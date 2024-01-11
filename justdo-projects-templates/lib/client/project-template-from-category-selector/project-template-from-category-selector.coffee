Template.project_template_from_category_selector.onCreated ->
  tpl = @

  @rerenderForcer = JustdoHelpers.generateRerenderForcer()

  # Chat AI Wizard
  @user_message_rv = new ReactiveVar ""
  @show_bot_response_thinking = new ReactiveVar false
  @show_bot_response_message = new ReactiveVar false

  @categories_to_show = ["blank"]
  if _.isString(categories = @data?.categories)
    categories = [categories]
  if _.isArray categories
    @categories_to_show = categories

  @subtitle_i18n = @data?.subtitle_i18n or ""

  @active_template_id_rv = new ReactiveVar ""

  @sendMessage = ->
    user_message = tpl.user_message_rv.get()
    message = $(".ai-wizard-input").val().trim()

    if user_message == "" and message != ""
      tpl.user_message_rv.set message

      activeUser = Meteor.user()

      message_data = {
        name: "#{activeUser.profile.first_name} #{activeUser.profile.last_name}",
        email: activeUser.emails[0].address,
        message: message
      }

      # Send using Mail API
      options = 
        project_id: JD.activeJustdoId()
        msg: message
        set_project_title: true
      APP.justdo_projects_templates.createSubtreeFromAiGeneratedTemplate options, (err, res) ->
        if err?
          console.error err
          return
        bootbox.hideAll()
        $("#ai-template-wizard").modal "hide"
        return

      setTimeout ->
        tpl.show_bot_response_thinking.set true
      , 500

      setTimeout ->
        tpl.show_bot_response_message.set true

      , 2000

    $(".ai-wizard-input").val ""

    return

  return

Template.project_template_from_category_selector.onRendered ->
  tpl = @

  setTimeout ->
    $("#ai-template-wizard").modal "show"
  , 500

  $("#ai-template-wizard").on "shown.bs.modal", ->
    $(".ai-wizard-input").focus()

    return

  return

Template.project_template_from_category_selector.helpers
  rerenderTrigger: ->
    tpl = Template.instance()

    return tpl.rerenderForcer()

  subtitleI18n: -> TAPi18n.__ Template.instance().subtitle_i18n

  getTemplatesList: ->
    tpl = Template.instance()

    templates = APP.justdo_projects_templates.getTemplatesByCategories tpl.categories_to_show

    if (first_template = templates?[0])?
      tpl.active_template_id_rv.set first_template.id
    return templates

  isTemplateActive: ->
    if @id is Template.instance().active_template_id_rv.get()
      return "active"
    return

  activeTemplate: ->
    return APP.justdo_projects_templates.requireTemplateById Template.instance().active_template_id_rv.get()

  userMessage: ->
    return Template.instance().user_message_rv.get()

  showBotThinking: ->
    return Template.instance().show_bot_response_thinking.get()

  showBotMessage: ->
    return Template.instance().show_bot_response_message.get()

Template.project_template_from_category_selector.events
  "click .template-item": (e, tpl) ->
    tpl.active_template_id_rv.set $(e.target).closest(".template-item").data "id"
    Tracker.flush()
    return

  "click .ai-wizard-close": (e, tpl) ->
    $("#ai-template-wizard").modal "hide"

    return

  "click .ai-wizard-send": (e, tpl) ->
    tpl.sendMessage()

    return

  "keypress .ai-wizard-input": (e, tpl) ->
    if e.keyCode == 13
      tpl.sendMessage()

    return
