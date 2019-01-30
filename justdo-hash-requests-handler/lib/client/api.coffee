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
        if not (request_handler = @request_handlers[request_handler_id])
          @logger.error "Unknown hash request id: #{request_handler_id}"
        else
          delete request_hash_args.id

          @logger.debug "Calling hash request handler: #{request_handler_id}"

          request_handler(request_hash_args)

      # Remove hash request args from hash
      if current_hash != hash_with_no_hash_request_args
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