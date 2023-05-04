_.extend JustdoNewProjectTemplates.prototype,
  _bothImmediateInit: ->
    @setupRouter()

    return

  _bothDeferredInit: ->
    if @destroyed
      return

    @registerDefaultNewProjectTemplates()

    return



  registerDefaultNewProjectTemplates: ->
    for name, template_def of JustdoNewProjectTemplates.default_project_templates
      @registerNewProjectTemplate
        id: "new-project-#{name}-template"
        name: name
        demo_img_src: template_def.demo_img_src
        template: template_def.template
        order: template_def.order

    return
