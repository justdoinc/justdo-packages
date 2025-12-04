lowercase_hyphen_separated_name_regex = /^[a-z0-9-]+$/

_.extend HashRequestsHandler.prototype,
  run: ->
    # Before run is called we won't attempt to detect hash requests
    #
    # run will perform the first attempt to detect a hash request
    # and will set in place the events that will trigger detection
    # attempts

    if @running
      @logger.debug "Already running"

      return

    $(window).on "hashchange", @_hashchange_cb = =>
      @_extractHashRequest()

      return

    # perform first detection attempt
    @_extractHashRequest()

    @running = true

    return

  stop: ->
    # After calling stop no further attempts to detect hash will take
    # place.

    if not @running
      @logger.debug "Not running, no need to stop"

      return

    if @_hashchange_cb?
      $(window).off "hashchange", @_hashchange_cb

    @running = false

    return

  addRequestHandler: (handler_id, cb) ->
    # Add a request handler

    if not lowercase_hyphen_separated_name_regex.test(handler_id)
      throw @_error "invalid-handler-id", "Use hyphen-separated handler id (received: #{handler_id})"

    if handler_id of @request_handlers
      @logger.info "#{handler_id} already exists in @request_handlers, replacing it"

    @request_handlers[handler_id] = cb

    return

  _extractHashRequest: ->
    @logger.debug "Looking for hash request"

    current_hash = window.location.hash

    # Normalize hash, remove # from beginning, if there is #.
    if current_hash.charAt(0) == "#"
      current_hash = current_hash.substr(1)

    request_hash_args = {}
    hash_with_no_hash_request_args = current_hash.replace @request_args_regexp, (match, arg_name, arg_value) ->
      request_hash_args[arg_name] = decodeURIComponent(arg_value)

      return "" # remove from hash

    if not _.isEmpty(request_hash_args)
      if not (request_handler_id = request_hash_args.id)?
        @logger.warn "Hash request args detected but couldn't find hash request id: #{@options.prefix}-id"
      else
        if not (requestHandler = @request_handlers[request_handler_id])
          @logger.error "Unknown hash request id: #{request_handler_id}"
        else
          delete request_hash_args.id

          @logger.debug "Calling hash request handler: #{request_handler_id}"

          request_handler_result = requestHandler(request_hash_args)
          # requestHandler may return an object to direct the behaviour of the hash handler.
          # If requestHandler returns undefined, there's simply no effect, otherwise we are currently support the following
          # options:
          
          # {
          #     keep_hash: true/false # Default: false.
          #                           #
          #                           # This basically tells the hash handler that the consumer of the hash request is not ready to use
          #                           # it, and ask not to clear yet the hash request from the url, until other aspects are ready for its
          #                           # consumption. (E.g. in the case of the bottom pane, the bottom pane supports certain hash request
          #                           # 'expand-project-pane' that allows opening the bottom pane in a particular tab. It is possible that
          #                           # a plugin that registers the tab might not be ready at the time that the hash request attempts to
          #                           # tell the bottom pane to do something with it, in which case the hash-request handler in the bottom
          #                           # pane, will return an object with `keep_hash: true`).
          # }
          keep_hash = request_handler_result?.keep_hash == true

      # Remove hash request args from hash
      if (not keep_hash) and current_hash != hash_with_no_hash_request_args
        window.location.hash = hash_with_no_hash_request_args

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @stop()

    @destroyed = true

    @logger.debug "Destroyed"

    return