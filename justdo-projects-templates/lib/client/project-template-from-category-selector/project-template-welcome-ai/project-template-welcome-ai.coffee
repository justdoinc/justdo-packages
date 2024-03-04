Template.project_template_welcome_ai.onCreated ->
  @pub_id_rv = new ReactiveVar ""
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
    if _.isEmpty(pub_id = @pub_id_rv.get())
      return false
    return APP.collections.AIResponse.findOne({pub_id: pub_id, parent: -1}, {fields: {_id: 1}})?

  @showDropdown = -> $(".welcome-ai-dropdown").addClass "show"
  @hideDropdown = -> $(".welcome-ai-dropdown").removeClass "show"

  @autorun ->
    APP.collections.AIResponse.find().fetch()
    $(".welcome-ai-results-items").animate(scrollTop: $('.welcome-ai-results-items').prop("scrollHeight"), 100)

    return

  @removeAllItemsWithPubIdInMiniMongo = (pub_id) ->
    APP.collections.AIResponse._collection.remove({pub_id: pub_id})
    return

  @sendRequestToOpenAI = (request) ->
    tpl = @

    @sent_request = request
    @is_loading_rv.set true
    @lockInput()
    
    if (old_sub_id = tpl.pub_id_rv.get())?
      APP.justdo_ai_kit.stopAndDeleteSubHandle old_sub_id

    sub_id = Random.id()
    tpl.pub_id_rv.set sub_id
    options = 
      sub_id: sub_id
      req_template_id: "stream_project_template"
      req_options: 
        msg: request.msg
      cache_token: request.cache_token
      subOnReady: -> 
        tpl.is_loading_rv.set false
        tpl.unlockInput()
        return

    APP.justdo_ai_kit.createStreamRequestAndSubscribeToResponse options
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
    if _.isEmpty(pub_id = tpl.pub_id_rv.get())
      return

    if not _.isEmpty(root_tasks = APP.collections.AIResponse.find({pub_id: pub_id, parent: -1}).fetch())
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

    pub_id = tpl.pub_id_rv.get()
    project_id = JD.activeJustdoId()

    query =
      pub_id: pub_id
      parent: -1

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

          # Remove created tasks from AIResponse collection
          APP.collections.AIResponse._collection.remove({pub_id: pub_id, key: corresponding_template_item_key})

          if _.isEmpty (child_template_items = APP.collections.AIResponse.find(child_query).fetch())
            APP.justdo_ai_kit.postNewProjectTemplateCreationCallback pub_id
          else
            recursiveBulkCreateTasks created_task_path, child_template_items
        
        return

      return
    
    # In case the resnpose has only 1 root task, use the child tasks as root tasks.
    if APP.collections.AIResponse.find(query).count() is 1
      query.parent = 0
      APP.collections.AIResponse._collection.remove {pub_id: pub_id, key: 0}
    
    if not _.isEmpty(excluded_item_keys = $(".welcome-ai-result-item-checkbox:not(.checked)").map((i, el) -> $(el).data("key")).get())
      query.key =
        $nin: excluded_item_keys
    
    if _.isEmpty(template_items = APP.collections.AIResponse.find(query).fetch())
      return

    # Top level tasks' state should always be nil
    template_items = _.map template_items, (item) -> 
      item.state = "nil"
      return item
    recursiveBulkCreateTasks("/", template_items)

    tpl.bootbox_dialog.modal "hide"

    return

  "click .welcome-ai-stop-generation": (e, tpl) ->
    APP.justdo_ai_kit.stopStreamAndKillPublication tpl.pub_id_rv.get()
    tpl.unlockInput()
    $(".welcome-ai-input").focus()
    return

Template.project_template_welcome_ai_task_item.helpers
  childTemplate: ->
    return APP.collections.AIResponse.find({pub_id: @pub_id, parent: @key}).fetch()
