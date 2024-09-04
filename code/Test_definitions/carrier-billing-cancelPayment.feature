Feature: CAMARA Carrier Billing API, v0.3 - Operation cancelPayment
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * Endpoint required for 2-step payment
  #
  # Testing assets:
  # * A phone number eligible for payment (no restrictions for it to be used to perform a payment)
  #
  # References to OAS spec schemas refer to schemas specifies in carrier-billing.yaml, version 0.3.0

  Background: Common cancelPayment setup
    Given the resource "/carrier-billing/v0.3/payments/{paymentId}/cancel"                                                              |
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" is set to a UUID value
    And the path parameter "paymentId" is set to a valid value
    And the request body is set by default to a request body compliant with the schema

  ##############################
  # Happy path scenarios
  ##############################


  @cancel_payment_01_generic_success_scenario
  Scenario: Common validations for any success scenario
    # Valid default request body compliant with the schema
    Given the request body is set to a valid request body
    When the HTTP "POST" request is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"


  @cancel_payment_02_phoneNumber_three_legged
  # Case using a 3-legged Access Token
  Scenario: Request cancel payment indicating phoneNumber
    Given the request body property "$.phonenumber" is set to a valid value which is the same as associated to access token
    When the HTTP "POST" request is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"


  @cancel_payment_03_phoneNumber_two_legged
  # Case using a 2-legged Access Token. Only applicable for Countries and Telco Operators whose regulation allows for it
  Scenario: Request cancel payment indicating phoneNumber
    Given the request body property "$.phonenumber" is set to a valid value which is the same as associated to access token
    When the HTTP "POST" request is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"


  ##############################
  # Error scenarios
  ##############################

  # Error 400 scenarios

  @cancel_payment_400.01_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text


  @cancel_payment_400.02_empty_request_body
  Scenario: Empty object as request body
    Given the request body is set to "{}"
    When the HTTP "POST" request is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text


  # Error 401 scenarios

  @cancel_payment_401.01_no_authorization_header
  Scenario: No Authorization header
    Given the header "Authorization" is removed
    And the request body is set to a valid request body
    When the HTTP "POST" request is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text


  @cancel_payment_401.02_expired_access_token
  Scenario: Expired access token
    Given the header "Authorization" is set to an expired access token
    And the request body is set to a valid request body
    When the HTTP "POST" request is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text


  @cancel_payment_401.03_invalid_access_token
  Scenario: Invalid access token
    Given the header "Authorization" is set to an invalid access token
    And the request body is set to a valid request body
    When the HTTP "POST" request is sent
    Then the response status code is 401
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text


  # Error 403 scenarios

  @cancel_payment_403.01_invalid_token_permissions
  Scenario: Inconsistent access token permissions
    # To test this, an access token has to be obtained without carrier-billing:payments:write scope
    Given the request body is set to a valid request body
    And the header "Authorization" is set to a valid access token emitted without carrier-billing:payments:write scope
    When the HTTP "POST" request is sent
    Then the response status code is 403
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text


  @cancel_payment_403.02_phoneNumber_token_mismatch
  Scenario: Inconsistent access token context for the phoneNumber
    # To test this, a 3-legged access token has to be obtained for a different phoneNumber
    Given the request body property "$.amountTransaction.phoneNumber" is set to a valid testing phone number
    And the header "Authorization" is set to a valid access token emitted for a different phone number
    When the HTTP "POST" request is sent
    Then the response status code is 403
    And the response property "$.status" is 403
    And the response property "$.code" is "INVALID_TOKEN_CONTEXT"
    And the response property "$.message" contains a user friendly text


  # Error 409 scenarios

  @cancel_payment_409.01_payment_confirmed
  Scenario: Payment already confirmed
    Given the request body is set to a valid request body
    And the path param "paymentId" is set to a valid value of an already confirmed payment
    And the header "Authorization" is set to a valid access token
    When the HTTP "POST" request is sent
    Then the response status code is 409
    And the response property "$.status" is 409
    And the response property "$.code" is "CARRIER_BILLING.PAYMENT_CONFIRMED"
    And the response property "$.message" contains a user friendly text


  @cancel_payment_409.02_payment_cancelled
  Scenario: Payment already cancelled
    Given the request body is set to a valid request body
    And the path param "paymentId" is set to a valid value of an already cancelled payment
    And the header "Authorization" is set to a valid access token
    When the HTTP "POST" request is sent
    Then the response status code is 409
    And the response property "$.status" is 409
    And the response property "$.code" is "CARRIER_BILLING.PAYMENT_CANCELLED"
    And the response property "$.message" contains a user friendly text


  # Error 422 scenarios

  @cancel_payment_422.01_phoneNumber_required
  Scenario: Payment requires the indication of phoneNumber. Only applicable to Countries and Telco Operators that allow and need it.
    Given the request body is set to a valid request body
    And the request body property "$.phoneNumber" is missing
    And the header "Authorization" is set to a valid access token
    When the HTTP "POST" request is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "CARRIER_BILLING.PHONE_NUMBER_REQUIRED"
    And the response property "$.message" contains a user friendly text


  ##############################
  ##END
  ##############################
