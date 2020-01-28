_.extend JustdoDependencies.prototype,
  _setupCollectionsHooks: ->
    @chatBotHooks()

    @projectsInstallUninstallProcedures()

    return

  chatBotHooks: ->
    self = @

    # Send a chat message that notify that all blocking tasks been fulfilled
    self.tasks_collection.after.update (user_id, doc, fieldNames, modifier, options) ->
      if not (new_state = modifier?.$set?.state)?
        return

      if new_state not in JustdoDependencies.non_blocking_tasks_states
        return

      # fetch all the tasks from this project that have any dependencies, and are candidates for 'all clear' notification
      potential_tasks = []
      JD.collections.Tasks.find
        project_id: doc.project_id
        "#{JustdoDependencies.dependencies_field_id}": doc.seqId
        state: {$in: JustdoDependencies.blocked_tasks_states}
      .forEach (potential_task_doc) ->
        if _.isEmpty(self.getTasksObjsBlockingTask(potential_task_doc))
          APP.justdo_chat.sendDataMessageAsBot("task", {task_id: potential_task_doc._id}, "bot:your-assistant", {type: "dependencies-cleared-for-execution"}, {})
          channel_obj = APP.justdo_chat.generateServerChannelObject("task", {task_id: doc._id}, "bot:your-assistant-jd-dependencies")
          channel_obj.manageSubscribers(add: [doc.owner_id])

        return

      return

    return

  projectsInstallUninstallProcedures: ->
    self = @

    self.projects_collection.after.update (user_id, doc, fieldNames, modifier, options) ->
      feature_id = JustdoDependencies.project_custom_feature_id # shortcut

      if (custom_features = modifier.$set?["conf.custom_features"])?
        previous_custom_features = @previous?.conf?.custom_features
        new_custom_features = doc.conf?.custom_features

        plugin_was_installed_before = false
        if _.isArray previous_custom_features
          plugin_was_installed_before = feature_id in previous_custom_features

        plugin_is_installed_after = false
        if _.isArray new_custom_features
          plugin_is_installed_after = feature_id in new_custom_features

        if not plugin_was_installed_before and plugin_is_installed_after
          self.performInstallProcedures(doc, user_id)

        if plugin_was_installed_before and not plugin_is_installed_after
          self.performUninstallProcedures(doc, user_id)

      return

    return