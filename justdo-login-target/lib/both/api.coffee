_.extend JustdoLoginTarget.prototype,
  #
  # Target url verification
  #
  validTargetUrl: (target_url) ->
    # Returns true if we allow target_url to be served as a
    # login targe, false otherwise

    if not @options.permitted_root_urls?
      # If target url root url isn't limited, just set it.
      return true

    for root_url in @options.permitted_root_urls
      if target_url.substr(0, root_url.length).toLowerCase() == root_url.toLowerCase()
        return true

    return false

  #
  # Getter/setter for internal @_target_url
  #
  setTargetUrl: (target_url) ->
    # Set target url

    if @validTargetUrl(target_url)
      @_target_url = target_url

      return

    # if loop finished, target url is forbidden
    throw @_error "target-url-forbidden"

  clearTargetUrl: -> @_target_url = null

  getTargetUrl: -> @_target_url

  #
  # Target url links generator
  #
  applyTargetUrl: (url, target_url=null) ->
    # Gets a url and apply on it a login target in accordance with this
    # package format, the login target will be the base64 encrypted
    #
    # If received target_url param is null, @_target_url will be used
    # if it is null also, url will return unchanged
    #
    # The target url must pass validTargetUrl() checks

    if not target_url?
      target_url = @getTargetUrl()

    if not target_url?
      @logger.debug "Target url not set"

      return url # return url with no change

    if not @validTargetUrl(target_url)
      throw @_error "target-url-forbidden", "Target_url: #{target_url}; Permitted urls: #{@options.permitted_root_urls.join(", ")}"

    has_hash_query_string = /#.*?\?/i
    has_hash = /#/i

    if has_hash_query_string.test(url)
      url += "&"
    else if has_hash.test(url)
      url += "?"
    else
      url += "#?"

    word_array = CryptoJS.enc.Utf8.parse(target_url);
    target_url_base64 = CryptoJS.enc.Base64.stringify(word_array);

    url += "target=#{target_url_base64}"

    return url