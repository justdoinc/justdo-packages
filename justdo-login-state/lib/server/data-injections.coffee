_.extend JustdoLoginState.prototype,
  _setupDataInjections: ->
    # Cross domain login-session sharing mechanism using POST requests
    # with 'token' param holding the user session token
    #
    # If a POST request received, look for the 'token' param, if exists,
    # push it to the client using pushData (meteorhacks:inject-data)

    root_post_requests_picker = Picker.filter (req, res) ->
      return req.method == "POST"

    root_post_requests_picker.middleware(bodyParser.json())
    root_post_requests_picker.middleware(bodyParser.urlencoded({extended: true}))

    root_post_requests_picker.middleware (req, res, next) ->
      if (token = req.body?.token)?
        InjectData.pushData res, "login-token", token

      next()
