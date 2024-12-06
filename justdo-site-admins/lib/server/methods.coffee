_.extend JustdoSiteAdmins.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      saGetAllUsers: ->
        return self.getAllUsers(@userId)

      saGetAllSiteAdminsIds: ->
        return self.getAllSiteAdminsIds(@userId)

      saSetUsersAsSiteAdmins: (users_ids) ->
        if _.isString users_ids
          users_ids = [users_ids]

        if not _.every(users_ids, (user_id) -> JustdoHelpers.isUserEmailsVerified user_id)
          throw self._error "not-supported", "Cannot promote users with non-verified emails to site admin"

        # users_ids checks are performed inside self.setUsersAsSiteAdmins
        return self.setUsersAsSiteAdmins(users_ids, @userId)

      saUnsetUsersAsSiteAdmins: (users_ids) ->
        # users_ids checks are performed inside self.unsetUsersAsSiteAdmins
        return self.unsetUsersAsSiteAdmins(users_ids, @userId)

      saDeactivateUsers: (users_ids) ->
        # users_ids checks are performed inside self.deactivateUsers
        return self.deactivateUsers(users_ids, @userId)

      saReactivateUsers: (users_ids) ->
        # users_ids checks are performed inside self.reactivateUsers
        return self.reactivateUsers(users_ids, @userId)

      saGetServerVitalsSnapshot: ->
        # users_id check is performed inside self.getServerVitalsSnapshot
        return self.getServerVitalsSnapshot(@userId)
      
      saGetServerVitalsShrinkWrapped: ->
        # users_id check is performed inside self.getServerVitalsShrinkWrapped
        return self.getServerVitalsShrinkWrapped(@userId)
      
      saRenewalRequest: (request_data) ->
        endpoint = new URL(JustdoSiteAdmins.renew_license_endpoint, "http://localhost:4000").toString()
        try
          res = HTTP.post endpoint, {data: request_data}
        catch error
          throw self._error "not-supported", "Renewal request did not receive a 200 response"
        return _.pick res, "statusCode"

    return