_.extend JustdoGridViews.prototype,

  _attachCollectionsSchemas: ->
    grid_views_schema =
      user_id:
        label: "User ID"
        type: String

      created:
        label: "Grid View created on"
        type: Date
        autoValue: ->
          if @isInsert
            return new Date()
          else if @isUpsert
            return {$setOnInsert: new Date()}
          else
            @unset()

          return

      updated:
        label: "Grid View updated on"
        type: Date
        optional: true
        denyInsert: true
        autoValue: ->
          if @isUpdate
            return new Date()
          return

      title:
        label: "Grid View title"
        type: String

      deleted:
        label: "Grid View deleted"
        type: Boolean
        optional: true

      view:
        label: "Saved Grid View"
        type: [Object] # XXX Make an EJSON
        blackbox: true

      hierarchy:
        label: "Grid View hierarchy"
        type: Object

      "hierarchy.type":
        label: "Hierarchy type"
        type: String
        allowedValues: ["site", "justdo"]

      "hierarchy.justdo_id":
        label: "Justdo ID"
        type: String
        optional: true

      shared:
        label: "Is Grid View shared"
        type: Boolean
        optional: true

    @grid_views_collection.attachSchema grid_views_schema

    return
