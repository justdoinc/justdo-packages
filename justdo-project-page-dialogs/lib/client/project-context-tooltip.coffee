getTaskContext = (task_id, context) ->
  task = APP.collections.Tasks.findOne task_id,
    fields:
      "p:dp:is_project": 1
      parents: 1
      seqId: 1
      title: 1
  
  if not task?
    return

  if task["p:dp:is_project"] == true or task?.parents?[0]?
    # in order to prevent double count from the context:
    for prevTask in context
      if prevTask.seqId == task.seqId
        return
    context.push task
    return
  
  if task?.parents?
    for parent_id of task.parents
      getTaskContext(parent_id, context)
  
  return

Template.project_context_tooltip.onCreated ->
  self = @
  @comp = null
  @task_rv = new ReactiveVar()
  @context_rv = new ReactiveVar()
  @autorun =>
    task = APP.collections.Tasks.findOne Template.currentData().task_id,
      fields:
        _id: 1
        seqId: 1
        title: 1
        parents: 1
    
    @task_rv.set task

    context = []

    if task?.parents?
      for parent_id of task.parents
        getTaskContext parent_id, context

    @context_rv.set context
    return
    
Template.project_context_tooltip.helpers
  taskSeqId: -> Template.instance().task_rv.get().seqId
  
  taskName: -> JustdoHelpers.taskCommonName(Template.instance().task_rv.get())

  taskContext: -> Template.instance().context_rv.get()

  taskCommonName: (task) -> 
    return JustdoHelpers.taskCommonName task
