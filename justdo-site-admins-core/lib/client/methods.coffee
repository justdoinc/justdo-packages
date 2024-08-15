_.extend JustdoSiteAdmins.prototype, 
  setUsersAsSiteAdmins: (users_ids, cb) ->
    return Meteor.call("saSetUsersAsSiteAdmins", users_ids, cb)

  unsetUsersAsSiteAdmins: (users_ids, cb) ->
    return Meteor.call("saUnsetUsersAsSiteAdmins", users_ids, cb)

  getAllUsers: (cb) ->
    return Meteor.call("saGetAllUsers", cb)

  getAllSiteAdminsIds: (cb) ->
    return Meteor.call("saGetAllSiteAdminsIds", cb)

  deactivateUsers: (users_ids, cb) ->
    return Meteor.call("saDeactivateUsers", users_ids, cb)

  reactivateUsers: (users_ids, cb) ->
    return Meteor.call("saReactivateUsers", users_ids, cb)
