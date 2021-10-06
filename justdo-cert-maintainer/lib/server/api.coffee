_.extend JustdoCertMaintainer.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    https = Npm.require "https"

    cert_bundle = Assets.getText "lib/assets/#{@cert_bundle_filename}"
    https.globalAgent.options.ca = [cert_bundle] # Add the list of CAs to https global agent

    return

  #   # If-Modified-Since prevents downloading the same file
    
  #   # Note, at the moment we don't update routinely in run-time, code is kept for future use
    
  #   fs = Npm.require "fs"
    
  #   self = @

  #   HTTP.get @pem_fetch_endpoint, {headers: {"If-Modified-Since":  @_getLastUpdateOfCert(cert_bundle)}}, (err, result) ->
  #     if err?
  #       throw err
      
  #     if result.statusCode is 200
  #       {content} = result
  #       https.globalAgent.options.ca = [content] # Add CAs again if updates were found

  #       content_to_save = ("## Last updated: " + result.headers["last-modified"] + "\n" + content)
  #       fs.writeFile self._getPathToCert(), content_to_save, (err) ->
  #         if err?
  #           throw err
  #         return

  #     return

  #   return

  # _getPathToCert: -> @path_to_cert_bundle_store + @cert_bundle_filename

  # # Returns GMT format of last update
  # _getLastUpdateOfCert: (cert_bundle) ->
  #   last_updated = cert_bundle.match(@last_updated_regex)?[0]
  #   last_updated = new Date(last_updated).toGMTString()
  #   return last_updated
