_.extend JustdoDependencies.prototype,
  _attachCollectionsSchemas: ->
    # On the client, we set pseudo custom field, but still, to ensure correct
    # types we also set schema here.
    Schema =
      "#{JustdoDependencies.dependencies_field_id}":
        label: JustdoDependencies.dependencies_field_label
        type: JustdoDependencies.dependencies_field_schema_type
        optional: true
  
      "#{JustdoDependencies.dependencies_mf_field_id}":
        label: JustdoDependencies.dependencies_mf_field_label
        type: [Object]
        optional: true
        blackbox: true
        

    @tasks_collection.attachSchema Schema

    return