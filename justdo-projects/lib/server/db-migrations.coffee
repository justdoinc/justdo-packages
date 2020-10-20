# Keep here code used for db migrations

update_changelog_batch_size = 100 
update_changelog_batch_cooldown = 1000

updateChangeLogsBatch = (batch_no) ->
    # 1,500,000 change logs in total
    #   150,000 tasks in total
    #        10 change logs on each task on average

    bulk_update_ops = []
    APP.collections.Tasks.find {},
      fields:
        _id: 1 
        project_id: 1
      skip: batch_no * update_changelog_batch_size
      limit: update_changelog_batch_size
    .forEach (task) ->
      bulk_update_ops.push
        updateMany:
          filter:
            task_id: task._id
            project_id:
              $exists: false
          update:
            $set:
              project_id: task.project_id
      
    if bulk_update_ops.length > 0
      console.log "Updating changlog batch #{batch_no}"
      APP.justdo_analytics.logMongoRawConnectionOp(APP.collections.TasksChangelog._name, "bulkWrite")
      APP.collections.TasksChangelog.rawCollection().bulkWrite bulk_update_ops
      console.log "Updated, cooldown..."
      Meteor.setTimeout ->
        updateChangeLogsBatch(batch_no+1)
      , update_changelog_batch_cooldown
    
    return

_.extend Projects.prototype,
  _setupDbMigrations: ->
    projects_object = @

    # **IMPORTANT** Unsecure - uncomment only when needed.
    Meteor.methods
      # addTasksSeqIndices: ->
      #   # Add to each task a seqId by order of creation (do nothing if already has seqID)
      #   projects_object.projects_collection.find({}).forEach (project) ->
      #     projects_object.items_collection.find({project_id: project._id}, {sort: {createdAt: 1}}).forEach (task) ->
      #       if not task.seqId?
      #         projects_object.items_collection.update task._id,
      #           $set:
      #             seqId: projects_object.allocateNewTaskSeqId project._id

      addTasksDescriptionLastUpdate: ->
        projects_object.items_collection.update({$and: [
            {description: {$ne: null}},
            {description: {$ne: ""}},
            {description_last_update: null},
        ]}, {$set: {description_last_update: new Date("2020-08-14T00:00:00Z")}}, {multi: true})

        return
      
      migrateToJPU: (justdo_id) ->
        check justdo_id, Match.Maybe String

        enableJPUIfNeeded = (project) ->
          if not (plugins_list = project?.conf?.custom_features)
            return
            
          for plugin_id in plugins_list
            if plugin_id in JustdoPlanningUtilities.legecy_plugin_ids
              plugins_list.push JustdoPlanningUtilities.project_custom_feature_id
              APP.collections.Projects.update project._id,
                $set:
                  "conf.custom_features": plugins_list
                  
              return
          
          return

        if justdo_id?
          enableJPUIfNeeded APP.collections.Projects.findOne justdo_id
        else
          APP.collections.Projects.find {},
            fields:
              _id: 1
              conf: 1
          .forEach (project) ->
            enableJPUIfNeeded project
            
            return
        
        # The duration recalculation will be triggered automatically in hooks defined in justdo-planning-utilties/lib/server/collections-hooks.coffee
        return
      
      addProjectIdToChangeLogCollection: ->
        updateChangeLogsBatch(0)

        return
          
        # return APP.collections.TasksChangelog.rawCollection().distinct("task_id",
        #   project_id:
        #     $exists: false
        # ).then (task_ids) ->
        #   bulk_update_ops = []

        #   for task_id in task_ids   # 150,000 tasks in total
        #     project_id = APP.collections.Tasks.findOne task_id,
        #       fields:
        #         project_id: 1
        #     ?.project_id

        #     console.log task_id, project_id

        #     if project_id?
        #       bulk_update_ops.push
        #         updateMany:
        #           filter:
        #             task_id: task_id
        #             project_id:
        #               $exists: false
        #           update:
        #             $set:
        #               project_id: project_id


        #   console.log JSON.stringify(bulk_update_ops)

        #   if bulk_update_ops.length > 0
        #     APP.justdo_analytics.logMongoRawConnectionOp(APP.collections.TasksChangelog._name, "bulkWrite")
        #     APP.collections.TasksChangelog.rawCollection().bulkWrite bulk_update_ops

        # task_id_to_project_id = {}
        # batch_count = 0
        # bulk_update_ops = []

        # APP.collections.TasksChangelog.find 
        #   project_id:
        #     $exists: false
        # ,
        #   fields:
        #     _id: 1
        #     task_id: 1
        # .forEach (change_log) ->
        #   if not (project_id = task_id_to_project_id[change_log.task_id])?
        #     project_id = APP.collections.Tasks.findOne change_log.task_id,
        #       fields:
        #         project_id: 1
        #     ?.project_id

        #     task_id_to_project_id[change_log.task_id] = project_id

        #   if project_id?
        #     bulk_update_ops.push
        #       updateOne:
        #         filter:
        #           _id: change_log._id
        #         update:
        #           $set:
        #             project_id: project_id
            
        #   if bulk_update_ops.length >= 100000
        #     console.log "Updating batch #{++batch_count}"
        #     APP.justdo_analytics.logMongoRawConnectionOp(APP.collections.TasksChangelog._name, "bulkWrite")
        #     APP.collections.TasksChangelog.rawCollection().bulkWrite bulk_update_ops
        #     bulk_update_ops = []
        #     console.log "Updated batch #{batch_count}"

        # if bulk_update_ops.length > 0
        #   console.log "Updating last batch"
        #   APP.justdo_analytics.logMongoRawConnectionOp(APP.collections.TasksChangelog._name, "bulkWrite")
        #   APP.collections.TasksChangelog.rawCollection().bulkWrite bulk_update_ops
        #   console.log "Updated last batch"

      icl: ->
        change_logs = []
        for i in [0...2000000]
          change_logs.push {
            _id: Random.id()
            task_id: "sggqAr9NGPYY6rhZQ"
          }

          if change_logs.length >= 100000
            console.log "inserting #{i}"
            APP.collections.TasksChangelog.rawCollection().insertMany change_logs
            console.log "#{i} inserted"
            change_logs = []

        if change_logs.length > 0
          console.log "inserting last"
          APP.collections.TasksChangelog.rawCollection().insertMany change_logs
          console.log "inserted"

        return

    # A temporary hook to block justdos with > 1000 tasks to enable justdo-planning-utilties
    # APP.collections.Projects.before.update (user_id, doc, field_names, modifier, options) ->
    #   if not (new_custom_features = modifier?.$set?["conf.custom_features"])?
    #     return true

    #   old_custom_features = doc?.conf?.custom_features or []
    #   added_custom_features = _.difference new_custom_features, old_custom_features
      
    #   if JustdoPlanningUtilities.project_custom_feature_id in added_custom_features
    #     tasks_count = APP.collections.Tasks.find 
    #       project_id: doc._id
    #     ,
    #       fields:
    #         _id: 1
    #     .count()

    #     if tasks_count > 1000
    #       projects_object.logger.log "JustDo #{doc._id} has more than 1000 tasks, blocking it from enabling justdo-planning-utilities."
    #       return false
      
    #   return true


          
          