_.extend JustdoHelpers,
  getCachedScript: (url, options) ->
    # Based on a script from: https://api.jquery.com/jquery.getscript/

    # If the url is a relative path (starts with "/" but not "//"), pass it through getCDNUrl
    # unless bypass_cdn option is set to true
    if url[0] == "/" and url.substr(0, 2) != "//" and not options?.bypass_cdn
      url = @getCDNUrl(url)

    # Allow user to set any option except for dataType, cache, and url
    options = $.extend(options or {},
      dataType: "script"
      cache: true
      url: url)
    options = _.omit options, "bypass_cdn" # bypass_cdn is our option and not jQuery ajax's so we omit it.

    # Use $.ajax() since it is more flexible than $.getScript
    # Return the jqXHR object so we can chain callbacks
    jQuery.ajax options

