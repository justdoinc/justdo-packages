_.extend JustdoDependencies.prototype,
  _setupCollectionsHooks: ->
    @chatBotHooks()

    @projectsInstallUninstallProcedures()

    return

  chatBotHooks: ->
    self = @

    self.tasks_collection.after.update (user_id, doc, fieldNames, modifier, options) ->
      if "state" in fieldNames
        # fetch all the tasks from this project that have any dependencies, and are candidates for 'all clear' notification
        potential_tasks = []
        JD.collections.Tasks.find
          project_id: doc.project_id
          "#{JustdoDependencies.dependencies_field_id}":
            $exists: true
          $or: [{state: "pending"}, {state: "in-progress"}, {state: "on-hold"}, {state: "nil"}]
        .forEach (task) ->
          if task[JustdoDependencies.dependencies_field_id] != null and task[JustdoDependencies.dependencies_field_id] != ""
            (task[JustdoDependencies.dependencies_field_id].split(/\s*,\s*/).map(Number)).forEach (dependant) ->
              if dependant == doc.seqId
                potential_tasks.push task

        all_dependencies = new Set()
        for task in potential_tasks
          if task[JustdoDependencies.dependencies_field_id] != null and task[JustdoDependencies.dependencies_field_id] != ""
            (task[JustdoDependencies.dependencies_field_id].split(/\s*,\s*/).map(Number)).forEach (dependant) ->
              all_dependencies.add dependant
        #cache all tasks that we might be depend on
        seq_id_2_state = {}
        JD.collections.Tasks.find
          project_id: doc.project_id
          seqId:
            $in: Array.from all_dependencies
        .forEach (task) ->
          seq_id_2_state[task.seqId] = task.state

        for task in potential_tasks
          if task[JustdoDependencies.dependencies_field_id] != null and task[JustdoDependencies.dependencies_field_id] != ""
            all_dependents_are_done = true
            (task[JustdoDependencies.dependencies_field_id].split(/\s*,\s*/).map(Number)).forEach (dependant) ->
              if seq_id_2_state[dependant] != "done"
                all_dependents_are_done = false
            if all_dependents_are_done
              APP.justdo_chat.sendDataMessageAsBot("task", {task_id: task._id}, "bot:your-assistant-jd-dependencies", {type: "dependencies-cleared-for-execution"}, {})
              channel_obj = APP.justdo_chat.generateServerChannelObject("task", {task_id: doc._id}, "bot:your-assistant-jd-dependencies")
              channel_obj.manageSubscribers(add: [doc.owner_id])
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