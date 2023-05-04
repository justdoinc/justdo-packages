_.extend JustdoNewProjectTemplates.prototype,
  _bothImmediateInit: ->
    @setupRouter()

    return

  _bothDeferredInit: ->
    if @destroyed
      return

    @registerNewProjectTemplates()

    return

  registerNewProjectTemplates: ->
    for template_id, template_def of JustdoNewProjectTemplates.new_project_templates
      try
        APP.justdo_projects_templates.registerCategory template_def.category
      catch e
        if e.error isnt "template-category-already-exist"
          throw @_error e

      options = _.extend {id: template_id}, template_def

      APP.justdo_projects_templates.registerTemplate options

    return
