_.extend JustdoChecklist.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    @setupTasksChangelogManagerTracker()

    return

  setupTasksChangelogManagerTracker: ->
    APP.executeAfterAppLibCode ->
      APP.tasks_changelog_manager.setupPseudoCustomFieldTrackedBySimpleTasksFieldsChangesTracker("p:checklist:is_checked", "Checked")

      return

    return

  recalcImpliedChecklistFields: (task_id, task_doc) ->
    self = @

    if not task_doc?
      if not (task_doc = @tasks_collection.findOne(task_id))?
        return

    for parent_id, parent_def of task_doc.parents
      if parent_id == "0"
        continue

      tasks = {}
      query =
        "parents.#{parent_id}": {$exists: true}
      options =
        fields:
          "p:checklist:is_checked": 1
          "p:checklist:total_count": 1
          "p:checklist:checked_count": 1
          "p:checklist:has_partial": 1
          "p:checklist:is_checklist": 1

      @tasks_collection.find(query, options).forEach (doc) ->
        tasks[doc._id] = doc

        return

      total_count = _.size(tasks)
      checked_count = 0
      has_partial = false
      for sibling_task_id, sibling_task_doc of tasks
        if sibling_task_doc["p:checklist:is_checked"] == true or
           (
            sibling_task_doc["p:checklist:total_count"]? and
            sibling_task_doc["p:checklist:total_count"] > 0 and
            (sibling_task_doc["p:checklist:total_count"] == sibling_task_doc["p:checklist:checked_count"])
           )
          checked_count += 1

        if sibling_task_doc["p:checklist:checked_count"] > 0 or
           sibling_task_doc["p:checklist:has_partial"] == true
          has_partial = true

      update = 
        $set:
          "p:checklist:total_count": total_count
          "p:checklist:checked_count": checked_count
          "p:checklist:has_partial": has_partial

      APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(update)

      APP.justdo_analytics.logMongoRawConnectionOp(@tasks_collection._name, "update", {_id: parent_id}, update)
      @tasks_collection.rawCollection().update {_id: parent_id}, update, Meteor.bindEnvironment (err) ->
        if err?
          console.error(err)

          return

        self.recalcImpliedChecklistFields(parent_id)

        return

      return false

    return

  toggleChecklistSwitch: (task_id, user_id) ->
    check task_id, String
    check user_id, String

    if not (task_doc = @tasks_collection.getItemByIdIfUserBelong task_id, user_id)?
      throw @_error "unknown-task"

    new_state = true
    if task_doc["p:checklist:is_checklist"] == true
      new_state = false

    return @tasks_collection.update(task_id, {$set: {"p:checklist:is_checklist": new_state}})

  toggleCheckItemSwitch: (task_id, user_id) ->
    check task_id, String
    check user_id, String

    if not (task_doc = @tasks_collection.getItemByIdIfUserBelong task_id, user_id)?
      throw @_error "unknown-task"

    new_state = true
    if task_doc["p:checklist:is_checked"] == true
      new_state = false

    return @tasks_collection.update(task_id, {$set: {"p:checklist:is_checked": new_state}})

