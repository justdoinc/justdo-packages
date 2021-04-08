Template.project_context_tooltip.onCreated ->
  self = @
  @comp = null
  @task_rv = new ReactiveVar()

  @autorun =>
    @task_rv.set APP.collections.Tasks.findOne Template.currentData().task_id,
      fields:
        _id: 1
        seqId: 1
        title: 1
    
    return

  @setTooltipText = =>
    if not @comp?
      @comp = Tracker.autorun =>
        @$(@firstNode).html getProjectContextHtml @task_rv.get()

        return
    
    return
    
Template.project_context_tooltip.onRendered ->
  $container = @$(@firstNode).closest(".project-context-tooltip-container")
  if $container.length == 0
    console.error "Please add a class '.project-context-tooltip-container' to the container of the project_context_tooltip template"
  else
    $container.on "mouseenter", @setTooltipText

  return

Template.project_context_tooltip.onDestroyed ->
  if @comp?
    @comp.stop()
  @$(@firstNode).closest(".project-context-tooltip-container").off "mouseenter", @setTooltipText

  return

getProjectContextHtml = (task_id) ->
  task = APP.collections.Tasks.findOne task_id,
    fields:
      _id: 1
      title: 1
      seqId: 1
  project_context = JustdoHelpers.getProjectContext task._id
  projects_text = _.map(project_context, (project_task) -> JustdoHelpers.taskCommonName project_task).join ', '
  return "#{JustdoHelpers.taskCommonName(task)}:<br>#{projects_text}"
