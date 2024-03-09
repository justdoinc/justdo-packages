Template.project_template_from_category_selector.onCreated ->
  tpl = @

  @rerenderForcer = JustdoHelpers.generateRerenderForcer()

  @categories_to_show = ["blank"]
  if _.isString(categories = @data?.categories)
    categories = [categories]
  if _.isArray categories
    @categories_to_show = categories

  @subtitle_i18n = @data?.subtitle_i18n or ""

  @active_template_id_rv = new ReactiveVar ""

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

Template.project_template_from_category_selector.events
  "click .template-item": (e, tpl) ->
    tpl.active_template_id_rv.set $(e.target).closest(".template-item").data "id"
    Tracker.flush()
    return
