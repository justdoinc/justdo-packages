_.extend TasksChangelogManager.prototype,
  _attachCollectionsSchemas: ->
    changelog_schema =
      when:
        label: "Change Time"
        type: Date
        autoValue: ->
          if this.isInsert
            return new Date
          else if this.isUpsert
            return {$setOnInsert: new Date}
          else
            this.unset()
      by:
        label: "Made by user ID"
        type: String

      field:
        label: "Field Name"
        type: String

      label:
        label: "Label"
        type: String

      change_type:
        label: "Change Type"
        type: String
        allowedValues: ["update", "moved_to_task", "created", "users_change", "unset", "priority_increased", "priority_decreased", "custom"]
        autoValue: ->
          if @field('change_type').value?
            return @field('change_type').value
          return "update"

      new_value:
        label: "New Value"
        type: String
        optional: true

      users_added:
        label: "Users Added"
        type: [String]
        optional: true

      users_removed:
        label: "Users Removed"
        type: [String]
        optional: true

      task_id:
        label: "Task ID"
        type: String
      
      project_id:
        label: "Project ID"
        type: String
        optional: true
      
      created_doc:
        label: "Created Doc"
        type: Object
        optional: true
        blackbox: true

    @changelog_collection.attachSchema changelog_schema