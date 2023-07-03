_.extend JustdoLicensing.prototype,
  _ensureIndexesExists: ->
    # IS_USER_LICENSED_INDEX
    Meteor.users.rawCollection().createIndex({createdAt: -1})
    return
