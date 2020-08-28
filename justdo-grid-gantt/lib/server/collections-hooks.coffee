_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    # Defined in db-migrations.coffee
    # @_setupDbMigrations()
    
    return

  _deferredInit: ->
    if @destroyed
      return

    # # Defined in methods.coffee
    # @_setupMethods()

    # # Defined in publications.coffee
    # @_setupPublications()

    # # Defined in allow-deny.coffee
    # @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # # Defined in collections-indexes.coffee
    # @_ensureIndexesExists()

    return
  
  _setupCollectionsHooks: ->
    @setupMilestoneRestrictions()

    return

  setupMilestoneRestrictions: ->
    self = @
    APP.collections.Projects.before.update (user_id, doc, field_names, modifier, options) ->
      if (new_custom_features = modifier?.$set?["conf.custom_features"])?
        old_custom_features = doc?.conf?.custom_features
        if JustdoGridGantt.project_custom_feature_id in _.difference new_custom_features, old_custom_features
          # grid-gantt added
          bulk_update_ops = []
          APP.collections.Tasks.find
            project_id: doc._id
            "#{JustdoGridGantt.is_milestone_pseudo_field_id}": "true"
          ,
            fields:
              _id: 1
              start_date: 1
              end_date: 1
          .forEach (task) ->
            if task.start_date?
              modifier = 
                $set:
                  end_date: task.start_date
            else if task.end_date?
              modifier = 
                $set:
                  end_date: null

            if modifier?
              APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier modifier
              bulk_update_ops.push
                updateOne:
                  filter:
                    _id: task._id
                  update: modifier
              
            return
          
          if bulk_update_ops.length > 0
            APP.justdo_analytics.logMongoRawConnectionOp(APP.collections.Tasks._name, "bulkWrite")
            APP.collections.Tasks.rawCollection().bulkWrite bulk_update_ops

      return
       
    APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options) ->
      if modifier?.$set?[JustdoGridGantt.is_milestone_pseudo_field_id] == "true" and self.isGridGanttInstalledInJustDo doc.project_id
        if not modifier.$set?
          modifier.$set = {}
        modifier.$set.end_date = doc.start_date
      else if doc?[JustdoGridGantt.is_milestone_pseudo_field_id] == "true" and 
          ((new_start_date = modifier.$set?.start_date) isnt undefined or (new_end_date = modifier.$set?.end_date) isnt undefined) and # null means unset, undefined means no change
          self.isGridGanttInstalledInJustDo doc.project_id
        if new_start_date isnt undefined # null means unset, undefined means no change
          modifier.$set.end_date = new_start_date
        else if new_end_date isnt undefined # null means unset, undefined means no change
          return false

      return true
    
    return