_.extend JustdoPushNotifications.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      pnRegisterToken: (pn_network_id, token_obj) ->
        # Security note:
        #
        # pn_network_id is checked by @generateServerChannelObject
        # token_obj is checked thoroughly by self.registerToken().

        check pn_network_id, String
        check token_obj, Object

        self.manageToken("register", pn_network_id, token_obj, @userId)

        return

      pnUnregisterToken: (pn_network_id, token_obj) ->
        # Security note:
        #
        # pn_network_id is checked by @generateServerChannelObject
        # token_obj is checked thoroughly by self.registerToken().

        check pn_network_id, String
        check token_obj, Object

        self.manageToken("unregister", pn_network_id, token_obj, @userId)

        return

      pnReportObsoleteToken: (pn_network_id, token_obj, user_id) ->
        # Security note:
        #
        # pn_network_id is checked by @generateServerChannelObject
        # token_obj is checked thoroughly by self.registerToken().

        check pn_network_id, String
        check token_obj, Object
        check user_id, String

        self.manageToken("unregister", pn_network_id, token_obj, user_id)

        return
