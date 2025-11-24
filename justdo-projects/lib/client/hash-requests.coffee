_.extend Projects.prototype,
  _setupHashRequests: ->
    if not @hash_requests_handler?
      @logger.info "No options.hash_requests_handler provided, skipping hash request handler setup"

      return

    @hash_requests_handler.addRequestHandler "unsubscribe-projects", (args) =>
      if not (projects = args.projects)?
        @logger.warn "Hash request: unsubscribe-projects: received with no projects argument, ignoring request"

        return

      projects = projects.split(",")

      @configureEmailUpdatesSubscriptions projects, false, (err) ->
        common_message = "Successfully unsubscribed you from daily email updates for"
        if projects[0] == "*"
          bootbox.alert("#{common_message} all projects.")
        else if projects.length > 1 
          bootbox.alert("#{common_message} all requested projects.")
        else
          bootbox.alert("#{common_message} the requested project.")

        return

      return

    @hash_requests_handler.addRequestHandler "unsubscribe-projects-email-notifications", (args) =>
      @configureEmailNotificationsSubscriptions false, (err) ->
        common_message = "Successfully unsubscribed from ownership transfer email notifications."
        bootbox.alert(common_message)

      return