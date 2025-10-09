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
        autoValue: ->
          if @field('change_type').value?
            return @field('change_type').value
          return "update"

      new_value:
        label: "New Value"
        type: "skip-type-check"
        optional: true
      
      "new_value.$":
        type: "skip-type-check"
        optional: true

      old_value:
        label: "Old Value"
        type: "skip-type-check"
        optional: true
      
      "old_value.$":
        type: "skip-type-check"
        optional: true

      data:
        # Optional data object to store additional information to facilitate log display
        # E.g. When a projects collection is closed/reopened, the collection type is stored in the data object
        # so that we can show "... closed this Department".
        label: "Change Data"
        type: Object
        optional: true
        blackbox: true

      undone:
        label: "Undone"
        type: Boolean
        optional: true

      undone_on:
        label: "Undone On"
        type: Date
        optional: true

      undone_by:
        label: "Undone By"
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
      
      bypass_time_filter: 
        # If set to true, multiple updates of the same field within a short period of time 
        # will not be filered out by `getFilteredActivityLogByTime`.
        type: Boolean
        optional: true

    @changelog_collection.attachSchema changelog_schema