_.extend JustdoTasksCollectionsManager.prototype,
  _setupCollectionsHooks: -> 
    @tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      # This hook is responsible for logging the description change to the tasks changelog collection.
      # 
      # If change to the `description` field exists in the modifier, 
      # AND `description_is_auto_save` is NOT set to true in the same modifier,
      # this hook will log the change to the tasks changelog collection.
      # 
      # Under all circumstances, the `description_is_auto_save` field should be unset by this hook.
      # 
      # We add the `description_is_auto_save` mechanism since the description field can be very long, 
      # and it's wasteful to create an entry on every auto-save (which happens every few seconds).
      # By having this mechanism, we save the most up-to-date description content to the changelog 
      # only when the user performs an explicit save, or upon the destruction of the editor.

      is_description_modified = _.has modifier?.$set, "description"
      is_description_auto_saved = _.has modifier?.$set, "description_is_auto_save"

      # IMPORTANT: Always unset the `description_is_auto_save` field by this hook.
      delete modifier.$set.description_is_auto_save

      if is_description_auto_saved or not is_description_modified
        return
      
      new_description = modifier.$set.description
      is_description_unset = _.isEmpty new_description

      log_obj = 
        field: "description"
        label: JustdoHelpers.getCollectionSchemaForField(APP.collections.Tasks, "description")?.label
        change_type: if is_description_unset then "unset" else "update"
        task_id: doc._id
        by: user_id
        new_value: new_description

      APP.tasks_changelog_manager.logChange log_obj

      return