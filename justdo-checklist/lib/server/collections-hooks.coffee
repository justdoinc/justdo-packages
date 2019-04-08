_.extend JustdoChecklist.prototype,
  recalcImplied: (task_id, task_doc) ->
    if not task_doc?
      return

    for parent_id, parent_def of task_doc.parents
      if parent_id == "0"
        continue

      tasks = {}
      APP.collections.Tasks.find({"parents.#{parent_id}": {$exists: true}}).forEach (doc) ->
        tasks[doc._id] = doc

      checked_count = 0
      total_count = 0
      has_partial = false
      for sibling_task_id, sibling_task_doc of tasks
        total_count += 1
        # console.log "#{sibling_task_doc._id}  total: #{sibling_task_doc['p:checklist:total_count']} checked: #{sibling_task_doc['p:checklist:checked_count']}"
        if (sibling_task_doc['p:checklist:is_checked'] == true or
           (sibling_task_doc['p:checklist:total_count']? and (sibling_task_doc['p:checklist:total_count'] == sibling_task_doc['p:checklist:checked_count']))
        )
          checked_count += 1

        if (sibling_task_doc['p:checklist:checked_count'] > 0 or sibling_task_doc['p:checklist:has_partial'] == true )
          # console.log "found partial - #{sibling_task_id}"
          has_partial = true

      APP.collections.Tasks.update({_id:parent_id}, {
        $set:{'p:checklist:total_count':total_count,'p:checklist:checked_count': checked_count,'p:checklist:has_partial': has_partial}
      })

    return

  _setupCollectionsHooks: ->
    self = @

    APP.collections.Tasks.after.insert (user_id, doc) =>
      self.recalcImplied doc._id, doc

      return

    APP.collections.Tasks.after.update (user_id, doc, field_names, modifier, options) =>
      self.recalcImplied doc._id, doc

      return
