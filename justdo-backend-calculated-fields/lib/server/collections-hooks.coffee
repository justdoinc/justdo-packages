_.extend JustdoBackendCalculatedFields.prototype,
  _setupCollectionsHooks: ->
    @projectsCustomFieldsMaintananceHooks()

    return

  projectsCustomFieldsMaintananceHooks: ->
    self = @

    # here we want to maintain the list of enabled projects.
    self.projects_collection.after.update (user_id, doc, fieldNames, modifier, options) =>
      if (custom_features = modifier.$set?["conf.custom_features"])?
        # Note, when we update the custom_features sub-document, we set all the custom features
        # including the existing ones. So, every update to conf.custom_features is going to
        # trigger @setupCustomFieldsForProject for projects that has the backend calculated field
        # enabled, @setupCustomFieldsForProject calls @removeCustomFieldsForProject() first
        # so we avoid duplicate setup.
        if @options.custom_feature_id in custom_features
          @setupCustomFieldsForProject(doc._id, user_id)
        else
          @removeCustomFieldsForProject(doc._id, user_id)

      return

    runIfBackendCalculatedFieldsEnabled = (project_id, cb) ->
      # nothing to do if the project is not enabled
      if not self.enabled_projects_cache[project_id]?
        return

      return cb()

    # Clear the params fields field when the command changes
    self.tasks_collection.after.update (user_id, doc, fieldNames, modifier, options) ->
      runIfBackendCalculatedFieldsEnabled doc.project_id, ->
        if "backend_calc_field_cmd" in fieldNames
          # if there is a change in the calc command, clear the params
          self.tasks_collection.direct.update(doc._id, {$set: {backend_calc_field_cmd_params: ""}}, {bypassCollection2: true})

      return

    # Trigger commands updates for task change
    self.tasks_collection.after.insert (user_id, doc) ->
      runIfBackendCalculatedFieldsEnabled doc.project_id, ->
        self.triggerDueDatesCommandsUpdatesForTaskChange doc, user_id

      return

    self.tasks_collection.after.pseudo_remove (user_id, doc) ->
      runIfBackendCalculatedFieldsEnabled doc.project_id, ->

        for parent_id of doc.parents
          self.triggerDueDatesCommandsUpdatesForTaskChange self.tasks_collection.findOne(parent_id), user_id

      return

    self.tasks_collection.after.update (user_id, doc, fieldNames, modifier, options) ->
      runIfBackendCalculatedFieldsEnabled doc.project_id, ->
        # Ignore order updates
        if _.size(modifier) == 1 and "$inc" of modifier and /parents\.\w+\.order/.test(_.keys(modifier.$inc)[0])
          return

        handle_hook = (
          "due_date" in fieldNames or
          "parents" in fieldNames or
          "backend_calc_field_cmd" in fieldNames or
          "_raw_removed_date" in fieldNames or
          "backend_calc_field_cmd_params" in fieldNames
        )

        if handle_hook
          self.triggerDueDatesCommandsUpdatesForTaskChange doc, user_id

      return

    return
