_.extend JustdoDependencies.prototype,
  _setupCollectionsHooks: ->
    @chatBotHooks()
    @projectsInstallUninstallProcedures()
    @humanReadableToMFAndBackHook()
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
    
  humanReadableToMFAndBackHook: ->
   
    self = @
    self.tasks_collection.before.update (user_id, doc, fieldNames, modifier, options) ->
      # for every change in the human-readable format, update the MF one
      if JustdoDependencies.dependencies_field_id in fieldNames
        if(new_dependencies = modifier.$set?[JustdoDependencies.dependencies_field_id])?
          new_dependencies_mf = []
          for dependency in new_dependencies
            if(dep_obj = JD.collections.Tasks.findOne({project_id: doc.project_id, seqId: dependency, _raw_removed_date: {$exists: false}}))?
              new_dependencies_mf.push
                task_id: dep_obj._id
                type: "F2S"
          modifier.$set = modifier.$set || {};
          modifier.$set[JustdoDependencies.dependencies_mf_field_id] = new_dependencies_mf
  
        # note - we do push or set but not both
        else if(new_dependency = modifier.$push?[JustdoDependencies.dependencies_field_id])?
          if(dep_obj = JD.collections.Tasks.findOne({project_id: doc.project_id, seqId: new_dependency, _raw_removed_date: {$exists: false}}))?
            new_dependencies_mf = doc[JustdoDependencies.dependencies_mf_field_id] or []
            new_dependencies_mf.push
              task_id: dep_obj._id
              type: "F2S"
          modifier.$set = modifier.$set || {};
          modifier.$set[JustdoDependencies.dependencies_mf_field_id] = new_dependencies_mf
          
      # for every change in the MF format, update the human-readable one
      # note that we don't support updating both at the same time
      else if JustdoDependencies.dependencies_mf_field_id in fieldNames
        if(new_dependencies = modifier.$set?[JustdoDependencies.dependencies_mf_field_id])?
          new_dependencies_mf = []
          for dependency in new_dependencies
            if dependency.type == "F2S"
              task_id = dependency.task_id
              if(dep_obj = JD.collections.Tasks.findOne({project_id: doc.project_id, _id: task_id, _raw_removed_date: {$exists: false}}))?
                new_dependencies_mf.push dep_obj.seqId
          modifier.$set = modifier.$set || {};
          modifier.$set[JustdoDependencies.dependencies_field_id] = new_dependencies_mf
        
      return # end of collection hook
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