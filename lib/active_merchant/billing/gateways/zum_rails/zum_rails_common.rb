module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # For more information on ZumRails visit https://zumrails.com
    # or contact support@zumrails.com

    module ZumRailsCommon
      def self.included(base)
        base.test_url = 'https://api-sandbox.zumrails.com'
        base.live_url = 'https://api-app.zumrails.com'

        base.supported_countries = %w[US CA]
        base.default_currency = 'CAD'
        base.money_format = :dollars
        base.supported_cardtypes = %i[visa master]

        base.homepage_url = 'https://zumrails.com'
        base.display_name = 'Zūm Rails'
      end

      STANDARD_ERROR_CODE_MAPPING = {
        '400' => 'Bad Request',
        '401' => 'Unauthorized',
        '403' => 'Forbidden',
        '404' => 'Not Found',
        '415' => 'Unsupported Media Type',
        '429' => 'Too Many Requests',
        '500' => 'Internal Server Error'
      }.freeze

      ENDPOINTS = {
        login: 'api/authorize',
        wallet: 'api/wallet',
        purchase: 'api/transaction',
        refund: 'api/transaction/%{transaction_id}/refund',
        void: 'api/transaction/%{transaction_id}'
      }.freeze

      # Configuration defaults
      DEFAULT_ACCESS_TOKEN_REFRESH_INTERVAL = 30.minutes # Note: Access tokens typically expire after 1 hour.

      # @param  options [Hash]    The options for gateway configuration.
      # @option options [String]  :username (required) The username for authentication.
      # @option options [String]  :password (required) The password for authentication.
      # @option options [Integer] :access_token_refresh_interval (optional) The time interval in seconds for refreshing the access token. If not provided, a default interval is used.
      def initialize(options = {})
        requires!(options, :username, :password)
        super
        @config = {
          access_token_refresh_interval: @options[:access_token_refresh_interval] || DEFAULT_ACCESS_TOKEN_REFRESH_INTERVAL
        }
        @access_token = nil
        @access_token_last_refreshed = nil
      end

      # Check if the stored access token is valid and has not expired.
      #
      # @return [Boolean]
      def access_token_valid?
        @access_token && !access_token_refresh_due?
      end

      # This method is typically called when the access token needs to be refreshed.
      # It ensures that the stored token is cleared to prevent any potential conflicts.
      def clean_access_token
        @access_token = nil
        @access_token_last_refreshed = nil
      end

      # This method clears the existing access token and attempts to retrieve a new one.
      # If the retrieval is successful, the new token is stored, along with the timestamp
      # of the last refresh.
      def refresh_access_token
        clean_access_token

        response = fetch_access_token

        if response.success?
          @access_token = response.authorization
          @access_token_last_refreshed = Time.now
        else
          raise ResponseError.new(response)
        end
      end

      private

      def ensure_access_token
        refresh_access_token unless access_token_valid?
      end

      def ensure_wallet
        response = fetch_wallet

        if response.success?
          @wallet_id = response.authorization
        else
          raise ResponseError.new(response)
        end
      end

      def access_token_refresh_due?
        @access_token_last_refreshed.nil? ||
          Time.now >= @access_token_last_refreshed + @config[:access_token_refresh_interval]
      end

      def fetch_access_token
        payload = {
          'Username' => @options[:username],
          'Password' => @options[:password]
        }

        commit :login, payload
      end

      def fetch_wallet
        commit :wallet
      end

      def commit(action, payload = {}, params = {})
        response = parse ssl_request(http_method(action), url(action, params), post_data(payload), request_headers)

        Response.new(
          success_from(response),
          message_from(response),
          response,
          authorization: authorization_from(action, response),
          test: test?,
          error_code: error_code_from(response)
        )
      end

      def parse(body)
        JSON.parse(body)
      rescue JSON::ParserError
        json_error(body)
      end

      def success_from(response)
        response['isError'] == false
      end

      def message_from(response)
        if success_from(response)
          'Succeeded'
        else
          response.dig('responseException', 'exceptionMessage') || 'Unable to read error message'
        end
      end

      def authorization_from(action, response)
        case action
        when :login
          # Extract the access token
          response.dig('result', 'Token')
        when :wallet
          # Retrieve the wallet ID
          response.dig('result', 0, 'Id')
        when :purchase
          # Fetch the transaction ID
          response.dig('result', 'Id')
        end
      end

      def post_data(payload = {})
        payload.to_json
      end

      def error_code_from(response)
        STANDARD_ERROR_CODE_MAPPING[response['statusCode']]
      end

      def url(action, params = {})
        action_segment = ENDPOINTS[action]
        return unless action_segment

        uri = action_segment % params
        "#{base_url}/#{uri}"
      end

      def http_method(action)
        case action
        when :wallet
          :get
        when :login, :purchase, :refund
          :post
        when :void
          :delete
        else
          raise ArgumentError, "Unsupported action: #{action}"
        end
      end

      def base_url
        test? ? test_url : live_url
      end

      def request_headers
        headers = {
          'Content-Type' => 'application/json'
        }

        headers['Authorization'] = "Bearer #{@access_token}" if @access_token.present?
        headers
      end

      def json_error(raw_response)
        msg = 'Invalid response received from the Zūm Rails API. Please contact support@zumrails.com if you continue to receive this message.'
        msg += " (The raw response returned by the API was #{raw_response.inspect})"
        {
          'status' => 'error',
          'message' => msg
        }
      end

      def handle_response(response)
        case response.code.to_i
        when 200..499
          response.body
        else
          raise ResponseError.new(response)
        end
      end
    end
  end
end
