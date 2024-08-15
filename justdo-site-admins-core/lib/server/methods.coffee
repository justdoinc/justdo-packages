_.extend JustdoSiteAdmins.prototype,
  _setupCoreMethods: ->
    self = @

    Meteor.methods 
      saSetUsersAsSiteAdmins: (users_ids) ->
        # users_ids checks are performed inside self.setUsersAsSiteAdmins
        return self.setUsersAsSiteAdmins(users_ids, @userId)

      saUnsetUsersAsSiteAdmins: (users_ids) ->
        # users_ids checks are performed inside self.unsetUsersAsSiteAdmins
        return self.unsetUsersAsSiteAdmins(users_ids, @userId)
    
      saGetAllUsers: ->
        return self.getAllUsers(@userId)

      saGetAllSiteAdminsIds: ->
        return self.getAllSiteAdminsIds(@userId)

      saDeactivateUsers: (users_ids) ->
        # users_ids checks are performed inside self.deactivateUsers
        return self.deactivateUsers(users_ids, @userId)

      saReactivateUsers: (users_ids) ->
        # users_ids checks are performed inside self.reactivateUsers
        return self.reactivateUsers(users_ids, @userId)

    return