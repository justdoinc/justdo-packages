_.extend JustdoSiteAdmins.prototype,
  getAllUsers: (cb) ->
    return Meteor.call("saGetAllUsers", cb)

  getAllSiteAdminsIds: (cb) ->
    return Meteor.call("saGetAllSiteAdminsIds", cb)

  setUsersAsSiteAdmins: (users_ids, cb) ->
    return Meteor.call("saSetUsersAsSiteAdmins", users_ids, cb)

  unsetUsersAsSiteAdmins: (users_ids, cb) ->
    return Meteor.call("saUnsetUsersAsSiteAdmins", users_ids, cb)

  deactivateUsers: (users_ids, cb) ->
    return Meteor.call("saDeactivateUsers", users_ids, cb)

  reactivateUsers: (users_ids, cb) ->
    return Meteor.call("saReactivateUsers", users_ids, cb)

  getServerVitalsSnapshot: (cb) ->
    return Meteor.call("saGetServerVitalsSnapshot", cb)
  
  getServerVitalsShrinkWrapped: (cb) ->
    return Meteor.call("saGetServerVitalsShrinkWrapped", cb)
  
  renewalRequest: (request_data, cb) ->
    return Meteor.call("saRenewalRequest", request_data, cb)