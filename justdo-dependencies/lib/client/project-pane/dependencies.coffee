Template.justdo_project_dependencies.onCreated ->
  self = @

  @my_non_blocked_blocking_tasks = new ReactiveVar []
  @my_tasks_blocked_by_others = new ReactiveVar []

  @autorun =>
    project_id = JD.activeJustdo({_id: 1})._id

    all_the_potentially_blocked_tasks_query =
      project_id: project_id
      state: {$in: JustdoDependencies.blocked_tasks_states}
      "#{JustdoDependencies.dependencies_field_id}":
        $exists: true

    my_non_blocked_blocking_tasks = {}
    my_tasks_blocked_by_others = {}
    JD.collections.Tasks.find(all_the_potentially_blocked_tasks_query).forEach (task) ->
      if _.isEmpty(blocking_tasks_objs = APP.justdo_dependencies.getTasksObjsBlockingTask(task, {fields: {_id: 1, owner_id: 1, title: 1, seqId: 1, state: 1, project_id: 1}}))
        # Not blocked task
        return

      for blocking_task_obj in blocking_tasks_objs
        # Check if I own task and others are blocking me
        if task.owner_id == Meteor.userId() and blocking_task_obj.owner_id != Meteor.userId()
          if task._id not of my_tasks_blocked_by_others
            my_tasks_blocked_by_others[task._id] = task
            my_tasks_blocked_by_others[task._id]._blocked_by = []

          my_tasks_blocked_by_others[task._id]._blocked_by.push blocking_task_obj

        # Check if any of the blocking tasks are mine, if so, check if I can start working on it,
        # i.e. whether it should be under my_non_blocked_blocking_tasks
        if blocking_task_obj.owner_id == Meteor.userId()
          if _.isEmpty(APP.justdo_dependencies.getTasksObjsBlockingTask(blocking_task_obj))
            if blocking_task_obj._id not of my_non_blocked_blocking_tasks
              my_non_blocked_blocking_tasks[blocking_task_obj._id] = blocking_task_obj
              my_non_blocked_blocking_tasks[blocking_task_obj._id]._blocking_tasks = []
            my_non_blocked_blocking_tasks[blocking_task_obj._id]._blocking_tasks.push task

      return # end forEach

    @my_non_blocked_blocking_tasks.set _.values(my_non_blocked_blocking_tasks)
    @my_tasks_blocked_by_others.set _.values(my_tasks_blocked_by_others)

    return # end autorun

  return


Template.justdo_project_dependencies.helpers
  myNonBlockedBlockingTasks: ->
    return Template.instance().my_non_blocked_blocking_tasks.get()

  myTasksBlockedByOthers: ->
    return Template.instance().my_tasks_blocked_by_others.get()

Template.justdo_project_dependencies.events
  "click .justdo-dependencies-line": (e, tpl) ->
    if (task_id = $(e.target).closest("[task-id]").attr("task-id"))?
      gcm = APP.modules.project_page.getCurrentGcm()
      gcm.setPath(["main", task_id], {collection_item_id_mode: true})

    return
