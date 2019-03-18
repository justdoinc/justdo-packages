_.extend JustdoRecaptcha.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    return

  _verifyCaptchaCaptchaInputSchema: new SimpleSchema
    type:
      type: String

      allowedValues: ["v2_android", "v2_checkbox"]

    captcha_data:
      type: String

  verifyCaptcha: (client_ip, captcha_input) ->
    check client_ip, String
    client_ip = String(client_ip or "").trim()

    if not @isSupported()
      return {err: @_error("not-supported", "Recaptcha is not supported on this environment")}

    if _.isEmpty client_ip
      return {err: @_error("invalid-argument", "Client ip must be provided")}

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_verifyCaptchaCaptchaInputSchema,
        captcha_input,
        {self: @, throw_on_error: true}
      )
    captcha_input = cleaned_val    

    if _.isEmpty(captcha_input.captcha_data)
      return {err: @_error("invalid-argument", "Empty captcha_data provided")}

    if captcha_input.type == "v2_android"
      secret = @v2_android_server_key
    else if captcha_input.type == "v2_checkbox"
      secret = @v2_checkbox_server_key

    recaptcha_request = "secret=#{encodeURIComponent(secret)}&remoteip=#{encodeURIComponent(client_ip)}&response=#{encodeURIComponent(captcha_input.captcha_data)}"

    try
      captcha_response = HTTP.post "https://www.google.com/recaptcha/api/siteverify",
        content: recaptcha_request.toString("utf8")
        headers:
          "Content-Type": "application/x-www-form-urlencoded"
          "Content-Length": recaptcha_request.length
    catch e
      console.log("Captcha exception", e)

      return {err: @_error("recaptcha-failed", "Recaptcha failed")}

    if captcha_response?.data?.success is true
      return {}

    return {err: @_error("recaptcha-failed", "Recaptcha failed: #{captcha_response?.data?['error-codes']}")}
