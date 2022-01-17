# Keep here code used for db migrations
_.extend Projects.prototype,
  locked_migration_scripts: {}
  lockMigrationScript: (script_name) ->
    if @locked_migration_scripts[script_name]?
      console.warn "Migration script #{script_name} is already running"
      return false

    @locked_migration_scripts[script_name] = moment.now()
    return true
    
  unlockMigrationScript: (script_name) ->
    delete @locked_migration_scripts[script_name]

    return
      
  _setupDbMigrations: ->
    projects_object = @
    self = @

    # **IMPORTANT** Unsecure - uncomment only when needed.
    Meteor.methods
      updateAjournedMeetingsStatus: ->
        APP.meetings_manager_plugin.meetings_manager.meetings.update
          status: "adjourned"
        ,
          $set:
            status: "ended"
        ,
          multi: true
      addJustdoFilesTaskFilesCount: ->
        if not APP.justdo_files?
          console.error "JustDo Files isn't installed on this environment"

          return

        if not self.lockMigrationScript "addJustdoFilesTaskFilesCount"
          return

        tasks_ids_to_files_count = {}
        APP.justdo_files.tasks_files.find().forEach (file_doc) ->
          task_id = file_doc.meta.task_id

          if task_id not of tasks_ids_to_files_count
            tasks_ids_to_files_count[task_id] = 0

          tasks_ids_to_files_count[task_id] += 1

          return

        APP.justdo_permissions.runCbInIgnoredPermissionsScope =>
          for task_id, task_files_count of tasks_ids_to_files_count
            JD.collections.Tasks.update(task_id, {$set: {"#{JustdoFiles.files_count_task_doc_field_id}": task_files_count}})

          return

        self.unlockMigrationScript "addJustdoFilesTaskFilesCount"

        return

      # addTasksSeqIndices: ->
      #   # Add to each task a seqId by order of creation (do nothing if already has seqID)
      #   projects_object.projects_collection.find({}).forEach (project) ->
      #     projects_object.items_collection.find({project_id: project._id}, {sort: {createdAt: 1}}).forEach (task) ->
      #       if not task.seqId?
      #         projects_object.items_collection.update task._id,
      #           $set:
      #             seqId: projects_object.allocateNewTaskSeqId project._id

      # addTasksDescriptionLastUpdate: ->
      #   projects_object.items_collection.update({$and: [
      #       {description: {$ne: null}},
      #       {description: {$ne: ""}},
      #       {description_last_update: null},
      #   ]}, {$set: {description_last_update: new Date("2020-08-14T00:00:00Z")}}, {multi: true})

      #   return
      
      # migrateToJPU: (justdo_id) ->
      #   check justdo_id, Match.Maybe String

      #   enableJPUIfNeeded = (project) ->
      #     if not (plugins_list = project?.conf?.custom_features)
      #       return
            
      #     for plugin_id in plugins_list
      #       if plugin_id in JustdoPlanningUtilities.legecy_plugin_ids
      #         plugins_list.push JustdoPlanningUtilities.project_custom_feature_id
      #         APP.collections.Projects.update project._id,
      #           $set:
      #             "conf.custom_features": plugins_list
                  
      #         return
          
      #     return

      #   if justdo_id?
      #     enableJPUIfNeeded APP.collections.Projects.findOne justdo_id
      #   else
      #     APP.collections.Projects.find {},
      #       fields:
      #         _id: 1
      #         conf: 1
      #     .forEach (project) ->
      #       enableJPUIfNeeded project
            
      #       return
        
      #   # The duration recalculation will be triggered automatically in hooks defined in justdo-planning-utilties/lib/server/collections-hooks.coffee
      #   return
      
      # removeInvalidDependencies: ->
      #   if not self.lockMigrationScript "removeInvalidDependencies"
      #     return 

      #   task_id_exists_cache = {}
      #   queries_count = 0

      #   taskIdExists = (task_id) ->
      #     if not task_id_exists_cache[task_id]?
      #       task_id_exists_cache[task_id] = APP.collections.Tasks.findOne(task_id, {fields: {_id: 1}})?
      #       queries_count += 1
      #     return task_id_exists_cache[task_id]

      #   task_seqId_exists_cache = {}
      #   taskSeqIdExists = (justdo_id, seqId) ->
      #     key = "#{justdo_id}:#{seqId}"
      #     if not task_seqId_exists_cache[key]?
      #       task_seqId_exists_cache[key] = APP.collections.Tasks.findOne(
      #         project_id: justdo_id
      #         seqId: seqId
      #       ,
      #         fields: 
      #           _id: 1
      #       )?
      #       queries_count += 1

      #     return task_seqId_exists_cache[key]
        
      #   bulk_update_ops = []

      #   queries_count += 1
      #   APP.collections.Tasks.find
      #     $or: [{
      #       justdo_task_dependencies:
      #         $exists: true
      #         $ne: []
      #     },{
      #       justdo_task_dependencies_mf:
      #         $exists: true
      #         $ne: []
      #     }]
      #   .forEach (task) ->
      #     set_modifier = {}

      #     if (deps = task.justdo_task_dependencies_mf)?
      #       sanitized_deps = []
      #       need_update = false
      #       for dep in deps
      #         if taskIdExists dep.task_id
      #           sanitized_deps.push dep
      #         else
      #           need_update = true
            
      #       if need_update
      #         set_modifier.justdo_task_dependencies_mf = sanitized_deps
                  
      #     if (seq_deps = task.justdo_task_dependencies)?
      #       sanitized_seq_ids = []
      #       need_update = false
      #       for seq_id in seq_deps
      #         # APP.justdo_planning_utilities.integrityCheckAndHumanReadableToMFAndBackHook_enabled = false
      #         if taskSeqIdExists task.project_id, seq_id
      #           sanitized_seq_ids.push seq_id
      #         else
      #           need_update = true
            
      #       if need_update
      #         set_modifier.justdo_task_dependencies = sanitized_seq_ids
              
      #         # APP.justdo_planning_utilities.integrityCheckAndHumanReadableToMFAndBackHook_enabled = true
          
      #     if not _.isEmpty set_modifier
      #       bulk_update_ops.push
      #         updateOne:
      #           filter:
      #             _id: task._id
      #           update:
      #             $set: set_modifier

      #     return
        
      #   if bulk_update_ops.length > 0
      #     APP.justdo_analytics.logMongoRawConnectionOp(APP.collections.Tasks._name, "bulkWrite")
      #     APP.collections.Tasks.rawCollection().bulkWrite bulk_update_ops

      #   self.unlockMigrationScript "removeInvalidDependencies"

      #   self.logger.debug "Queried #{queries_count} times."
      #   self.logger.debug "Updated #{bulk_update_ops.length} tasks with invalid dependencies."

      #   return
            
    add_project_id_to_changelog_in_progress = false
    Meteor.methods
      addProjectIdToChangeLogCollection: ->
        # Debug note, to remove the entire project_id column:
        # db.getCollection('changeLog').update({}, {$unset: {project_id:1}} , {multi: true});

        if add_project_id_to_changelog_in_progress
          console.warn "addProjectIdToChangeLogCollection already running"
          return
        
        add_project_id_to_changelog_in_progress = true # Prevent more than one migration process from running

        assumed_changelogs_per_task = 1
        assumed_updates_per_second = 12000
        batch_cooldown = 1000
        batch_no = -1
        updateChangeLogsBatch = ->
          batch_no += 1

          bulk_update_ops = []

          batch_task_ids = new Set()
          APP.collections.TasksChangelog.find {project_id: null},
            order:
              task_id: 1 # Got an index for this order.
            fields:
              _id: 1
              task_id: 1
            limit: assumed_updates_per_second * assumed_changelogs_per_task
                   # The changelogs that need update are received from the db ordered {task_id: 1},
                   # therefore to get to use the actual throughput listed in assumed_updates_per_second
                   # we multiply it by assumed_changelogs_per_task
          .forEach (changelog_doc) ->
            batch_task_ids.add(changelog_doc.task_id)

            return

          APP.collections.Tasks.find {_id: {$in: Array.from(batch_task_ids)}},
            fields:
              _id: 1
              project_id: 1
          .forEach (task_doc) ->
            batch_task_ids.delete(task_doc._id)

            bulk_update_ops.push
              updateMany:
                filter:
                  task_id: task_doc._id
                update:
                  $set:
                    project_id: task_doc.project_id or "UNKNOWN" # We might have such crazy cases ...

            return

          # We removed from batch_task_ids all the tasks that we found in the db
          # the tasks that we didn't find were probably deleted, set their project_id
          # to "UNKNOWN"
          batch_task_ids.forEach (task_id) ->
            bulk_update_ops.push
              updateMany:
                filter:
                  task_id: task_id
                update:
                  $set:
                    project_id: "UNKNOWN"

            return

          if bulk_update_ops.length == 0
            add_project_id_to_changelog_in_progress = false

            return

          console.log "Updating changlog batch #{batch_no}, batch updateMany queries: #{bulk_update_ops.length} (Out of which #{batch_task_ids.size} of removed tasks)"
          APP.justdo_analytics.logMongoRawConnectionOp(APP.collections.TasksChangelog._name, "bulkWrite")
          begin_time = new Date()
          APP.collections.TasksChangelog.rawCollection().bulkWrite bulk_update_ops, Meteor.bindEnvironment (err) ->
            if err?
              console.error "updateChangeLogsBatch", err
              # Don't return, let the loop keep going, don't let a single failure break the chain

            console.log "Completed in: #{(new Date()) - begin_time}ms"

            Meteor.setTimeout ->
              updateChangeLogsBatch()

              return
            , batch_cooldown
            
            return

          return

        Meteor.defer ->
          updateChangeLogsBatch()

          return

        return
    
    Meteor.methods
      addTimezoneToAllJustdos: ->
        APP.collections.Projects.find
          timezone:
            $eq: null
        ,
          fields:
            _id: 1
            members: 1
        .forEach (justdo) ->
          first_admin = _.find(justdo.members, (member) -> member.is_admin)
          admin_user = Meteor.users.findOne first_admin.user_id,
            fields:
              "profile.timezone": 1
          APP.collections.Projects.update justdo._id,
            $set:
              timezone: admin_user.profile.timezone
          console.log("Adding timezone #{admin_user.profile.timezone} to #{justdo._id}")
          return

        return
    return
