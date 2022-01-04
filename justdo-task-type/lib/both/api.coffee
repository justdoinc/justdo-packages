_.extend JustdoTaskType.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @types_generators = {}
    @_merged_required_fields_cache = {} # Cache to avoid the need to recalculate each time
    @types_generators_and_merged_required_fields_cache_dep = new Tracker.Dependency()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoTaskType.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoTaskType.project_custom_feature_id})

  _getTypesGenerators: (category) ->
    if not category?
      category = "default"

    @types_generators_and_merged_required_fields_cache_dep.depend()

    return @types_generators[category] or {}

  getTypesGenerators: (category) ->
    # Note on the client this is a reactive resource

    return _.extend {}, @_getTypesGenerators(category)

  _getRequiredFields: (category) ->
    if not category?
      category = "default"

    @types_generators_and_merged_required_fields_cache_dep.depend()

    return @_merged_required_fields_cache[category] or {}

  getRequiredFields: (category) ->
    # Note on the client this is a reactive resource
    return _.extend {}, @_getRequiredFields(category)

  recalculateRequiredFieldsCache: ->
    @_merged_required_fields_cache = {}
    for category of @types_generators
      required_fields_objs = _.map @types_generators[category], (type_generator) -> 
        return type_generator.required_task_fields_to_determine

      required_fields_objs.unshift({})

      @_merged_required_fields_cache[category] = _.extend.apply(_, required_fields_objs)

    @types_generators_and_merged_required_fields_cache_dep.changed()

    return

  _task_type_def_schema: new SimpleSchema
    category:
      type: String

      defaultValue: "default"

    id:
      type: String

    required_task_fields_to_determine:
      type: Object

      blackbox: true

    generator:
      type: Function

    propertiesGenerator:
      type: Function

    possible_tags:
      type: [String]

    conditional_tags:
      type: [String]
      optional: true

  registerTaskTypesGenerator: (category, id, def) ->
    def = _.extend {}, def, {id, category}

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_task_type_def_schema,
        def or {},
        {self: @, throw_on_error: true}
      )
    def = cleaned_val

    if def.id of @types_generators
      throw @_error "type-generator-id-already-exist"

    Meteor._ensure(@types_generators, def.category)

    @types_generators[def.category][def.id] = def
    @recalculateRequiredFieldsCache()
    @types_generators_and_merged_required_fields_cache_dep.changed()

    return

  unregisterTaskTypesGenerator: (category, id) ->
    if id not of @types_generators[category]
      # Nothing to do
      return

    delete @types_generators[category][id]
    @recalculateRequiredFieldsCache()
    @types_generators_and_merged_required_fields_cache_dep.changed()

    return

  getTaskTypesByTaskId: (category, task_id) ->
    # Note, on the Client this is a reactive resource
    
    return @getTaskTypesByTaskObj(category, @tasks_collection.findOne(task_id, {fields: @_getRequiredFields(category)}))

  getTaskTypesByTaskObj: (category, task_obj) ->
    # Note, on the Client this is a reactive resource

    # IMPORTANT If you are using this one, it is up to you to ensure required fields requirements are met
    # call @getRequiredFields to find who they are.

    if not category?
      category = "default"

    types_generators = @_getTypesGenerators(category)

    task_types = []

    for type_generator_id, type_generator of types_generators
      generated_types = type_generator.generator(task_obj)

      if _.isArray(generated_types)
        for generated_type in generated_types
          task_types.push(generated_type)

    return task_types

  getTagProperties: (category, tag) ->
    # Note, on the Client this is a reactive resource

    if not category?
      category = "default"

    types_generators = @_getTypesGenerators(category)

    for type_generator_id, type_generator of types_generators
      if (properties = type_generator.propertiesGenerator(tag))?
        return properties

    return {}

  getCategoryFilterOptions: (category) ->
    if not category?
      category = "default"

    types_generators = @_getTypesGenerators(category)

    filter_options = {}

    for type_generator_id, type_generator of types_generators
      possible_tags = type_generator.possible_tags

      if (conditional_tags = type_generator.conditional_tags)?
        tags_to_ignore = new Set()

        for conditional_tag in conditional_tags
          current_project_has_conditional_tag_query = _.extend {project_id: JD.activeJustdoId()}, type_generator.required_task_fields_to_determine

          if @tasks_collection.find(current_project_has_conditional_tag_query).count() is 0
            tags_to_ignore.add conditional_tag

        possible_tags = _.filter possible_tags, (tag) -> return not tags_to_ignore.has tag

      for tag in possible_tags
        if not (tag_properties = type_generator.propertiesGenerator(tag))?
          throw @_error "unknown-tag", "An unknown tag '#{tag}' listed as a possible_tags for type generator id: #{type_generator_id} under the category: #{category}"

        filter_options[tag] =
          txt: tag_properties.text
          order: tag_properties.filter_list_order or 0
          customFilterQuery: tag_properties.customFilterQuery

    return filter_options
