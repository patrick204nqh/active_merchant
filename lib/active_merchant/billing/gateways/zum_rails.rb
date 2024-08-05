require 'active_merchant/billing/gateways/zum_rails/zum_rails_common'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # This gateway is designed for handling transactions through Zum Rails, a payment system that differs from
    # traditional payment gateways in several ways:
    #
    # 1. User-Centric Payment Methods: Zum Rails is user-centric, allowing users to store and manage their
    #    preferred payment methods, including credit/debit card and bank account.
    #
    # 2. User-Based Fund Source Selection: The payment source used for a transaction depends on the user's preferences.
    #    Each user can associate one credit/debit card, and one bank account with their account.
    #
    # 3. Transaction Type Determines Source: The choice of payment source (credit/debit card, or bank account)
    #    for a transaction depends on the transaction type selected.
    #
    # 4. Support for Multiple Users with the Same Email: Zum Rails allows multiple users with the same email address
    #    to create separate accounts and manage their payment methods independently.
    #
    # To use this gateway effectively, it's important to understand how Zum Rails handles payments and fund sources,
    # and how transaction types impact the selection of the appropriate payment method.
    #
    # For more information on Zum Rails and how to use this gateway, refer to the Zum Rails documentation https://docs.zumrails.com
    # or contact support@zumrails.com
    #
    class ZumRailsGateway < Gateway
      include ZumRailsCommon

      # Available transaction types:
      # * 'FundZumWallet':         Send money from Funding Source to Zum Wallet
      # * 'WithdrawZumWallet':     Withdraw money from Zum Wallet to Funding Source
      # * 'AccountsPayable':       Send money (accounts payable) from your Zum Wallet/Funding Source to a User
      # * 'AccountsReceivable':    Withdraw money (accounts receivable) from a User to Zum Wallet/Funding Source
      #
      TRANSACTION_TYPES = %w[FundZumWallet WithdrawZumWallet AccountsPayable AccountsReceivable].freeze
      TRANSACTION_TYPES_REQUIRING_USER_ID = %w[AccountsPayable AccountsReceivable].freeze
      DEFAULT_TRANSACTION_TYPE = 'AccountsReceivable'

      # Available transaction methods:
      # * 'Eft':                   Electronic funds transfer between banks
      # * 'Interac':               Online e-transfers, user receives an e-mail or SMS
      # * 'VisaDirect':            Visa rails to send and pull funds directly to Visa debit card
      # * 'CreditCard':            Credit Card payments/checkout to collect funds
      #
      TRANSACTION_METHODS = %w[Eft Interac VisaDirect CreditCard].freeze
      TRANSACTION_METHODS_REQUIRING_3DS = %w[VisaDirect CreditCard].freeze
      DEFAULT_TRANSACTION_METHOD = 'CreditCard'

      # Define the possible owner source types for transactions
      #
      SOURCE_TYPES = %w[virtual_wallet funding_source].freeze
      DEFAULT_SOURCE_TYPE = 'virtual_wallet'

      # @param  money   [Integer] The transaction amount in cents.
      # @param  options [Hash]    Additional options for the purchase transaction.
      # @option options [Integer] :user_id (required for certain transaction types) Unique user ID.
      # @option options [Symbol]  :source_type (default: 'virtual_wallet').
      # @option options [String]  :memo (required) Order memo.
      # @option options [String]  :comment (optional) Comment associated with the transaction.
      # @option options [String]  :transaction_type (default: 'AccountsReceivable').
      # @option options [String]  :transaction_method (default: 'CreditCard').
      # @option options [String]  :card_eci (optional) Set the Card Electronic Commerce Indicator (ECI) for the transaction.
      # @option options [String]  :card_xid (optional) Set the Card XID (Payment System Unique Transaction Identifier) for the transaction.
      # @option options [String]  :card_cavv (optional) Set the Card CAVV (Cardholder Authentication Verification Value) for the transaction.
      #
      # @return         [Response]
      def purchase(money, options = {})
        ensure_access_token

        post = {}
        add_amount(post, money)
        add_payment(post, options)
        add_customer(post, options)
        add_description(post, options)
        add_source_owner(post, options)

        commit :purchase, post
      end

      # Please note that Zum Rails currently supports two refund types:
      # 1. Full Refund: You can initiate a full refund of the entire transaction amount.
      # 2. Partial Refund: You can initiate a partial refund for a specific amount.
      #
      # Refunds can only be processed for transactions created using the 'CreditCard' method.
      # If you attempt to refund a transaction created using a different method, it may not be supported.
      #
      # @param money          [Integer] The refund amount in cents.
      # @param authorization  [String]  The unique transaction ID for the refund.
      #
      # @return               [Response]
      def refund(money, authorization)
        ensure_access_token

        post = {}
        add_amount(post, money)

        commit :refund, post, { transaction_id: authorization }
      end

      # Zum Rails supports various payment methods such as EFT and Interac. These transaction types
      # may not complete instantly, and it's possible to initiate a void operation to cancel them
      # before they are completed.
      #
      # @param authorization  [String]  The unique transaction ID for the refund.
      # @param options        [Hash]    Additional options for the refund transaction.
      #
      # @return               [Response]
      def void(authorization)
        ensure_access_token

        commit :void, {}, { transaction_id: authorization }
      end

      # @return [Boolean]
      def supports_scrubbing?
        true
      end

      # Scrub (filter) sensitive information in the provided transcript.
      #
      # @param transcript [String] The text to be scrubbed.
      #
      # @return           [String] The scrubbed text.
      def scrub(transcript)
        transcript.
          gsub(%r((Authorization: Bearer )[a-zA-Z0-9._-]+)i, '\1[FILTERED]').
          gsub(%r(("Username\\?":\\?")[^"]*)i, '\1[FILTERED]').
          gsub(%r(("Password\\?":\\?")[^"]*)i, '\1[FILTERED]').
          gsub(%r(("Token\\?":\\?")[^"]*)i, '\1[FILTERED]').
          gsub(%r(("WalletId\\?":\\?")[^"]*)i, '\1[FILTERED]').
          gsub(%r(("FundingSourceId\\?":\\?")[^"]*)i, '\1[FILTERED]').
          gsub(%r(("UserId\\?":\\?")[^"]*)i, '\1[FILTERED]').
          gsub(%r(("CustomerId\\?":\\?")[^"]*)i, '\1[FILTERED]')
      end

      private

      def add_amount(post, money)
        post[:Amount] = amount(money)
      end

      def add_payment(post, options)
        add_transaction_type(post, options)
        add_transaction_method(post, options)
        add_3dsecure(post, options)
      end

      def add_customer(post, options)
        return if TRANSACTION_TYPES_REQUIRING_USER_ID.exclude?(post[:ZumRailsType])

        requires!(options, :user_id)

        post[:UserId] = options[:user_id]
      end

      def add_source_owner(post, options)
        source_type = options[:source_type] || DEFAULT_SOURCE_TYPE
        raise ArgumentError, "Invalid source_type: #{source_type}" if SOURCE_TYPES.exclude?(source_type)

        case source_type
        when 'virtual_wallet'
          ensure_wallet

          post[:WalletId] = @wallet_id
        when 'funding_source'
          requires!(:funding_source_id)

          post[:FundingSourceId] = options[:funding_source_id]
        end
      end

      def add_description(post, options)
        requires!(options, :memo)

        post[:Memo] = options[:memo]
        post[:Comment] = options[:comment] || ''
      end

      def add_transaction_type(post, options)
        transaction_type = options[:transaction_type] || DEFAULT_TRANSACTION_TYPE
        raise ArgumentError, "Invalid transaction_type: #{transaction_type}" if TRANSACTION_TYPES.exclude?(transaction_type)

        post[:ZumRailsType] = transaction_type
      end

      def add_transaction_method(post, options)
        transaction_method = options[:transaction_method] || DEFAULT_TRANSACTION_METHOD
        raise ArgumentError, "Invalid transaction_method: #{transaction_method}" if TRANSACTION_METHODS.exclude?(transaction_method)

        post[:TransactionMethod] = transaction_method
      end

      def add_3dsecure(post, options)
        return if TRANSACTION_METHODS_REQUIRING_3DS.exclude?(post[:TransactionMethod])

        post[:CardEci] = options[:card_eci]
        post[:CardXid] = options[:card_xid]
        post[:CardCavv] = options[:card_cavv]
      end
    end
  end
end
