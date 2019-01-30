default_options = {
  # permitted_root_urls: if array, one of the root url it contains as its
  # values must be the same as the that of the target url. if null ignored
  # Very important tool to protect agains phishing attack
  permitted_root_urls: null
}

JustdoLoginTarget = (options) ->
  EventEmitter.call this

  @logger = Logger.get("justdo-login-target")

  @options = _.extend {}, default_options, options

  # @_target_url holds the internal target url
  #
  # On the client side, it is set automatically to the verified
  # target url received in the 'target' param of the hash query
  # string.
  #
  # Doesn't have much meaning in the server.
  #
  # It can be read/manipulated by the api, check api.coffee
  @_target_url = null

  @_init() # note we don't defer the call to @_init

  return @

Util.inherits JustdoLoginTarget, EventEmitter

_.extend JustdoLoginTarget.prototype,
  _error: JustdoHelpers.constructor_error