_.extend JustdoQuickNotes.prototype,
  _attachCollectionsSchemas: ->
    quick_notes_schema =
      created:
        label: "Created On"
        type: Date
        autoValue: ->
          console.log @isInsert
          console.log @isUpsert
          if @isInsert
            return new Date()
          else if @isUpsert
            return {$setOnInsert: new Date()}
          else
            @unset()

      completed:
        label: "Completed On"
        type: Date
        optional: true

      deleted:
        label: "Deleted On"
        type: Date
        optional: true

      title:
        label: "Note Title"
        type: String

      user_id:
        label: "Note Owner"
        type: String

      order:
        label: "Note Order"
        type: Number

      created_task_id:
        label: "Created Task ID"
        type: String
        optional: true

    @quick_notes_collection.attachSchema quick_notes_schema
    return
