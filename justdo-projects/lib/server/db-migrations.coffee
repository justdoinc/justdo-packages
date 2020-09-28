# Keep here code used for db migrations

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
    
    # A temporary hook to block justdos with > 1000 tasks to enable justdo-planning-utilties
    APP.collections.Projects.before.update (user_id, doc, field_names, modifier, options) ->
      if not (new_custom_features = modifier?.$set?["conf.custom_features"])?
        return true

      old_custom_features = doc?.conf?.custom_features or []
      added_custom_features = _.difference new_custom_features, old_custom_features
      
      if JustdoPlanningUtilities.project_custom_feature_id in added_custom_features
        tasks_count = APP.collections.Tasks.find 
          project_id: doc._id
        ,
          fields:
            _id: 1
        .count()

        if tasks_count > 1000
          projects_object.logger.log "JustDo #{doc._id} has more than 1000 tasks, blocking it from enabling justdo-planning-utilities."
          return false
      
      return true


          
          