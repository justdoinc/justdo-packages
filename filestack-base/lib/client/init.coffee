_.extend FilestackBase.prototype,
  _immediateInit: ->
    if  @options.api_key?
      @filestack_api_key = @options.api_key
      @_initFilestack()

    else
      @logger.log @_error "api-key-required"

    return

  _deferredInit: ->
    return

  _initFilestack: ->
    # Commented out because conflicts with tasks-file-manager:

    # Load filestack.com
    # Source: https://www.filestack.com/docs/
    $.getScript '//api.filestackapi.com/filestack.js', (error, r) =>
      if error?
        @emit "error", error
      if window.filepicker?
        @filepicker = filepicker
        window.filepicker.setKey @filestack_api_key
        @emit "filestack-ready"
        $.getScript "https://api.filepicker.io/v1/filepicker_debug.js"
