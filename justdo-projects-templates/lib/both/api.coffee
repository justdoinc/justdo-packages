_.extend JustDoProjectsTemplates.prototype,
  _bothImmediateInit: ->
    @categories = {}
    @templates = {}

    return

  _bothDeferredInit: ->
    if @destroyed
      return

    return

  requireCategoriesExists: (category_ids) ->
    if _.isString category_ids
      category_ids = [category_ids]

    for category_id in category_ids
      if not _.has @categories, category_id
        throw @_error "template-category-not-found", "Template category #{category_id} not found"

    return true

  requireTemplateExists: (template_id) ->
    if not _.has @templates, template_id
      throw @_error "template-not-found", "Template #{template_id} not found"
    return true

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

    @requireCategoriesExists options.categories

    @templates[options.id] = options

    return

  getAllRegisteredTemplates: ->
    return _.sortBy @templates, (template) -> template.order

  getTemplatesByCategories: (categories) ->
    @requireCategoriesExists categories

    templates = _.filter @templates, (template_def) ->
      for template_category in template_def.categories
        if template_category in categories
          return true
      return false
    templates = _.sortBy templates, (template) -> template.order

    return templates

  getTemplateById: (template_id) ->
    @requireTemplateExists template_id

    return @templates[template_id]
