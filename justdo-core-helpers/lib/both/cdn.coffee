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

  getCDNUrl: (path) ->
    if Meteor.isServer
      app_version = process.env.APP_VERSION
    if Meteor.isClient
      app_version = env.APP_VERSION

    if not cdn?
      return path

    if path[0] != "/"
      console.warn("getCDNUrl: At the moment supporting only paths beginning with /")

      return path

    cdn_url = "#{cdn}#{path}"

    if not _.isEmpty app_version
      query_param_prefix = "?"
      if path.includes(query_param_prefix)
        if path[path.length - 1] is "&"
          query_param_prefix = ""
        else
          query_param_prefix = "&"
      cdn_url = "#{cdn_url}#{query_param_prefix}_cv=#{encodeURIComponent app_version}"

    return cdn_url


