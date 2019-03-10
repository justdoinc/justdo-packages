_.extend JustdoChecklist.prototype,

  recalcImplied: (task_id) ->
    task = APP.collections.Tasks.findOne({_id:task_id})
    if not task
      return

    for parent,v of task.parents
      if parent == "0"
        continue

      tasks = {}
      APP.collections.Tasks.find({"parents.#{parent}":{$exists:true}}).forEach (doc) ->
        tasks[doc._id] = doc

      checked_count = 0
      total_count = 0
      has_partial = false
      for k,v of tasks
        total_count++
        # console.log "#{v._id}  total: #{v['p:checklist:total_count']} checked: #{v['p:checklist:checked_count']}"
        if (v['p:checklist:is_checked']==true or
           (v['p:checklist:total_count']? and (v['p:checklist:total_count'] == v['p:checklist:checked_count']))
        )
          checked_count++

        if (v['p:checklist:checked_count'] > 0 or v['p:checklist:has_partial'] == true )
          # console.log "found partial - #{k}"
          has_partial = true

      APP.collections.Tasks.update({_id:parent}, {
        $set:{'p:checklist:total_count':total_count,'p:checklist:checked_count': checked_count,'p:checklist:has_partial': has_partial}
      })




  _setupCollectionsHooks: ->
    self = @
    APP.collections.Tasks.after.insert (user_id, doc) =>
      self.recalcImplied doc._id
      return

    APP.collections.Tasks.after.remove (user_id, doc) =>
      self.recalcImplied doc._id
      return

    APP.collections.Tasks.after.update (user_id, doc, field_names, modifier, options) =>
      self.recalcImplied doc._id
      return
