Template.project_template_welcome_ai.onCreated ->
  @templates_sub_handle = null
  @pub_id_rv = new ReactiveVar ""
  @is_loading_rv = new ReactiveVar false

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
    @is_loading_rv.set true
    @lockInput()
    Meteor.call "streamTemplateFromOpenAi", request, (err, pub_id) =>
      if err?
        JustdoSnackbar.show
          text: err.reason or err
        return
      
      old_pub_id = Tracker.nonreactive => @pub_id_rv.get()
      if not _.isEmpty(old_pub_id)
        @removeAllItemsWithPubIdInMiniMongo old_pub_id

      @pub_id_rv.set ""
      @templates_sub_handle?.stop()

      @pub_id_rv.set pub_id
      @templates_sub_handle = Meteor.subscribe pub_id, 
        onReady: => @showDropdown()
        onStop: => 
          @is_loading_rv.set false
          @unlockInput()
          return

      return

  @removeAllItemsWithPubIdInMiniMongo = (pub_id) ->
    APP.collections.AIResponse._collection.remove({pub_id: pub_id})
    return

  @sendRequestToOpenAI = (request) ->
    @is_loading_rv.set true
    @lockInput()
    Meteor.call "streamTemplateFromOpenAi", request, (err, pub_id) =>
      if err?
        JustdoSnackbar.show
          text: err.reason or err
        return
      
      old_pub_id = Tracker.nonreactive => @pub_id_rv.get()
      if not _.isEmpty(old_pub_id)
        @removeAllItemsWithPubIdInMiniMongo old_pub_id

      @pub_id_rv.set ""
      @templates_sub_handle?.stop()

      @pub_id_rv.set pub_id
      @templates_sub_handle = Meteor.subscribe pub_id, 
        onReady: => @showDropdown()
        onStop: => 
          @is_loading_rv.set false
          @unlockInput()
          return

      return

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
      tpl.sendRequestToOpenAI template_id
    else
      $(".welcome-ai-btn-generate").click()

    return

  "click .welcome-ai-btn-generate": (e, tpl) ->
    request = $(".welcome-ai-input").val().trim()

    # If request is empty, use the first example prompt from the dropdown.
    if _.isEmpty request
      $($(".welcome-ai-suggestion-item").get(0)).click()
    else
      tpl.sendRequestToOpenAI request

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
    item_content = $(e.target).closest(".welcome-ai-result-item-content")
    checkbox = item_content.find(".welcome-ai-result-item-checkbox")
    check_state = null

    if checkbox.hasClass "checked"
      check_state = false
      checkbox.removeClass "checked"
    else
      check_state = true
      checkbox.addClass "checked"

    item_content.siblings().each (i, el) ->
      $(el).find(".welcome-ai-result-item-checkbox").each (i, el_checkbox) ->
        if check_state
          $(el_checkbox).addClass "checked"
        else
          $(el_checkbox).removeClass "checked"

        return
      return
    return

  "click .welcome-ai-create-btn": (e, tpl) ->
    pub_id = tpl.pub_id_rv.get()
    project_id = JD.activeJustdoId()

    query =
      pub_id: pub_id
      parent: -1
    if not _.isEmpty(excluded_item_ids = $(".welcome-ai-result-item-checkbox:not(.checked)").map((i, el) -> $(el).data("id")).get())
      query._id =
        $nin: excluded_item_ids

    grid_data = APP.modules.project_page.gridData()
    transformTemplateItemToTaskDoc = (template_item) ->
      template_item.project_id = project_id
      delete template_item._id
      delete template_item.pub_id
      return template_item
    recursiveBulkCreateTasks = (path, template_items_arr) ->
      # template_item_ids is to keep track of the corresponding template item id for each created task
      template_item_ids = _.map template_items_arr, (item) -> item._id

      items_to_add = _.map template_items_arr, (item) -> transformTemplateItemToTaskDoc item
      grid_data.bulkAddChild path, items_to_add, (err, created_task_ids) ->
        if err?
          JustdoSnackbar.show
            text: err.reason or err
          return

        for created_task_id_and_path, i in created_task_ids
          created_task_path = created_task_id_and_path[1]
          corresponding_template_item_id = template_item_ids[i]
          child_query =
            pub_id: pub_id
            parent: corresponding_template_item_id
          if not _.isEmpty excluded_item_ids
            child_query._id =
              $nin: excluded_item_ids

          template_items = APP.collections.AIResponse.find(child_query).fetch()
          recursiveBulkCreateTasks created_task_path, template_items

      return
    
    # In case the resnpose has only 1 root task, use the child tasks as root tasks.
    if APP.collections.AIResponse.find(query).count() is 1
      query.parent = 0
    
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
    APP.justdo_projects_templates.stopStreamTemplateFromOpenAi tpl.pub_id_rv.get()
    tpl.unlockInput()
    $(".welcome-ai-input").focus()
    return

Template.project_template_welcome_ai_task_item.helpers
  childTemplate: ->
    return APP.collections.AIResponse.find({pub_id: @pub_id, parent: @_id}).fetch()
