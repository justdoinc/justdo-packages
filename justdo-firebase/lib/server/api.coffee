import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

firebase_admin = Npm.require("firebase-admin")

_.extend JustdoFirebase.prototype,
  _immediateInit: ->
    @firebase = firebase_admin.initializeApp
      credential: firebase_admin.credential.cert JSON.parse @server_key.replace(/\'/g, "\"")
    @fcm = @firebase.messaging()

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

  send: (message, dry_run=false, cb) ->
    @fcm.send message, dry_run
      .then (res) => cb null, res
      .catch (err) => cb err

    return
