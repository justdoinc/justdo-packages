_.extend JustdoAnalytics.prototype,
  _setupDataInjections: ->
    self = @

    root_post_requests_picker = Picker.filter (req, res) ->
      return req.method == "POST"

    root_post_requests_picker.middleware(bodyParser.json())
    root_post_requests_picker.middleware(bodyParser.urlencoded({extended: true}))

    root_post_requests_picker.middleware (req, res, next) ->
      if (justdo_analytics = req.body?["justdo-analytics"])?
        [did, sid] = justdo_analytics.split("|")

        if did? and did.length == 17 and sid? and sid.length == 17
          InjectData.pushData res, "justdo-analytics", "#{did}|#{sid}" # Build the justdo-analytics ourself and don't use justdo_analytics to avoid surprises
        else
          self.logger.error "Invalid justdo-analytics POST params injection attempt (did=#{did} , sid=#{sid})"

      next()