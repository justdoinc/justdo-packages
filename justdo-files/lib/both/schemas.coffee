_.extend JustdoFiles.prototype,
  _attachCollectionsSchemas: ->
    Schema =
      "#{JustdoFiles.files_count_task_doc_field_id}":
        type: Number
        optional: true

    @tasks_collection.attachSchema Schema

    return