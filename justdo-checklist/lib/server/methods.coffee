_.extend JustdoChecklist.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      flipChecklistSwitch: (task_id) ->

        # let's verify that the user has access to the task
        t = APP.collections.Tasks.findOne({_id:task_id,users:Meteor.user()._id})
        if not t
          return
        check = true
        if (t['p:checklist:is_checklist']==true)
          check = false

        APP.collections.Tasks.update({_id:task_id},{$set: {"p:checklist:is_checklist":check}})

        return

      flipCheckItemSwitch: (task_id) ->
        # let's verify that the user has access to the task
        t = APP.collections.Tasks.findOne({_id:task_id,users:Meteor.user()._id})
        if not t
          return

        check = true
        if (t['p:checklist:is_checked']==true)
          check = false

        APP.collections.Tasks.update({_id:task_id},{$set: {"p:checklist:is_checked":check}})

        return

