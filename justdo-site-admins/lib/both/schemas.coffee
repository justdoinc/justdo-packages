_.extend JustdoSiteAdmins.prototype,
  _attachCollectionsSchemas: ->
    Meteor.users.attachSchema
      "site_admin.is_site_admin":
        optional: true

        type: Boolean

      "site_admin.added_by":
        optional: true

        type: String

      "site_admin.added_at":
        optional: true

        type: Date

      "site_admin.initiated_modules":
        optional: true

        type: [String]
