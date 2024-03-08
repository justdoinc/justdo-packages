Template.project_template_welcome_ai.onCreated ->
  @stream_handler_rv = new ReactiveVar {}
  @is_loading_rv = new ReactiveVar false
  # Store the request sent for template generation, for use with project title generation
  @sent_request = ""

  @lockInput = ->
    $(".welcome-ai-input").prop "disabled", true
    return
  @unlockInput = ->
    $(".welcome-ai-input").prop "disabled", false
    return

  @isResponseExists = ->
    if _.isEmpty(stream_handler = @stream_handler_rv.get())
      return false
    return stream_handler.findOne({parent: -1}, {fields: {_id: 1}})?

  @showDropdown = -> $(".welcome-ai-dropdown").addClass "show"
  @hideDropdown = -> $(".welcome-ai-dropdown").removeClass "show"

  @autorun ->
    APP.collections.AIResponse.find().fetch()
    $(".welcome-ai-results-items").animate(scrollTop: $('.welcome-ai-results-items').prop("scrollHeight"), 100)

    return

  @sendRequestToOpenAI = (request) ->
    tpl = @

    @sent_request = request
    @is_loading_rv.set true
    @lockInput()
    
    if not _.isEmpty(old_stream_handler = tpl.stream_handler_rv.get())
      old_stream_handler.stopSubscription()

    options = 
      template_id: "stream_project_template"
      template_data: 
        msg: request.msg
      cache_token: request.cache_token
      subOnReady: -> 
        tpl.is_loading_rv.set false
        tpl.unlockInput()
        return
      subOnStop: (err) ->
        if err?
          JustdoSnackbar.show
            text: TAPi18n.__ "stream_response_generic_err"
          tpl.is_loading_rv.set false
          tpl.unlockInput()
        return

    stream_handler = APP.justdo_ai_kit.createStreamRequestAndSubscribeToResponse options
    tpl.stream_handler_rv.set stream_handler
    tpl.showDropdown()

  return

Template.project_template_welcome_ai.onRendered ->
  $(".welcome-ai-input").focus()

  return

Template.project_template_welcome_ai.helpers
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

    if not _.isEmpty(root_tasks = stream_handler.find({parent: -1}).fetch())
      tpl.showDropdown()

    return root_tasks

Template.project_template_welcome_ai.events
  "focus .welcome-ai-input": (e, tpl) ->
    tpl.showDropdown()

    return

  "click .welcome-ai-suggestion-item": (e, tpl) ->
    # On the first click, we fetch the pre-definied template from server and remove the data attribute.
    # On the second click of the same item, if the user wishes to re-generate, we actually pass the request to OpenAI.

    request = $(e.currentTarget).text()
    $(".welcome-ai-input").val request
    tpl.lockInput()
    tpl.hideDropdown()
    
    if (template_id = $(e.currentTarget).data("template_id"))?
      $(e.currentTarget).removeData "template_id"
      tpl.sendRequestToOpenAI {cache_token: template_id, msg: request}
    else
      $(".welcome-ai-btn-generate").click()

    return

  "click .welcome-ai-btn-generate": (e, tpl) ->
    request = $(".welcome-ai-input").val().trim()

    # If request is empty, use the first example prompt from the dropdown.
    if _.isEmpty request
      $($(".welcome-ai-suggestion-item").get(0)).click()
    else
      tpl.sendRequestToOpenAI {msg: request}

    return

  "keyup .welcome-ai-input": (e, tpl) ->
    request = $(".welcome-ai-input").val().trim()

    if _.isEmpty(request) or tpl.isResponseExists()
      tpl.showDropdown()
    else
      tpl.hideDropdown()

    if e.keyCode is 13
      $(".welcome-ai-btn-generate").click()
    return

  # This is to handle the checkbox logic for the AI response items:
  # If a child item is checked, all its parent items will be checked;
  # If a parent item is unchecked, all its child items will be unchecked.
  "click .welcome-ai-result-item-content": (e, tpl) ->
    $item_content = $(e.target).closest(".welcome-ai-result-item-content")
    $checkbox = $item_content.find(".welcome-ai-result-item-checkbox")
    check_state = null

    if $checkbox.hasClass "checked"
      check_state = false
      $checkbox.removeClass "checked"
    else
      check_state = true
      $checkbox.addClass "checked"

    # Checks/unchecks child tasks
    $item_content.siblings().each (i, el) ->
      $(el).find(".welcome-ai-result-item-checkbox").each (i, el_checkbox) ->
        if check_state
          $(el_checkbox).addClass "checked"
        else
          $(el_checkbox).removeClass "checked"

        return
      return
    
    if check_state
      # Ensure all parents are checked
      $item = $(e.target).closest(".welcome-ai-result-item")
      while ($parent_content = $item.siblings(".welcome-ai-result-item-content")).length > 0
        $parent_content.find(".welcome-ai-result-item-checkbox").addClass "checked"
        $item = $parent_content.closest(".welcome-ai-result-item")

    return

  "click .welcome-ai-create-btn": (e, tpl) ->
    # Set the project title
    if (template = APP.justdo_projects_templates.getTemplateById tpl.sent_request.cache_token)?
      project_title = TAPi18n.__ template.label_i18n
      APP.collections.Projects.update JD.activeJustdoId(), {$set: {title: project_title}}
    else
      APP.justdo_projects_templates.generateProjectTitleFromOpenAi tpl.sent_request.msg, (err, title) ->
        if err?
          console.error err
          return

        APP.collections.Projects.update JD.activeJustdoId(), {$set: {title}}
        return

    stream_handler = tpl.stream_handler_rv.get()
    project_id = JD.activeJustdoId()
    grid_data = APP.modules.project_page.gridData()
    postNewProjectTemplateCreationCallback = (created_task_path) ->
      grid_control = grid_data.grid_control

      if not (project_id = JD.activeJustdoId())?
        return

      if _.isString created_task_path
        grid_control.once "rebuild_ready", ->
          grid_control.forceItemsPassCurrentFilter GridData.helpers.getPathItemId created_task_path
          grid_data.expandPath created_task_path
          return
      
      # If not all tasks are created, return here.
      if stream_handler.find().count() isnt 0
        return

      stream_handler.stopSubscription()
      
      cur_proj = -> APP.modules.project_page.curProj()

      if cur_proj().isCustomFeatureEnabled JustdoPlanningUtilities.project_custom_feature_id
        gc.setView JustDoProjectsTemplates.template_grid_views.gantt

        APP.justdo_planning_utilities.on "changes-queue-processed", ->
          if (first_task_id = APP.collections.Tasks.findOne({project_id}, {fields: {_id: 1}, sort: {seqId: 1}})?._id)
            task_info = APP.justdo_planning_utilities.task_id_to_info[first_task_id]
            {earliest_child_start_time, latest_child_end_time} = task_info
            if earliest_child_start_time? and latest_child_end_time?
              # Set the date range presented in the gantt
              APP.justdo_planning_utilities.setEpochRange [earliest_child_start_time, latest_child_end_time]

          return
      
      return
    transformTemplateItemToTaskDoc = (template_item) ->
      template_item.project_id = project_id
      delete template_item.parent
      delete template_item._id
      delete template_item.key
      delete template_item.sub_id
      return template_item
    recursiveBulkCreateTasks = (path, template_items_arr) ->
      # template_item_keys is to keep track of the corresponding template item id for each created task
      template_item_keys = _.map template_items_arr, (item) -> item.key

      items_to_add = _.map template_items_arr, (item) -> transformTemplateItemToTaskDoc item
      grid_data.bulkAddChild path, items_to_add, (err, created_task_ids) ->
        if err?
          JustdoSnackbar.show
            text: err.reason or err
          return

        for created_task_id_and_path, i in created_task_ids
          created_task_path = created_task_id_and_path[1]
          corresponding_template_item_key = template_item_keys[i]
          child_query =
            parent: corresponding_template_item_key
          if not _.isEmpty excluded_item_keys
            child_query.key =
              $nin: excluded_item_keys

          # Remove created tasks from AIResponse collection
          stream_handler.remove({key: corresponding_template_item_key})

          if _.isEmpty (child_template_items = stream_handler.find(child_query).fetch())
            postNewProjectTemplateCreationCallback created_task_path
          else
            recursiveBulkCreateTasks created_task_path, child_template_items
        
        return

      return
    
    query =
      parent: -1

    # In case the resnpose has only 1 root task, use the child tasks as root tasks.
    if stream_handler.find(query).count() is 1
      stream_handler.remove query
      query.parent = 0
    
    if not _.isEmpty(excluded_item_keys = $(".welcome-ai-result-item-checkbox:not(.checked)").map((i, el) -> $(el).data("key")).get())
      query.key =
        $nin: excluded_item_keys
    
    if _.isEmpty(template_items = stream_handler.find(query).fetch())
      return

    # Top level tasks' state should always be nil
    template_items = _.map template_items, (item) -> 
      item.state = "nil"
      return item
    recursiveBulkCreateTasks("/", template_items)

    tpl.bootbox_dialog.modal "hide"

    return

  "click .welcome-ai-stop-generation": (e, tpl) ->
    tpl.stream_handler_rv.get().stopStream()
    tpl.unlockInput()
    $(".welcome-ai-input").focus()
    return

Template.project_template_welcome_ai_task_item.onCreated ->
  @parentTemplateInstance = -> Blaze.getView("Template.project_template_welcome_ai").templateInstance()
  return

Template.project_template_welcome_ai_task_item.helpers
  childTemplate: ->
    tpl = Template.instance()
    parent_tpl = tpl.parentTemplateInstance()
    return parent_tpl.stream_handler_rv.get().find({parent: @key}).fetch()
