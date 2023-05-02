Template.new_project_template_selector.onCreated ->
  @active_template_rv = new ReactiveVar "new-project-default-template"
  return

Template.new_project_template_selector.helpers
  getTemplatesList: -> JD.getPlaceholderItems "new-project-template"

  isTemplateActive: ->
    if @id is Template.instance().active_template_rv.get()
      return "active"
    return

  activeTemplate: -> _.find JD.getPlaceholderItems("new-project-template"), (item) -> item.id is Template.instance().active_template_rv.get()

Template.new_project_template_selector.events
  "click .template-item": (e, tpl) ->
    tpl.active_template_rv.set $(e.target).closest(".template-item").data "id"
    return
