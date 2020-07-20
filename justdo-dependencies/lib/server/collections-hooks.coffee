_.extend JustdoDependencies.prototype,
  _setupCollectionsHooks: ->
    @chatBotHooks()
    @projectsInstallUninstallProcedures()
    @integrityCheckAndHumanReadableToMFAndBackHook()
    @setupChangeLogCapture()
    
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
    
  integrityCheckAndHumanReadableToMFAndBackHook: ->
    self = @
    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      check_dependencies = false
      # for every change in the human-readable format, update the machine friendly one
      if JustdoDependencies.dependencies_field_id in field_names
        check_dependencies = true
        new_dependencies_mf = []
        if not (new_dependencies = modifier.$set?[JustdoDependencies.dependencies_field_id])?
          new_dependencies = []
        if (new_dependency = modifier.$push?[JustdoDependencies.dependencies_field_id])?
          new_dependencies.push new_dependency
          new_dependencies_mf = doc[JustdoDependencies.dependencies_mf_field_id] or []
  
        JD.collections.Tasks.find({project_id: doc.project_id, seqId: {$in: new_dependencies}, _raw_removed_date: {$exists: false}}).forEach (dep_obj) ->
          new_dependencies_mf.push
            task_id: dep_obj._id
            type: "F2S"
            
        if (removed_dependency = modifier.$pull?[JustdoDependencies.dependencies_field_id])?
          if(removed_id = JD.collections.Tasks.findOne({project_id: doc.project_id, seqId: removed_dependency})._id)?
            old_dependencies = doc[JustdoDependencies.dependencies_mf_field_id]
            for dependency in old_dependencies
              if dependency.task_id != removed_id
                new_dependencies_mf.push dependency
        
        modifier.$set = modifier.$set or {};
        modifier.$set[JustdoDependencies.dependencies_mf_field_id] = new_dependencies_mf
        field_names.push JustdoDependencies.dependencies_mf_field_id
        
      # for every change in the MF format, update the human-readable one
      # note that we don't support updating both at the same time
      else if JustdoDependencies.dependencies_mf_field_id in field_names
        check_dependencies = true
        if (new_dependencies_mf = modifier.$set?[JustdoDependencies.dependencies_mf_field_id])?
          new_dependencies = []
          for dependency_mf in new_dependencies_mf
            if dependency_mf.type == "F2S"
              task_id = dependency_mf.task_id
              if (dep_obj = JD.collections.Tasks.findOne({project_id: doc.project_id, _id: task_id, _raw_removed_date: {$exists: false}}))?
                new_dependencies.push dep_obj.seqId
          modifier.$set = modifier.$set || {};
          modifier.$set[JustdoDependencies.dependencies_field_id] = new_dependencies
          field_names.push JustdoDependencies.dependencies_field_id
      
      if check_dependencies
        return self.checkDependenciesFormatBeforeUpdate doc, field_names, modifier, options
        
      return true
      # end of collection hook
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

  _extractUpdatedByFromModifierOrFail: (modifier) ->
    # Extract the set `updated_by` field from an update operation modifier
    # and returns it.
    # Fails if such an item can't be found by throwing the "updated-by-missing"
    # error.

    if (updated_by = modifier?.$set?.updated_by)?
      return updated_by

    throw @_error "updated-by-missing"

  setupChangeLogCapture: ->
    self = @
    self.tasks_collection.before.update (userId, doc, fieldNames, modifier, options) ->
      if modifier.$set?.justdo_task_dependencies?
        if modifier.$set.justdo_task_dependencies.length == 0
          new_value = "N/A"
        else
          new_value = modifier.$set.justdo_task_dependencies.join ","          
        
         APP.tasks_changelog_manager.logChange
          field: JustdoDependencies.dependencies_field_id
          label: JustdoDependencies.dependencies_field_label
          change_type: "update"
          task_id: doc._id
          by: self._extractUpdatedByFromModifierOrFail(modifier)
          new_value: new_value

      return
    
    return