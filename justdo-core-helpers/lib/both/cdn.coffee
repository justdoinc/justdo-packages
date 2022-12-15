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
    if not cdn?
      return path

    if path[0] != "/"
      console.warn("getCDNUrl: At the moment supporting only paths beginning with /")

      return path

    return "#{cdn}#{path}"


