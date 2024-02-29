APP.justdo_tooltips.registerTooltip
  id: "ai-wizard-tooltip"
  template: "ai_wizard_tooltip"

prev_task_id = ""
prev_pub_id = ""

Template.ai_wizard_tooltip.onCreated ->
  tpl = @
  tpl.pub_id_rv = new ReactiveVar prev_pub_id
  tpl.is_loading_rv = new ReactiveVar false

  tpl.isResponseExists = ->
    if _.isEmpty(pub_id = @pub_id_rv.get())
      return false
    return APP.collections.AIResponse.findOne({pub_id: pub_id, parent: -1}, {fields: {_id: 1}})?

  tpl.streamTemplateFromOpenAi = ->
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
    

    options = 
      req_template_id: "stream_child_tasks"
      req_options:
        project: JD.activeJustdo({title: 1})?.title
        target_task: JD.activeItem({title: 1})?.title
        parents: parent_titles
        siblings: sibling_titles
        children: children_titles
      subOnReady: -> tpl.showDropdown()
      subOnStop: -> tpl.is_loading_rv.set false
    tpl.is_loading_rv.set true
    APP.justdo_ai_kit.createStreamRequestAndPublishResponse options, (err, pub_id) ->
      old_pub_id = Tracker.nonreactive -> tpl.pub_id_rv.get()

      if not _.isEmpty(old_pub_id)
        APP.justdo_ai_kit.stopAndDeleteSubHandle old_pub_id
        tpl.removeAllItemsWithPubIdInMiniMongo old_pub_id
      
      tpl.pub_id_rv.set ""

      prev_pub_id = pub_id
      tpl.pub_id_rv.set pub_id

      return
    return

  tpl.removeAllItemsWithPubIdInMiniMongo = (pub_id) ->
    APP.collections.AIResponse._collection.remove({pub_id: pub_id})
    return

  tpl.autorun ->
    APP.collections.AIResponse.find().fetch()
    $(".ai-wizard-list").animate(scrollTop: $(".ai-wizard-list").prop("scrollHeight"), 100)

  if (task_id = JD.activeItemId()) isnt prev_task_id
    tpl.removeAllItemsWithPubIdInMiniMongo  tpl.pub_id_rv.get()
    tpl.streamTemplateFromOpenAi()
    prev_task_id = task_id

  return

Template.ai_wizard_tooltip.helpers
  isLoading: ->
    tpl = Template.instance()
    return tpl.is_loading_rv.get()

  isResponseExists: ->
    tpl = Template.instance()
    return tpl.isResponseExists()

  rootTemplate: ->
    tpl = Template.instance()
    if _.isEmpty(pub_id = tpl.pub_id_rv.get())
      return

    root_tasks = APP.collections.AIResponse.find({pub_id: pub_id, parent: -1}).fetch()

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

    return

  "click .ai-wizard-stop": (e, tpl) ->
    APP.justdo_ai_kit.stopStreamAndKillPublication tpl.pub_id_rv.get()
    return

  "click .ai-wizard-create": (e, tpl) ->
    pub_id = tpl.pub_id_rv.get()
    project_id = JD.activeJustdoId()

    query =
      pub_id: pub_id
      parent: -1
    if not _.isEmpty(excluded_item_keys = $(".ai-wizard-item-checkbox:not(.checked)").map((i, el) -> $(el).data("key")).get())
      query.key =
        $nin: excluded_item_keys

    grid_data = APP.modules.project_page.gridData()
    transformTemplateItemToTaskDoc = (template_item) ->
      template_item.project_id = project_id
      delete template_item.parent
      delete template_item._id
      delete template_item.key
      delete template_item.pub_id
      return template_item
    recursiveBulkCreateTasks = (path, template_items_arr) ->
      # template_item_keys is to keep track of the corresponding template item id for each created task
      template_item_keys = _.map template_items_arr, (item) -> item.key
      items_to_add = _.map template_items_arr, (item) -> transformTemplateItemToTaskDoc item
      path = "/" + JD.activeItemId() + path

      grid_data.bulkAddChild path, items_to_add, (err, created_task_ids) ->
        if err?
          JustdoSnackbar.show
            text: err.reason or err
          return

        for created_task_id_and_path, i in created_task_ids
          created_task_path = created_task_id_and_path[1]
          corresponding_template_item_key = template_item_keys[i]
          child_query =
            pub_id: pub_id
            parent: corresponding_template_item_key
          if not _.isEmpty excluded_item_keys
            child_query.key =
              $nin: excluded_item_keys

          template_items = APP.collections.AIResponse.find(child_query).fetch()
          recursiveBulkCreateTasks created_task_path, template_items

      return

    if _.isEmpty(template_items = APP.collections.AIResponse.find(query).fetch())
      return

    recursiveBulkCreateTasks("/", template_items)

    $(".jd-tt-ai-wizard-tooltip-container").remove()

    return

Template.ai_wizard_item.helpers
  childTemplate: ->
    return APP.collections.AIResponse.find({pub_id: @pub_id, parent: @key}).fetch()
