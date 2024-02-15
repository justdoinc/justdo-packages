APP.justdo_tooltips.registerTooltip
  id: "ai-wizard-tooltip"
  template: "ai_wizard_tooltip"

Template.ai_wizard_tooltip.onCreated ->
  tpl = @
  tpl.templates_sub_handle = null
  tpl.pub_id_rv = new ReactiveVar ""
  tpl.is_loading_rv = new ReactiveVar false

  tpl.isResponseExists = ->
    if _.isEmpty(pub_id = @pub_id_rv.get())
      return false
    return APP.collections.AIResponse.findOne({pub_id: pub_id, parent: -1}, {fields: {_id: 1}})?

  tpl.streamTemplateFromOpenAi = ->
    request = JD.activeItem({title: 1}).title
    tpl.is_loading_rv.set true

    Meteor.call "streamTemplateFromOpenAi", request, (err, pub_id) ->
      if err?
        JustdoSnackbar.show
          text: err.reason or err
        return

      tpl.pub_id_rv.set ""
      tpl.templates_sub_handle?.stop()

      tpl.pub_id_rv.set pub_id
      tpl.templates_sub_handle = Meteor.subscribe pub_id,
        onReady: -> tpl.showDropdown()
        onStop: ->
          tpl.is_loading_rv.set false
          return

      return
    return

  tpl.autorun ->
    APP.collections.AIResponse.find().fetch()
    $(".ai-wizard-list").animate(scrollTop: $(".ai-wizard-list").prop("scrollHeight"), 100)

  return

Template.ai_wizard_tooltip.onRendered ->
  tpl = @
  tpl.streamTemplateFromOpenAi()

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
    return

  "click .ai-wizard-stop": (e, tpl) ->
    APP.justdo_projects_templates.stopStreamTemplateFromOpenAi tpl.pub_id_rv.get()
    return

  "click .ai-wizard-create": (e, tpl) ->
    pub_id = tpl.pub_id_rv.get()
    project_id = JD.activeJustdoId()

    query =
      pub_id: pub_id
      parent: -1
    if not _.isEmpty(excluded_item_ids = $(".ai-wizard-item-checkbox:not(.checked)").map((i, el) -> $(el).data("id")).get())
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
      path = "/" + JD.activeItemId() + path

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

    if _.isEmpty(template_items = APP.collections.AIResponse.find(query).fetch())
      return

    recursiveBulkCreateTasks("/", template_items)

    $(".jd-tt-ai-wizard-tooltip-container").remove()

    return

Template.ai_wizard_item.helpers
  childTemplate: ->
    return APP.collections.AIResponse.find({pub_id: @pub_id, parent: @_id}).fetch()
