import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions
  'fcm-push': '1.1.x'
, 'justdoinc:justdo-firebase'

FCM = require('fcm-push')

_.extend JustdoFirebase.prototype,
  _immediateInit: ->
    @fcm = new FCM(@server_key)

    # Test
    #
    # message =
    #   notification:
    #     title: '$GOOG up 2.43% on the day',
    #     body: '$GOOG gained 11.80 points to close at 835.67, up 1.43% on the day.'

    #   to: "" # device token

    # @send(message)
    #   .then (response) =>
    #     console.log('Successfully sent message:', response)

    #     return
    #   .catch (error) =>
    #     console.log('Error sending message:', error)

    #     return

    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  isEnabled: -> true

  send: (message, cb) ->
    return @fcm.send message, JustdoHelpers.runInFiber(cb)

