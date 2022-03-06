_.extend JustdoGridViews.prototype,
  _attachCollectionsSchemas: ->
    grid_views_hierachy_schema =
      type:
        label: "Grid View share type"
        type: String
        optional: true

      justdo_id:
        label: "ID of Justdo that shares the Grid View"
        type: String
        optional: true

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

      view:
        label: "Saved Grid View"
        type: [Object]

      hierarchy:
        label: "Grid View hierachy"
        type: new SimpleSchema grid_views_hierachy_schema
        optional: true

    @grid_views_collection.attachSchema grid_views_schema

    return
