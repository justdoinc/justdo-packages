# Keep here code used for db migrations

update_changelog_batch_size = 100 
update_changelog_batch_cooldown = 1000
updateChangeLogsBatch = (batch_no) ->
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
      updateChangeLogsBatch(batch_no + 1)

      return
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

      # addTasksDescriptionLastUpdate: ->
      #   projects_object.items_collection.update({$and: [
      #       {description: {$ne: null}},
      #       {description: {$ne: ""}},
      #       {description_last_update: null},
      #   ]}, {$set: {description_last_update: new Date("2020-08-14T00:00:00Z")}}, {multi: true})

      #   return
      
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
