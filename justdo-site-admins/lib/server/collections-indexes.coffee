_.extend JustdoSiteAdmins.prototype,
  _ensureIndexesExists: -> 
    # IS_SITE_ADMIN_LICENSED_INDEX
    Meteor.users.rawCollection().createIndex {"site_admin.is_site_admin": 1, "emails.verified": 1, createdAt: 1}
    # IS_USER_LICENSED_INDEX
    Meteor.users.rawCollection().createIndex {createdAt: 1, "site_admin.is_site_admin": 1, deactivated: 1}
    return