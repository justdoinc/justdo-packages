_.extend JustdoQuickNotes.prototype,
  _attachCollectionsSchemas: ->
    quick_notes_schema =
      created:
        label: "Created On"
        type: Date
        autoValue: ->
          if @isInsert
            return new Date()
          else if @isUpsert
            return {$setOnInsert: new Date()}
          else
            @unset()

      updated:
        label: "Quick Note Updated At"
        type: Date
        optional: true
        denyInsert: true
        autoValue: ->
          if @isUpdate
            return new Date()

          return

      completed:
        label: "Completed On"
        type: Date
        optional: true

      deleted:
        label: "Deleted On"
        type: Date
        optional: true

      title:
        label: "Quick Note Title"
        type: String

      user_id:
        label: "Quick Note Owner"
        type: String

      order:
        label: "Quick Note Order"
        type: Number

      created_task_id:
        label: "Created Task ID"
        type: String
        optional: true

    @quick_notes_collection.attachSchema quick_notes_schema
    return
