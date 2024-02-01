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

  getTemplateById: (template_id) ->
    return @templates[template_id]

  requireTemplateById: (template_id) ->
    if not (template = @getTemplateById template_id)?
      throw @_error "template-not-found", "Template #{template_id} not found"
    return template

  _registerCategoryDefSchema: new SimpleSchema
    id:
      type: String
    label_i18n:
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
    postCreationCallback:
      type: Function
      optional: true
    label_i18n:
      type: String
    demo_img_src:
      type: String
      optional: true
    demo_html_template:
      type: [Object]
      blackbox: true
      optional: true
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

    # Omit the tree structure on the client side as it's not used.
    if Meteor.isClient
      options = _.omit options, "template"

    @templates[options.id] = options

    return

  getTemplatesByCategories: (categories) ->
    # Order of templates is: templates that lists categories[0] before any other category in
    # the provided categories array, ordered by order - and so on.
    @requireCategoriesExists categories

    templates = _.filter @templates, (template_def) ->
      for template_category in template_def.categories
        if template_category in categories
          return true
      return false

    templates = _.sortBy(_.sortBy(templates, (template) -> template.order), (template) -> _.indexOf(categories, template.categories[0]))

    return templates

  parseOpenAiTemplateToTasksTemplate: (tasks_arr) ->
    check tasks_arr, Array

    length = tasks_arr.length
    if (length isnt 7) and (length isnt 8)
      throw @_error "invalid-argument", "Invalid template"

    states = ["pending", "in-progress", "done", "will-not-do", "on-hold", "duplicate", "nil"]
    templateParser = (template_arr) ->
      task_template_obj = {}

      [
        title
        start_date_offset
        end_date_offset
        due_date_offset
        state_idx
        key
        subtasks
      ] = template_arr

      task_template_obj =
        title: title
        start_date: if _.isNumber(start_date_offset) then moment().add(start_date_offset, 'days').format("YYYY-MM-DD") else null
        end_date: if _.isNumber(end_date_offset) then moment().add(end_date_offset, 'days').format("YYYY-MM-DD") else null
        due_date: if _.isNumber(due_date_offset) then moment().add(due_date_offset, 'days').format("YYYY-MM-DD") else null
        state: if (state_idx >= 0) then states[state_idx] else "nil"
        key: key
      
      if subtasks?
        task_template_obj.tasks = []
        for subtask_template_arr in subtasks
          task_template_obj.tasks.push(templateParser(subtask_template_arr, {}))
      
      return task_template_obj
    
    return templateParser tasks_arr
  