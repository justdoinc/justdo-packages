_.extend JustDoProjectsTemplates.prototype,
  _bothImmediateInit: ->
    @project_templates = {}

    return

  _registerTemplateOptionsSchema: new SimpleSchema
    category:
      type: String
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
  registerTemplate: (options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerTemplateOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if not _.has @project_templates, options.category
      throw @_error "template-category-not-found"

    if Meteor.isServer
      @project_templates[options.category][options.id] = options.template

    if Meteor.isClient
      JD.registerPlaceholderItem options.id,
        domain: "project-templates"
        position: options.order
        data:
          category: options.category
          name: options.name
          template: "project_template_demo"
          template_data:
            img_src: options.demo_img_src

    return
