# I believe that crypto is not available in all versions of node
# however it's available in the meteor shell, so I'm assuming that the version
# of node shipped with meteor 1.3 has crypto.
crypto = Npm.require('crypto')
# If we need to switch to a different crypto engine, this is the only function
# which needs updating
getHmac = (secret, message) ->
  hmacEngine = crypto.createHmac('sha256', secret)
  hmacEngine.update(message, 'utf8')
  return hmacEngine.digest('hex')

_.extend FilestackBase.prototype,
  signPolicy: (policy) ->
    policy = JSON.stringify policy

    # The url-safe base64 format is specified by filestack which simply
    # replaces two chars which are url-unsafe with two chars which are url-safe
    encodedPolicy = new Buffer(policy + '', 'utf8').toString('base64').replace(/\+/g, '-').replace(/\//g, '_')
    hmac = getHmac @options.secret, encodedPolicy

    return {
      policy: policy
      encoded_policy: encodedPolicy
      hmac: hmac
    }

  getHandle: (url) ->
    check(url, String)

    if url.match(/^https?:\/\/[^\\\/]+\.s3\.amazonaws\.com\//)
      regex = /([^\\\/_]+)_[^\\\/]+$/
      match = url.match(regex)
      return match?[1]
    else
      regex = /[^\\\/]+$/
      match = url.match(regex)
      return match?[0]

  cleanupRemovedFile: (file) ->
    if _.isString file
      file =
        id: @getHandle file

    if not Match.test file, Object
      throw @_error "expected-object", "File should be an object or file id (string)."

    # We're generating a policy for each request.
    # (Since we're on the server side, we could just as well generate a single
    # policy which gives full access to filestack, but then we'd have to manage
    # that key, this is simpler and fits with the way we're doing things
    # elsewhere.)
    policy =
      handle: file.id,
      expiry: Date.now() / (1000 + 60) * 30 # 30 minutes (to account for any clock mismatches)
      call: 'remove'

    signed_policy = @signPolicy policy

    url = "https://www.filestackapi.com/api/file/#{file.id}?key=#{@options.api_key}&policy=#{signed_policy.encoded_policy}&signature=#{signed_policy.hmac}"
    try
      HTTP.del url
    catch e
      if not (e?.response?.statusCode == 404)
        throw e

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
