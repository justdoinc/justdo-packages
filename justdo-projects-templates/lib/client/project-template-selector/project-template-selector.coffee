Template.project_template_selector.onCreated ->
  @categories_to_show = ["blank"]
  if _.isString(categories = @data?.categories)
    categories = [categories]
  if _.isArray categories
    @categories_to_show = categories

  @subtitle = @data?.subtitle or ""

  @active_category_id_rv = new ReactiveVar ""
  @active_template_id_rv = new ReactiveVar ""
  return

Template.project_template_selector.helpers
  subtitle: -> Template.instance().subtitle

  getTemplatesList: ->
    tpl = Template.instance()

    templates = JD.getPlaceholderItems "project-templates"
    if _.isArray tpl.categories_to_show
      templates = _.filter templates, (template) -> template.category in tpl.categories_to_show

    if (first_template = templates?[0])?
      tpl.active_category_id_rv.set first_template.category
      tpl.active_template_id_rv.set first_template.id
    return templates

  isTemplateActive: ->
    if @id is Template.instance().active_template_id_rv.get()
      return "active"
    return

  activeTemplate: -> _.find JD.getPlaceholderItems("project-templates"), (item) -> item.id is Template.instance().active_template_id_rv.get()

Template.project_template_selector.events
  "click .template-item": (e, tpl) ->
    tpl.active_category_id_rv.set $(e.target).closest(".template-item").data "category"
    tpl.active_template_id_rv.set $(e.target).closest(".template-item").data "id"
    return
