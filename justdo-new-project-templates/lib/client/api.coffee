_.extend JustdoNewProjectTemplates.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  showFirstJustDoTemplatePicker: ->
    options =
      popup_title: "Welcome"
      popup_subtitle: "Start by choosing a template that suit your needs"
      categories: ["getting-started", "blank"]
      allow_closing: false
      target_task: "/"
    APP.justdo_projects_templates.showTemplatesFromCategoriesPicker options
    return
