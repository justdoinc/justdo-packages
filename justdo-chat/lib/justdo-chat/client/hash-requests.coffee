_.extend JustdoChat.prototype,
  _setupHashRequests: ->
    if not @hash_requests_handler?
      @logger.info "No options.hash_requests_handler provided, skipping hash request handler setup"

      return

    @hash_requests_handler.addRequestHandler "unsubscribe-c-iv-unread-emails-notifications", (args) =>
      @setUnreadNotificationsSubscription "email", "off", (err) ->
        message = "Successfully unsubscribed you from chat email notifications."

        bootbox.alert(message)

        return

      return
