prev_task_doc = {}
prev_input = ""
prev_stream_handler = {}
prev_excluded_item_keys = []

Template.ai_wizard_tooltip.onCreated ->
  tpl = @
  tpl.stream_handler_rv = new ReactiveVar prev_stream_handler
  tpl.is_loading_rv = new ReactiveVar false

  tpl.updateDropdownPosition = ->
    return
    
    # Update dropdown position to ensure it is always visible
    $connected_element = APP.justdo_ai_kit.tooltip_dropdown.$connected_element
    APP.justdo_ai_kit.tooltip_dropdown.updateDropdownPosition $connected_element
    return

  tpl.resizeInput = ->
    # Resize the textarea
    textarea = $(".ai-wizard-input").get(0)
    textarea.style.height = "auto"
    textarea.style.height = textarea.scrollHeight + 2 + "px" # Add an extra 2px to compensate for the top and bottom borders

    # Update dropdown position to ensure it is always visible
    tpl.updateDropdownPosition()

    return

  tpl.isResponseExists = ->
    if _.isEmpty(stream_handler = @stream_handler_rv.get())
      return false

    return stream_handler.findOne({"data.parent": -1}, {fields: {_id: 1}})?

  tpl.generateTaskTitleAndAddDescriptionIfEmpty = (task_id) ->
    # Task already has title. return.
    if not APP.collections.Tasks.findOne({_id: task_id, title: null}, {fields: {_id: 1}})?
      return

    # Otherwise, generate a task title and update description from the user input
    APP.justdo_ai_kit.generateTaskTitle prev_input, (err, res) ->
      if err?
        return

      APP.collections.Tasks.update task_id, 
        $set:
          title: res.title
          description: TAPi18n.__ "ai_wizard_tooltip_generated_description", {prompt: prev_input}
      
      APP.justdo_ai_kit.logResponseUsage res.req_id, "a", res.title
      return
    
    return

  tpl.streamTemplateFromOpenAi = ->
    if tpl.is_loading_rv.get()
      return
  
    active_path = JD.activePath()
    active_task_id = GridData.helpers.getPathItemId active_path

    parent_tasks_query = 
      _id:
        $in:
          GridData.helpers.getPathArray active_path
        $ne: active_task_id
    parent_titles = APP.collections.Tasks.find(parent_tasks_query, {fields: {title: 1}}).map (task) -> task.title

    child_or_sibling_limit = 10 # Limit the number of siblings and children to 10

    parent_task_id = GridData.helpers.getPathParentId active_path
    active_task_order = JD.activeItem({parents: 1}).parents[parent_task_id].order
    sibling_task_query = 
      $or: [
        "parents.#{parent_task_id}.order":
          $lte: active_task_order
          $gte: active_task_order - child_or_sibling_limit
      ,
        "parents.#{parent_task_id}.order":
          $lte: active_task_order + child_or_sibling_limit
          $gte: active_task_order
      ]
      _id: 
        $ne: active_task_id
    sibling_task_candidates = APP.collections.Tasks.find(sibling_task_query, {fields: {title: 1, parents: 1}}).fetch()
    # For sibling tasks, we want to get the closest tasks to the active task. 
    # We sort the tasks by the absolute difference between the active task's order and the sibling task's order
    # For example, if active task has order of 5, the result of the following sort is [{...order: 4}, {...order: 6}, {...order: 3}, ...] 
    sibling_task_candidates = _.sortBy sibling_task_candidates, (task) ->
      task_order_offset = Math.abs(task.parents[parent_task_id].order - active_task_order)
      return task_order_offset
    sibling_titles = _.map(sibling_task_candidates.slice(0, child_or_sibling_limit), (task) -> task.title)
    
    children_titles = APP.collections.Tasks.find({"parents.#{active_task_id}": {$ne: null}}, {fields: {title: 1}, limit: child_or_sibling_limit}).map (task) -> task.title
    
    tpl.is_loading_rv.set true
    if not _.isEmpty(old_stream_handler = tpl.stream_handler_rv.get())
      old_stream_handler.logResponseUsage "d"
      old_stream_handler.stopSubscription()

    options = 
      template_id: "stream_child_tasks"
      template_data:
        target_task: JD.activeItem({title: 1})?.title
        additional_context:
          siblings: sibling_titles
          children: children_titles
          parents: parent_titles
          project: JD.activeJustdo({title: 1})?.title
      subOnReady: -> tpl.is_loading_rv.set false
      subOnStop: (err) ->
        if err?
          JustdoSnackbar.show
            text: TAPi18n.__ "stream_response_generic_err"
          tpl.is_loading_rv.set false
        return
    
    # Use the user input as the target task if it is not the same as the target task in the template data
    if (user_input = $(".ai-wizard-input").val()?.trim()) and (user_input isnt (target_task_title = options.template_data.target_task))
      if not _.isEmpty target_task_title
        options.template_data.additional_context.parents.push target_task_title

      options.template_data.target_task = user_input
      prev_input = user_input

    stream_handler = APP.justdo_ai_kit.createStreamRequestAndSubscribeToResponse options
    tpl.stream_handler_rv.set stream_handler
    prev_stream_handler = stream_handler

    tpl.updateDropdownPosition()
    
    return

  tpl.autorun ->
    if _.isEmpty(stream_handler = tpl.stream_handler_rv.get())
      return

    stream_handler.find({}, {fields: {_id: 1}}).fetch() # for reactivity
    $(".ai-wizard-list").animate(scrollTop: $(".ai-wizard-list").prop("scrollHeight"), 100)
    tpl.updateDropdownPosition()
    return

  tpl.active_path = JD.activePath()


  processGeneratedTaskForAddition = (generated_root_task) ->
    root_task_to_add = 
      _id: generated_root_task._id
      title: generated_root_task.data.title
      description: generated_root_task.data.description or ""
    
    return root_task_to_add

  processed_task_ids = new Set()

  # Create preview context first
  gc = APP.modules.project_page.gridControl()
  preview_ctx = gc.createPreviewContext()

  tpl.autorun ->
    if _.isEmpty(stream_handler = tpl.stream_handler_rv.get())
      return
    
    processed_task_ids_arr = Array.from(processed_task_ids)

    root_tasks_to_add = []
    generated_root_tasks_query = 
      "data.parent": -1
      _id:
        $nin: processed_task_ids_arr
    stream_handler.find(generated_root_tasks_query).forEach (generated_root_task) ->
      root_tasks_to_add.push processGeneratedTaskForAddition generated_root_task
    
    if not _.isEmpty root_tasks_to_add
      created_root_task_ids = preview_ctx.bulkAddChild tpl.active_path, root_tasks_to_add
      for created_root_task_id in created_root_task_ids
        processed_task_ids.add created_root_task_id

    generated_child_tasks_query = 
      "data.parent":
        $in: _.map processed_task_ids_arr, (task_id) -> parseInt task_id.split("_")[0]
      _id:
        $nin: processed_task_ids_arr
    stream_handler.find(generated_child_tasks_query).forEach (generated_child_task) ->
      parent_id = _.find processed_task_ids_arr, (root_task_id) -> root_task_id.startsWith "#{generated_child_task.data.parent}_"
      child_task_to_add = processGeneratedTaskForAddition generated_child_task

      created_child_task_id = preview_ctx.addChild tpl.active_path + "#{parent_id}/", child_task_to_add
      processed_task_ids.add created_child_task_id

    return

  active_task = JD.activeItem({title: 1})
  if (active_task._id isnt prev_task_doc._id) or (active_task.title isnt prev_task_doc.title)
    if not _.isEmpty(prev_stream_handler = tpl.stream_handler_rv.get())
      prev_stream_handler.logResponseUsage "d"
      prev_stream_handler.stopSubscription()
      tpl.stream_handler_rv.set {}
    
    prev_task_doc = active_task
    prev_input = ""
    prev_excluded_item_keys = []

    if _.isEmpty active_task.title
      return

    tpl.streamTemplateFromOpenAi()

  return

Template.ai_wizard_tooltip.onRendered ->
  tpl = @
  tpl.resizeInput()
  tpl.$(".ai-wizard-input").focus()

  return

Template.ai_wizard_tooltip.helpers
  previousInputOrActiveTaskTitle: -> 
    if not _.isEmpty(prev_input)
      return prev_input
    return JD.activeItem({title: 1})?.title
  
  isActiveTaskTitleEmpty: ->
    return _.isEmpty JD.activeItem({title: 1})?.title

  isLoading: ->
    tpl = Template.instance()
    return tpl.is_loading_rv.get()

  isResponseExists: ->
    tpl = Template.instance()
    return tpl.isResponseExists()

  rootTemplate: ->
    tpl = Template.instance()
    if _.isEmpty(stream_handler = tpl.stream_handler_rv.get())
      return

    root_tasks = stream_handler.find({"data.parent": -1}).fetch()

    return root_tasks
  
  ucFirst: (str) -> JustdoHelpers.ucFirst str

Template.ai_wizard_tooltip.events
  "click .ai-wizard-generate": (e, tpl) ->
    tpl.streamTemplateFromOpenAi()

    return

  "click .ai-wizard-item-content": (e, tpl) ->
    item_content = $(e.target).closest(".ai-wizard-item-content")
    checkbox = item_content.find(".ai-wizard-item-checkbox")
    check_state = null

    if checkbox.hasClass "checked"
      check_state = false
      checkbox.removeClass "checked"
    else
      check_state = true
      checkbox.addClass "checked"

    item_content.siblings().each (i, el) ->
      $(el).find(".ai-wizard-item-checkbox").each (i, el_checkbox) ->
        if check_state
          $(el_checkbox).addClass "checked"
        else
          $(el_checkbox).removeClass "checked"

        return
      return
    
    if check_state
      # Ensure all parents are checked
      $item = $(e.target).closest(".ai-wizard-item")
      while ($parent_content = $item.siblings(".ai-wizard-item-content")).length > 0
        $parent_content.find(".ai-wizard-item-checkbox").addClass "checked"
        $item = $parent_content.closest(".ai-wizard-item")
    
    # Store the excluded items for showing the same state if the tooltip is re-opened in the same task.
    prev_excluded_item_keys = $(".ai-wizard-item-checkbox:not(.checked)").map((i, el) -> $(el).data("key")).get()

    return

  "click .ai-wizard-stop": (e, tpl) ->
    stream_handler = tpl.stream_handler_rv.get()
    stream_handler.stopStream()
    return

  "click .ai-wizard-create": (e, tpl) ->
    stream_handler = tpl.stream_handler_rv.get()
    project_id = JD.activeJustdoId()
    task_id = JD.activeItemId()
    handled_item_keys = []

    query =
      "data.parent": -1
    if not _.isEmpty(excluded_item_keys = $(".ai-wizard-item-checkbox:not(.checked)").map((i, el) -> $(el).data("key")).get())
      handled_item_keys = handled_item_keys.concat excluded_item_keys
      query.key =
        $nin: excluded_item_keys

    created_task_paths = []
    grid_data = APP.modules.project_page.gridData()
    grid_control = grid_data.grid_control
    postItemsCreationCallback = (created_task_path) ->
      if _.isString created_task_path
        grid_control.once "rebuild_ready", ->
          grid_control.forceItemsPassCurrentFilter GridData.helpers.getPathItemId created_task_path
          grid_data.expandPath created_task_path
          return
      
      # If not all tasks are created, return here.
      if stream_handler.find().count() isnt handled_item_keys.length
        return            

      JustdoSnackbar.show
        text: TAPi18n.__ "ai_wizard_created_task_msg", {count: created_task_paths.length}
        duration: 1000 * 30
        showDismissButton: true
        actionText: TAPi18n.__ "undo"
        onActionClick: ->
          JustdoSnackbar.close()
          grid_data.bulkRemoveParents created_task_paths.reverse(), (err) ->
            if err?
              JustdoSnackbar.show
                text: err.reason or err
            return
        
      stream_handler.stopSubscription()
      prev_task_doc = {}

      return
    recursiveBulkCreateTasks = (path, template_items_arr) ->
      # template_item_keys is to keep track of the corresponding template item id for each created task
      template_item_keys = _.map template_items_arr, (item) -> item.key
      items_to_add = _.map template_items_arr, (item) -> 
        item.data.project_id = project_id
        return item.data

      grid_data.bulkAddChild path, items_to_add, (err, created_task_ids_and_paths) ->
        if err?
          JustdoSnackbar.show
            text: err.reason or err
          return
        
        for created_task_id_and_path, i in created_task_ids_and_paths
          created_task_path = created_task_id_and_path[1]
          corresponding_template_item_key = template_item_keys[i]

          created_task_paths.push created_task_path
          handled_item_keys.push corresponding_template_item_key

          child_query =
            "data.parent": corresponding_template_item_key

          if not _.isEmpty excluded_item_keys
            child_query.key =
              $nin: excluded_item_keys

          template_items = stream_handler.find(child_query).fetch()
          if _.isEmpty (template_items = stream_handler.find(child_query).fetch())
            postItemsCreationCallback created_task_path
          else
            recursiveBulkCreateTasks created_task_path, template_items

      return

    if _.isEmpty(template_items = stream_handler.find(query).fetch())
      return
    
    choice = "a"
    if not _.isEmpty excluded_item_keys
      choice = "p"
    choice_data = stream_handler.find({key: {$nin: excluded_item_keys}}).fetch()
    stream_handler.logResponseUsage choice, choice_data

    recursiveBulkCreateTasks(JD.activePath(), template_items)

    tpl.generateTaskTitleAndAddDescriptionIfEmpty task_id

    APP.justdo_ai_kit.closeAiWizardTooltip()

    return

  "keydown .ai-wizard-input": (e, tpl) ->
    # cmd/ctrl enter triggers the create action
    if (e.keyCode is 13) and (e.ctrlKey or e.metaKey)
      tpl.streamTemplateFromOpenAi()

    return

  "input .ai-wizard-input": (e, tpl) ->
    tpl.resizeInput()

    return
  
  "paste .ai-wizard-input": (e, tpl) ->
    e.preventDefault()
    if not (clipboard_val = e.originalEvent.clipboardData?.getData("text/plain"))?
      return

    $(".ai-wizard-input").val(clipboard_val.trim()).trigger("input")

    return

Template.ai_wizard_item.onCreated ->
  @parentTemplateInstance = -> Blaze.getView("Template.ai_wizard_tooltip").templateInstance()
  return

Template.ai_wizard_item.helpers
  childTemplate: ->
    stream_handler = Template.instance().parentTemplateInstance().stream_handler_rv.get()
    return stream_handler.find({"data.parent": @key}).fetch()

  unchecked: -> @key in prev_excluded_item_keys