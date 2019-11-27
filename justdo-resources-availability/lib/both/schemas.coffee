_.extend JustdoResourcesAvailability.prototype,
  _attachCollectionsSchemas: ->
    Schema =
      "#{JustdoResourcesAvailability.project_custom_feature_id}":
        type: Object
        blackbox: true
        optional: true

    @projects_collection.attachSchema Schema
    return