require 'test_helper'

class RemoteZumRailsTest < Test::Unit::TestCase
  def setup
    @gateway = ZumRailsGateway.new(fixtures(:zum_rails))

    @amount = 1000
    @options = {
      user_id: fixtures(:zum_rails)[:user_id],
      memo: fixtures(:zum_rails)[:memo]
    }
  end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @options)
    assert_success response
    assert_equal 'Succeeded', response.message
    assert response.authorization
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @options.merge(user_id: SecureRandom.hex(10)))
    assert_failure response
  end

  # def test_successful_refund
  #   purchase = @gateway.purchase(@amount,  @options)
  #   assert_success purchase
  #   assert purchase.authorization

  #   assert refund = @gateway.refund(@amount, purchase.authorization)
  #   assert_success refund
  # end

  # def test_partial_refund
  #   purchase = @gateway.purchase(@amount, @options)
  #   assert_success purchase
  #   assert purchase.authorization

  #   assert refund = @gateway.refund(@amount - 1, purchase.authorization)
  #   assert_success refund
  # end

  def test_failed_refund
    response = @gateway.refund(@amount, 'sample_transaction_id')
    assert_failure response
  end

  def test_successful_void
    purchase = @gateway.purchase(@amount, @options.merge(transaction_method: 'Interac'))
    assert_success purchase
    assert purchase.authorization

    assert void = @gateway.void(purchase.authorization)
    assert_success void
  end

  def test_failed_void
    purchase = @gateway.purchase(@amount, @options) # CreditCard
    assert_success purchase
    assert purchase.authorization

    assert void = @gateway.void(purchase.authorization)
    assert_failure void
  end

  def test_transcript_scrubbing
    transcript = capture_transcript(@gateway) do
      @gateway.purchase(@amount, @options)
    end
    transcript = @gateway.scrub(transcript)

    assert_scrubbed(fixtures(:zum_rails)[:password], transcript)
  end
end
