APP.justdo_tooltips.registerTooltip
  id: "task-info"

  template: "task_info_tooltip"

  raw_default_options:
    "id": ""
    "justdo-id": ""
    "show-title": "false"
    "title-ellipsis": "0"

  rawOptionsLoader: (raw_options) ->
    options = {
      "id": raw_options.id
      "justdo-id": if not _.isEmpty(raw_options["justdo-id"].trim()) then raw_options["justdo-id"].trim() else JD.activeJustdo({_id: 1})?._id
      "show-title": raw_options["show-title"] is "true"
      "title-ellipsis": parseInt(raw_options["title-ellipsis"], 10)
    }

    return options

Template.task_info_tooltip.onCreated ->
  @options = @data.options
  @tooltip_controller = @data.tooltip_controller

  if not @options["justdo-id"]?
    throw new Error("Not inside a Justdo and justdo-id option isn't define")

  if @options["justdo-id"] is JD.activeJustdo({_id: 1})?._id
    # We got an highly-optimized way to fetch projects if we are inside the JustDo of the task:
    current_task_id = @options.id

    gc = APP.modules.project_page.mainGridControl()
    gd = gc._grid_data

    tasks_ids = new Set()

    item_paths = gd.getAllCollectionItemIdPaths(current_task_id, false, false) # We send false to the allow_unreachable_paths argument. That means that fully unreachable *non-closed*
                                                                               # projects *won't* be in the list!
                                                                               #
                                                                               # At first, I thought to pass true to it, but it turned out that to activate the task under the fully-unreachable project
                                                                               # might in some cases be quite challenging, when the user clicks on it.
                                                                               # Imagine the case 'task a* -> project_task -> task b* -> target_task' where '*' denotes archived task. Because task_b is archived
                                                                               # as well, it is techincally impossible, as of writing, to activate target_task under project_task using activateCollectionItemUnderSpecificAncestorOrFallbackToMainTab
                                                                               # to avoid dealing with this case, I just decided to avoid getting to it by not showing fully unreachable projects in the list ~Daniel C.

    if item_paths?
      for path in item_paths
        for task_id in path.split("/")
          if task_id != "" and task_id != current_task_id
            tasks_ids.add(task_id)

    known_ancestors_by_reference = JustdoHelpers.nonReactiveFullDocFindById(APP.collections.Tasks, Array.from(tasks_ids), {get_docs_by_reference: true})[0]

    @projects_by_reference = _.filter known_ancestors_by_reference, (doc) -> doc["p:dp:is_project"] is true
  else
    # To be implemented:
    # 1. need to introduce loading indicator while loading the JustDo's tasks.
    # 2. need to implement the projects finding alg.

    return

  return

Template.task_info_tooltip.helpers
  taskProjects: ->
    {tooltip_controller, options, projects_by_reference} = Template.instance()

    return projects_by_reference

  showTaskTitle: ->
    {tooltip_controller, options} = Template.instance()

    return options["show-title"]

  taskCommonName: (task) ->
    {tooltip_controller, options} = Template.instance()

    return JustdoHelpers.taskCommonName APP.collections.Tasks.findOne(options["id"], {fields: {seqId: 1, title: 1}}), options["title-ellipsis"]

  projectCommonName: (task) -> 
    return JustdoHelpers.taskCommonName task, 70

Template.task_info_tooltip.events
  "click .task-title": ->
    {tooltip_controller, options} = Template.instance()

    APP.modules?.project_page?.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab options["id"]

    return

  "click .task": ->
    {tooltip_controller, options} = Template.instance()

    APP.modules?.project_page?.getCurrentGcm()?.activateCollectionItemUnderSpecificAncestorOrFallbackToMainTab @_id, options["id"]

    tooltip_controller.closeTooltip()

    return