Template.justdo_project_dependencies.onCreated ->
  self = @

  @tasks_to_start = new ReactiveVar []
  @pending_tasks = new ReactiveVar []

  @autorun =>
    tasks_to_start = []
    pending_tasks = []
    # find all the tasks from this project, where the current user is owner, and have any dependencies
    JD.collections.Tasks.find
      project_id: JD.activeJustdo({_id: 1})._id
      owner_id: Meteor.userId()
      "#{JustdoDependencies.dependencies_field_id}":
        $exists: true
      $or: [{state: "pending"}, {state: "in-progress"}, {state: "on-hold"}, {state: "nil"}]
    .forEach (task) ->
      if task[JustdoDependencies.dependencies_field_id] != null and task[JustdoDependencies.dependencies_field_id] != ""
        all_dependents_are_done = true
        # for each dependent seq ID
        (task[JustdoDependencies.dependencies_field_id].split(/\s*,\s*/).map(Number)).forEach (dependant) ->
          if (task_obj = JD.collections.Tasks.findOne({seqId: dependant}))
            if task_obj.state != "done"
              all_dependents_are_done = false
        if all_dependents_are_done
          tasks_to_start.push task
        else
          pending_tasks.push task

    self.tasks_to_start.set tasks_to_start
    self.pending_tasks.set pending_tasks

  return


Template.justdo_project_dependencies.helpers
  tasksToStart: ->
    return Template.instance().tasks_to_start.get()

  tasksWaiting: ->
    return Template.instance().pending_tasks.get()

  hasTasksToStart: ->
    return (Template.instance().tasks_to_start.get().length > 0)
  hasTasksWaiting: ->
    return (Template.instance().pending_tasks.get().length > 0)

Template.justdo_project_dependencies.events

  "click .justdo-dependencies-line": (e, tpl) ->

    task_id = e.target.getAttribute"task_id"
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.setPath(["main", task_id], {collection_item_id_mode: true})


return
