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

    if Meteor.isServer
      @server_vitals_collection.attachSchema
        system:
          type: Object
          blackbox: true
        
        mongo:
          type: Object
          blackbox: true
        
        process:
          type: Object
          blackbox: true
        
        app:
          type: Object
          blackbox: true
        
        plugins:
          type: Object
          blackbox: true
        
        long_term:
          type: Boolean
          optional: true
        
        createdAt:
          type: Date
          autoValue: ->
            if @isInsert
              return new Date
            else if @isUpsert
              return {$setOnInsert: new Date}
            else
              return @unset()

    return