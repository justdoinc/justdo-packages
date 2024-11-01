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

    return