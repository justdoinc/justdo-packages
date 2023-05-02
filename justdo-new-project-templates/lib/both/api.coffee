_.extend JustdoNewProjectTemplates.prototype,
  _bothImmediateInit: ->
    if Meteor.isServer
      @project_templates = {}

    @setupRouter()

    return

  _bothDeferredInit: ->
    if @destroyed
      return

    @registerDefaultNewProjectTemplates()

    return

  _registerNewProjectTemplateOptionsSchema: new SimpleSchema
    id:
      type: String
    name:
      type: String
    demo_img_src:
      type: String
    template:
      type: Object
      blackbox: true
    order:
      type: Number
      optional: true
  registerNewProjectTemplate: (options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerNewProjectTemplateOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if Meteor.isServer
      @project_templates[options.id] = options.template

    if Meteor.isClient
      JD.registerPlaceholderItem options.id,
        domain: "new-project-template"
        position: options.order
        data:
          name: options.name
          template: "new_project_template_demo"
          template_data:
            img_src: options.demo_img_src

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
