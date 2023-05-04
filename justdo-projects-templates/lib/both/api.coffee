_.extend JustDoProjectsTemplates.prototype,
  _bothImmediateInit: ->
    @categories = {}
    @project_templates = {}

    return

  _bothDeferredInit: ->
    if @destroyed
      return

    return

  _registerCategoryDefSchema: new SimpleSchema
    id:
      type: String
    label:
      type: String
    order:
      type: Number
      optional: true
  registerCategory: (category_def) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerCategoryDefSchema,
        category_def,
        {self: @, throw_on_error: true}
      )
    category_def = cleaned_val

    if _.has @categories, category_def.id
      throw @_error "template-category-already-exist"

    @categories[category_def.id] = category_def

    return

  _registerTemplateOptionsSchema: new SimpleSchema
    id:
      type: String
    categories:
      type: [String]
    label:
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

    for category in options.categories
      if not _.has @categories, category
        throw @_error "template-category-not-found", "Template category #{category} not found"

    @project_templates[options.id] = options.template

    return