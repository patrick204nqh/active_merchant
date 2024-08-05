require 'test_helper'

class ZumRailsTest < Test::Unit::TestCase
  def setup
    @gateway = ZumRailsGateway.new(username: 'test', password: 'password')

    @transaction_id = 'sample-transaction-id'
    @amount = 100
    @options = {
      user_id: 'sample-user-id',
      memo: 'TEST'
    }
  end

  def test_successful_purchase
    @gateway.expects(:ssl_request).times(3).returns(
      successful_access_token_response
    ).then.returns(
      successful_wallet_response
    ).then.returns(
      successful_purchase_response
    )

    response = @gateway.purchase(@amount, @options)

    assert_success response
    assert_equal @transaction_id, response.authorization
    assert response.test?
  end

  def test_failed_purchase
    @gateway.expects(:ssl_request).times(3).returns(
      successful_access_token_response
    ).then.returns(
      successful_wallet_response
    ).then.returns(
      failed_purchase_response
    )

    response = @gateway.purchase(@amount, @options)

    assert_failure response
    assert response.test?
  end

  def test_successful_refund
    @gateway.expects(:ssl_request).times(2).returns(
      successful_access_token_response
    ).then.returns(
      successful_refund_response
    )

    response = @gateway.refund(@amount, @transaction_id)

    assert_success response
    assert response.test?
  end

  def test_successful_partial_refund
    @gateway.expects(:ssl_request).times(2).returns(
      successful_access_token_response
    ).then.returns(
      successful_partial_refund_response
    )

    response = @gateway.refund(@amount - 1, @transaction_id)

    assert_success response
    assert response.test?
  end

  def test_failed_refund
    @gateway.expects(:ssl_request).times(2).returns(
      successful_access_token_response
    ).then.returns(
      failed_refund_response
    )

    response = @gateway.refund(@amount, @transaction_id)

    assert_failure response
    assert response.test?
  end

  def test_successful_void
    @gateway.expects(:ssl_request).times(2).returns(
      successful_access_token_response
    ).then.returns(
      successful_void_response
    )

    response = @gateway.void(@transaction_id)

    assert_success response
    assert response.test?
  end

  def test_failed_void
    @gateway.expects(:ssl_request).times(2).returns(
      successful_access_token_response
    ).then.returns(
      failed_void_response
    )

    response = @gateway.void(@transaction_id)

    assert_failure response
    assert response.test?
  end

  def test_scrub
    assert @gateway.supports_scrubbing?
    assert_equal @gateway.scrub(pre_scrubbed), post_scrubbed
  end

  private

  def pre_scrubbed
    <<~PRE_SCRUBBED
      opening connection to api-sandbox.zumrails.com:443...
      opened
      starting SSL for api-sandbox.zumrails.com:443...
      SSL established, protocol: TLSv1.2, cipher: ECDHE-RSA-AES128-GCM-SHA256
      <- "POST /api/authorize HTTP/1.1\r\nContent-Type: application/json\r\nConnection: close\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nHost: api-sandbox.zumrails.com\r\nContent-Length: 97\r\n\r\n"
      <- "{\"Username\":\"username\",\"Password\":\"password\"}"
      -> "HTTP/1.1 200 OK\r\n"
      -> "Date: Tue, 10 Oct 2023 15:08:49 GMT\r\n"
      -> "Content-Type: application/json\r\n"
      -> "Content-Length: 1054\r\n"
      -> "Connection: close\r\n"
      -> "x-envoy-upstream-service-time: 158\r\n"
      -> "server: istio-envoy\r\n"
      -> "strict-transport-security: max-age=63072000; includeSubDomains; preload\r\n"
      -> "x-xss-protection: 1; mode=block\r\n"
      -> "cache-control: no-store\r\n"
      -> "pragma: no-cache\r\n"
      -> "\r\n"
      reading 1054 bytes...
      -> "{\"statusCode\":200,\"message\":\"POST Request successful.\",\"isError\":false,\"result\":{\"Id\":\"62a667ed-3cbd-4dfa-a376-5e1ef9df9a22\",\"Role\":\"API\",\"Token\":\"jwttoken\",\"CustomerId\":\"sample_customer_id\",\"CompanyName\":\"Example Company\",\"CustomerCreatedAt\":\"2022-12-22T16:10:38.297495Z\",\"CustomerType\":\"Customer\",\"Username\":\"sample_customer_id\",\"IsTermsOfUseAccepted\":false,\"IsTwoFactorAuthenticationEnabled\":false,\"LoginType\":\"EmailPassword\",\"RefreshToken\":\"EOjHzqLJ20jtZ6ZivTz6TaN2Xh7535oiUkZTSDYyYTY2N2VkLTNjYmQtNGRmYS1hMzc2LTVlMWVmOWRmOWEyMg==\",\"CreatedAt\":\"2022-12-22T16:10:38.470867Z\",\"OtpReady\":false}}"
      read 1054 bytes
      Conn close
      opening connection to api-sandbox.zumrails.com:443...
      opened
      starting SSL for api-sandbox.zumrails.com:443...
      SSL established, protocol: TLSv1.2, cipher: ECDHE-RSA-AES128-GCM-SHA256
      <- "GET /api/wallet HTTP/1.1\r\nContent-Type: application/json\r\nAuthorization: Bearer jwttoken\r\nConnection: close\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nHost: api-sandbox.zumrails.com\r\n\r\n"
      -> "HTTP/1.1 200 OK\r\n"
      -> "Date: Tue, 10 Oct 2023 15:08:50 GMT\r\n"
      -> "Content-Type: application/json\r\n"
      -> "Content-Length: 480\r\n"
      -> "Connection: close\r\n"
      -> "x-envoy-upstream-service-time: 33\r\n"
      -> "server: istio-envoy\r\n"
      -> "strict-transport-security: max-age=63072000; includeSubDomains; preload\r\n"
      -> "x-xss-protection: 1; mode=block\r\n"
      -> "cache-control: no-store\r\n"
      -> "pragma: no-cache\r\n"
      -> "\r\n"
      reading 480 bytes...
      -> "{\"statusCode\":200,\"message\":\"GET Request successful.\",\"isError\":false,\"result\":[{\"Id\":\"sample_wallet_id\",\"Type\":\"Unified\",\"EftProvider\":\"RBC\",\"Balance\":57078.81,\"BankAccountInformationId\":\"8bb57c36-e594-47f0-aac6-a65a119fa619\",\"Customer\":{\"Enable3DSecureVisa\":false,\"Enable3DSecureCreditCard\":false,\"InteracProvider\":\"PeoplesTrust\",\"Id\":\"2ce80331-3688-4d3e-b687-df7dc93bc463\",\"CompanyName\":\"Example Company\",\"CompanyEmail\":\"test@co.ca\"},\"Currency\":\"CAD\"}]}"
      read 480 bytes
      Conn close
      opening connection to api-sandbox.zumrails.com:443...
      opened
      starting SSL for api-sandbox.zumrails.com:443...
      SSL established, protocol: TLSv1.2, cipher: ECDHE-RSA-AES128-GCM-SHA256
      <- "POST /api/transaction HTTP/1.1\r\nContent-Type: application/json\r\nAuthorization: Bearer jwttoken\r\nConnection: close\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nHost: api-sandbox.zumrails.com\r\nContent-Length: 212\r\n\r\n"
      <- "{\"Amount\":\"10.00\",\"ZumRailsType\":\"AccountsReceivable\",\"TransactionMethod\":\"CreditCard\",\"UserId\":\"sample_user_id\",\"Memo\":\"TEST\",\"Comment\":\"\",\"WalletId\":\"sample_wallet_id\"}"
      -> "HTTP/1.1 200 OK\r\n"
      -> "Date: Tue, 10 Oct 2023 15:08:53 GMT\r\n"
      -> "Content-Type: application/json\r\n"
      -> "Content-Length: 1417\r\n"
      -> "Connection: close\r\n"
      -> "x-envoy-upstream-service-time: 1481\r\n"
      -> "server: istio-envoy\r\n"
      -> "strict-transport-security: max-age=63072000; includeSubDomains; preload\r\n"
      -> "x-xss-protection: 1; mode=block\r\n"
      -> "cache-control: no-store\r\n"
      -> "pragma: no-cache\r\n"
      -> "\r\n"
      reading 1417 bytes...
      -> "{\"statusCode\":200,\"message\":\"POST Request successful.\",\"isError\":false,\"result\":{\"Customer\":{\"Enable3DSecureVisa\":false,\"Enable3DSecureCreditCard\":false,\"InteracProvider\":\"PeoplesTrust\",\"Id\":\"2ce80331-3688-4d3e-b687-df7dc93bc463\",\"CompanyName\":\"Example Company\",\"CompanyEmail\":\"test@co.ca\"},\"InteracHasSecurityQuestionAndAnswer\":false,\"InteracDebtorInstitutionName\":\"\",\"IsRefundable\":true,\"Id\":\"7fad2810-2741-4a7e-b084-e68eb10a90d7\",\"CreatedAt\":\"2023-10-10T15:08:52.1120512Z\",\"Memo\":\"TEST\",\"Comment\":\"\",\"Amount\":10.0,\"User\":{\"Id\":\"30984f1a-19bc-4688-9a34-26660d9541cb\",\"FirstName\":\"Huy\",\"LastName\":\"Nguyen\",\"Email\":\"huy.nguyen@co.ca\",\"IsActive\":true,\"PaymentInstruments\":[]},\"Wallet\":{\"Id\":\"7b96f345-059e-4dbb-b16f-20fc2e770494\",\"Type\":\"Unified\",\"Currency\":\"CAD\"},\"ZumRailsType\":\"AccountsReceivable\",\"TransactionMethod\":\"CreditCard\",\"TransactionHistory\":[{\"Id\":\"c6146a4d-307e-49b4-b255-8909e5793611\",\"CreatedAt\":\"2023-10-10T15:08:53.1822261Z\",\"Event\":\"Succeeded\",\"EventDescription\":\"Transaction completed\"},{\"Id\":\"36d18089-04c3-4306-800e-0ee798bd4e5f\",\"CreatedAt\":\"2023-10-10T15:08:52.2755253Z\",\"Event\":\"Started\",\"EventDescription\":\"Transaction with type AccountsReceivable started, from Huy Nguyen - (************4242) to Zum Wallet with amount: $10.00\"}],\"TransactionStatus\":\"Completed\",\"From\":\"Huy Nguyen - (************4242)\",\"To\":\"Zum Wallet\",\"CompletedAt\":\"2023-10-10T15:08:53.2044389Z\",\"Currency\":\"CAD\"}}"
      read 1417 bytes
      Conn close
    PRE_SCRUBBED
  end

  def post_scrubbed
    <<~POST_SCRUBBED
      opening connection to api-sandbox.zumrails.com:443...
      opened
      starting SSL for api-sandbox.zumrails.com:443...
      SSL established, protocol: TLSv1.2, cipher: ECDHE-RSA-AES128-GCM-SHA256
      <- "POST /api/authorize HTTP/1.1\r\nContent-Type: application/json\r\nConnection: close\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nHost: api-sandbox.zumrails.com\r\nContent-Length: 97\r\n\r\n"
      <- "{\"Username":"[FILTERED]","Password":"[FILTERED]"}"
      -> "HTTP/1.1 200 OK\r\n"
      -> "Date: Tue, 10 Oct 2023 15:08:49 GMT\r\n"
      -> "Content-Type: application/json\r\n"
      -> "Content-Length: 1054\r\n"
      -> "Connection: close\r\n"
      -> "x-envoy-upstream-service-time: 158\r\n"
      -> "server: istio-envoy\r\n"
      -> "strict-transport-security: max-age=63072000; includeSubDomains; preload\r\n"
      -> "x-xss-protection: 1; mode=block\r\n"
      -> "cache-control: no-store\r\n"
      -> "pragma: no-cache\r\n"
      -> "\r\n"
      reading 1054 bytes...
      -> "{\"statusCode\":200,\"message\":\"POST Request successful.\",\"isError\":false,\"result\":{\"Id\":\"62a667ed-3cbd-4dfa-a376-5e1ef9df9a22\",\"Role\":\"API\",\"Token\":\"[FILTERED]\",\"CustomerId\":\"[FILTERED]\",\"CompanyName\":\"Example Company\",\"CustomerCreatedAt\":\"2022-12-22T16:10:38.297495Z\",\"CustomerType\":\"Customer\",\"Username\":\"[FILTERED]\",\"IsTermsOfUseAccepted\":false,\"IsTwoFactorAuthenticationEnabled\":false,\"LoginType\":\"EmailPassword\",\"RefreshToken\":\"EOjHzqLJ20jtZ6ZivTz6TaN2Xh7535oiUkZTSDYyYTY2N2VkLTNjYmQtNGRmYS1hMzc2LTVlMWVmOWRmOWEyMg==\",\"CreatedAt\":\"2022-12-22T16:10:38.470867Z\",\"OtpReady\":false}}"
      read 1054 bytes
      Conn close
      opening connection to api-sandbox.zumrails.com:443...
      opened
      starting SSL for api-sandbox.zumrails.com:443...
      SSL established, protocol: TLSv1.2, cipher: ECDHE-RSA-AES128-GCM-SHA256
      <- "GET /api/wallet HTTP/1.1\r\nContent-Type: application/json\r\nAuthorization: Bearer [FILTERED]\r\nConnection: close\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nHost: api-sandbox.zumrails.com\r\n\r\n"
      -> "HTTP/1.1 200 OK\r\n"
      -> "Date: Tue, 10 Oct 2023 15:08:50 GMT\r\n"
      -> "Content-Type: application/json\r\n"
      -> "Content-Length: 480\r\n"
      -> "Connection: close\r\n"
      -> "x-envoy-upstream-service-time: 33\r\n"
      -> "server: istio-envoy\r\n"
      -> "strict-transport-security: max-age=63072000; includeSubDomains; preload\r\n"
      -> "x-xss-protection: 1; mode=block\r\n"
      -> "cache-control: no-store\r\n"
      -> "pragma: no-cache\r\n"
      -> "\r\n"
      reading 480 bytes...
      -> "{\"statusCode\":200,\"message\":\"GET Request successful.\",\"isError\":false,\"result\":[{\"Id\":\"sample_wallet_id\",\"Type\":\"Unified\",\"EftProvider\":\"RBC\",\"Balance\":57078.81,\"BankAccountInformationId\":\"8bb57c36-e594-47f0-aac6-a65a119fa619\",\"Customer\":{\"Enable3DSecureVisa\":false,\"Enable3DSecureCreditCard\":false,\"InteracProvider\":\"PeoplesTrust\",\"Id\":\"2ce80331-3688-4d3e-b687-df7dc93bc463\",\"CompanyName\":\"Example Company\",\"CompanyEmail\":\"test@co.ca\"},\"Currency\":\"CAD\"}]}"
      read 480 bytes
      Conn close
      opening connection to api-sandbox.zumrails.com:443...
      opened
      starting SSL for api-sandbox.zumrails.com:443...
      SSL established, protocol: TLSv1.2, cipher: ECDHE-RSA-AES128-GCM-SHA256
      <- "POST /api/transaction HTTP/1.1\r\nContent-Type: application/json\r\nAuthorization: Bearer [FILTERED]\r\nConnection: close\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nHost: api-sandbox.zumrails.com\r\nContent-Length: 212\r\n\r\n"
      <- "{\"Amount\":\"10.00\",\"ZumRailsType\":\"AccountsReceivable\",\"TransactionMethod\":\"CreditCard\",\"UserId\":\"[FILTERED]\",\"Memo\":\"TEST\",\"Comment\":\"\",\"WalletId\":\"[FILTERED]\"}"
      -> "HTTP/1.1 200 OK\r\n"
      -> "Date: Tue, 10 Oct 2023 15:08:53 GMT\r\n"
      -> "Content-Type: application/json\r\n"
      -> "Content-Length: 1417\r\n"
      -> "Connection: close\r\n"
      -> "x-envoy-upstream-service-time: 1481\r\n"
      -> "server: istio-envoy\r\n"
      -> "strict-transport-security: max-age=63072000; includeSubDomains; preload\r\n"
      -> "x-xss-protection: 1; mode=block\r\n"
      -> "cache-control: no-store\r\n"
      -> "pragma: no-cache\r\n"
      -> "\r\n"
      reading 1417 bytes...
      -> "{\"statusCode\":200,\"message\":\"POST Request successful.\",\"isError\":false,\"result\":{\"Customer\":{\"Enable3DSecureVisa\":false,\"Enable3DSecureCreditCard\":false,\"InteracProvider\":\"PeoplesTrust\",\"Id\":\"2ce80331-3688-4d3e-b687-df7dc93bc463\",\"CompanyName\":\"Example Company\",\"CompanyEmail\":\"test@co.ca\"},\"InteracHasSecurityQuestionAndAnswer\":false,\"InteracDebtorInstitutionName\":\"\",\"IsRefundable\":true,\"Id\":\"7fad2810-2741-4a7e-b084-e68eb10a90d7\",\"CreatedAt\":\"2023-10-10T15:08:52.1120512Z\",\"Memo\":\"TEST\",\"Comment\":\"\",\"Amount\":10.0,\"User\":{\"Id\":\"30984f1a-19bc-4688-9a34-26660d9541cb\",\"FirstName\":\"Huy\",\"LastName\":\"Nguyen\",\"Email\":\"huy.nguyen@co.ca\",\"IsActive\":true,\"PaymentInstruments\":[]},\"Wallet\":{\"Id\":\"7b96f345-059e-4dbb-b16f-20fc2e770494\",\"Type\":\"Unified\",\"Currency\":\"CAD\"},\"ZumRailsType\":\"AccountsReceivable\",\"TransactionMethod\":\"CreditCard\",\"TransactionHistory\":[{\"Id\":\"c6146a4d-307e-49b4-b255-8909e5793611\",\"CreatedAt\":\"2023-10-10T15:08:53.1822261Z\",\"Event\":\"Succeeded\",\"EventDescription\":\"Transaction completed\"},{\"Id\":\"36d18089-04c3-4306-800e-0ee798bd4e5f\",\"CreatedAt\":\"2023-10-10T15:08:52.2755253Z\",\"Event\":\"Started\",\"EventDescription\":\"Transaction with type AccountsReceivable started, from Huy Nguyen - (************4242) to Zum Wallet with amount: $10.00\"}],\"TransactionStatus\":\"Completed\",\"From\":\"Huy Nguyen - (************4242)\",\"To\":\"Zum Wallet\",\"CompletedAt\":\"2023-10-10T15:08:53.2044389Z\",\"Currency\":\"CAD\"}}"
      read 1417 bytes
      Conn close
    POST_SCRUBBED
  end

  def successful_access_token_response
    %{
      {
        "statusCode": 200,
        "message": "POST Request successful.",
        "isError": false,
        "result": {
          "Id": "62a667ed-3cbd-4dfa-a376-5e1ef9df9a22",
          "Role": "API",
          "Token": "sample-access-token",
          "CustomerId": "sample-customer-id",
          "CompanyName": "Example Company",
          "CustomerCreatedAt": "2022-12-22T16:10:38.297495Z",
          "CustomerType": "Customer",
          "Username": "sample-owner-id",
          "IsTermsOfUseAccepted": false,
          "IsTwoFactorAuthenticationEnabled": false,
          "LoginType": "EmailPassword",
          "RefreshToken": "sample-refresh-token",
          "CreatedAt": "2022-12-22T16:10:38.470867Z",
          "OtpReady": false
        }
      }
    }
  end

  def successful_wallet_response
    %(
      {
        "statusCode": 200,
        "message": "GET Request successful.",
        "isError": false,
        "result": [
          {
            "Id": "sample-wallet-id",
            "Type": "Unified",
            "EftProvider": "RBC",
            "Balance": 5050,
            "BankAccountInformationId": "sample-bankinfo-id",
            "Customer": {
              "Id": "sample-customer-id",
              "CompanyName": "Example Company",
              "Enable3DSecureVisa": false,
              "Enable3DSecureCreditCard": false,
              "InteracProvider": "PeoplesTrust"
            }
          }
        ]
      }
    )
  end

  def successful_purchase_response
    %(
      {
        "statusCode": 200,
        "message": "POST Request successful.",
        "isError": false,
        "result": {
          "Id": "sample-transaction-id",
          "CreatedAt": "2023-01-10T07:52:19.5055175Z",
          "Memo": "test",
          "Comment": "test",
          "Amount": 10,
          "Customer": {
            "Id": "sample-customer-id",
            "CompanyName": "Example Company",
            "Enable3DSecureVisa": false,
            "Enable3DSecureCreditCard": false,
            "InteracProvider": "PeoplesTrust"
          },
          "User": {
            "Id": "sample-user-id",
            "FirstName": "Huy",
            "LastName": "Nguyen",
            "Email": "huy.nguyen@co.ca",
            "IsActive": true
          },
          "Wallet": {
              "Id": "sample-wallet-id",
              "Type": "Unified"
          },
          "ZumRailsType": "AccountsReceivable",
          "TransactionMethod": "CreditCard",
          "TransactionHistory": [
            {
              "Id": "e65e841a-5886-43e7-88ec-dddddddddddd",
              "CreatedAt": "2023-01-10T07:52:19.6689046Z",
              "Event": "Started",
              "EventDescription": "Transaction with type AccountsReceivable started, from Huy Nguyen - (************5100) to Zum Wallet with amount: $10.00"
            },
            {
              "Id": "d52a37f1-a2b4-4b9d-9070-dddddddddddd",
              "CreatedAt": "2023-01-10T07:52:20.3738049Z",
              "Event": "Succeeded",
              "EventDescription": "Transaction completed"
            }
          ],
          "TransactionStatus": "Completed",
          "From": "Huy Nguyen - (************5100)",
          "To": "Zum Wallet",
          "InteracHasSecurityQuestionAndAnswer": false,
          "InteracDebtorInstitutionName": "",
          "CompletedAt": "2023-01-10T07:52:20.3902211Z",
          "IsRefundable": true
        }
      }
    )
  end

  def failed_purchase_response
    %(
      {
        "statusCode": 415,
        "isError": true,
        "responseException": {
          "exceptionMessage": {
            "type": "https://tools.ietf.org/html/rfc7231#section-6.5.13",
            "title": "Unsupported Media Type",
            "status": 415,
            "traceId": "00-a2bfbc0a024ae64ef862a96ada7c0697-3af2bb77a3632453-00"
          }
        }
      }
    )
  end

  def successful_refund_response
    %(
      {
        "statusCode": 200,
        "message": "POST Request successful.",
        "isError": false,
        "result": {}
      }
    )
  end

  def successful_partial_refund_response
    %(
      {
        "statusCode": 200,
        "message": "POST Request successful.",
        "isError": false,
        "result": {}
      }
    )
  end

  def failed_refund_response
    %(
      {
        "statusCode": 400,
        "isError": true,
        "responseException": {
          "exceptionMessage": "Payment method not supported for refund."
        }
      }
    )
  end

  def successful_void_response
    %(
      {
        "statusCode": 200,
        "message": "DELETE Request successful.",
        "isError": false,
        "result": ""
      }
    )
  end

  def failed_void_response
    %(
      {
        "statusCode": 400,
        "isError": true,
        "responseException": {
          "exceptionMessage": "Transaction is already completed"
        }
      }
    )
  end
end
