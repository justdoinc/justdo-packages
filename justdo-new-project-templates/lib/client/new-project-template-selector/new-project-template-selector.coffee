Template.new_project_template_selector.onCreated ->
  @active_template_rv = new ReactiveVar "new-project-default-template"
  JD.registerPlaceholderItem "new-project-default-template",
    domain: "new-project-template"
    position: 0
    data:
      name: "Empty"
      template: "new_project_template_demo"
      template_data:
        img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/empty.jpg"
  JD.registerPlaceholderItem "new-project-dev-template",
    domain: "new-project-template"
    position: 1
    data:
      name: "Dev"
      template: "new_project_template_demo"
      template_data:
        img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/empty.jpg"
  JD.registerPlaceholderItem "new-project-sales-template",
    domain: "new-project-template"
    position: 2
    data:
      name: "Sales"
      template: "new_project_template_demo"
      template_data:
        img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/sales.png"
  JD.registerPlaceholderItem "new-project-wiki-template",
    domain: "new-project-template"
    position: 3
    data:
      name: "Wiki"
      template: "new_project_template_demo"
      template_data:
        img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/empty.jpg"
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
