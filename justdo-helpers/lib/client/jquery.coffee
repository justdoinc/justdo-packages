_.extend JustdoHelpers,
  getCachedScript: (url, options) ->
    # Based on a script from: https://api.jquery.com/jquery.getscript/

    # Allow user to set any option except for dataType, cache, and url
    options = $.extend(options or {},
      dataType: "script"
      cache: true
      url: url)

    # Use $.ajax() since it is more flexible than $.getScript
    # Return the jqXHR object so we can chain callbacks
    jQuery.ajax options

