determineCDNdomain = ->
  if Meteor.isServer
    _cdn = process.env.CDN
  else
    _cdn = window.CDN

  if _cdn? and _.isString(_cdn) and not _.isEmpty(_cdn = _cdn.trim())
    if _cdn[_cdn.length - 1] is "/"
      return _cdn.slice(0, _cdn.length -1)
    return _cdn
  else
    return undefined

determineCDNDomainWithProtocol = ->
  if not (_cdn_domain = determineCDNdomain())?
    return _cdn_domain

  return "//#{determineCDNdomain()}"

cdn_domain = determineCDNdomain()
cdn = determineCDNDomainWithProtocol()

_.extend JustdoCoreHelpers,
  getCDNDomain: -> cdn_domain

  # This function returns the CDN URL for a given path.
  #
  # If the path does not start with a "/", it returns the path as is.
  # If the path starts with "//", it returns the path as is.
  # If a CDN is not configured, it returns the path as is.
  # If an app version is available in the env/process.env, it appends it as a query parameter to the CDN URL.
  # options:
  #   add_protocol (defualt: false): (RELEVANT ONLY IF a CDN is defined!) adds the protocol to the CDN URL - only if the CDN URL starts with "//". 
  #   add_domain_if_no_cdn (default: false): (RELEVANT ONLY IN ENVS WITHOUT CDN URL) adds the domain to the path if no CDN URL is configured.
  getCDNUrl: (path, options) ->
    URL = JustdoCoreHelpers.getURL()

    if Meteor.isServer
      app_version = process.env.APP_VERSION
    if Meteor.isClient
      app_version = env.APP_VERSION

    if not cdn?
      if options?.add_domain_if_no_cdn
        return new URL path, JustdoCoreHelpers.getRootUrl()
      else
        return path

    if path[0] != "/"
      # console.warn("getCDNUrl: At the moment supporting only paths beginning with /")
      return path

    if path.substr(0, 2) == "//"
      # console.info("getCDNUrl: // prefix isn't supported")
      return path

    cdn_url = "#{cdn}#{path}"

    if not _.isEmpty app_version
      query_param_prefix = "?"
      if path.includes(query_param_prefix)
        if path[path.length - 1] in ["&", "?"]
          query_param_prefix = ""
        else
          query_param_prefix = "&"
      cdn_url = "#{cdn_url}#{query_param_prefix}_cv=#{encodeURIComponent app_version}"

    if options?.add_protocol and cdn_url.substr(0, 2) == "//"
      protocol = new URL(JustdoCoreHelpers.getRootUrl()).protocol # Includes the colon

      cdn_url = "#{protocol}#{cdn_url}"

    return cdn_url
