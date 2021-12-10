tags_properties =
  "project":
    text: "Project"

    filter_list_order: 0

    customFilterQuery: (filter_state_id, column_state_definitions, context) ->
      return {"p:dp:is_project": true}

_.extend JustdoTaskType.prototype,
  _immediateInit: ->
    @installed_category_fields = {}
    @installed_category_fields_dep = new Tracker.Dependency()

    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    # @registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    return

  getCategoryFieldId: (category) ->
    return "task-type::#{category}"

  installCategoryField: (category, options) ->
    if category of @installed_category_fields
      return

    @installed_category_fields[category] = options
    @installed_category_fields_dep.changed()

    return

  uninstallCategoryField: (category) ->
    if category not of @installed_category_fields
      return

    APP.modules.project_page.removePseudoCustomFields @getCategoryFieldId(category)

    delete @installed_category_fields[category]
    @installed_category_fields_dep.changed()

    return

  getInstalledCategoryFields: ->
    @installed_category_fields_dep.depend()

    return @installed_category_fields

  _category_field_options_schema: new SimpleSchema
    label:
      type: "String"
  _setupCategoryColumnPseudoField: (category, options) ->
    Tracker.nonreactive =>
      required_fields_ids = _.keys(@getRequiredFields(category)) # <- This is a reactive resource

      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          @_category_field_options_schema,
          options or {},
          {self: @, throw_on_error: true}
        )
      options = cleaned_val

      APP.modules.project_page.setupPseudoCustomField @getCategoryFieldId(category),
        label: options.label
        field_type: "objects_array"
        grid_visible_column: true
        formatter: "tagsFormatter"
        grid_editable_column: false
        editor: null
        default_width: 200
        grid_dependencies_fields: required_fields_ids
        grid_column_formatter_options:
          valuesGenerator: (task_doc) =>
            # ENSURE REACTIVITY POST ADD/REMOVE of new types generator
            return @getTaskTypesByTaskObj(category, task_doc)

          propertiesGenerator: (tag) =>
            return @getTagProperties(category, tag)
        client_only: true

        filter_type: "whitelist"
        filter_options:
          filter_values: =>
            return @getCategoryFilterOptions(category)

      return

    return

  setupCustomFeatureMaintainer: ->
    if JustdoTaskType.plugin_integral_part_of_justdo
      feature_id = "INTEGRAL"
    else
      feature_id = JustdoTaskType.project_custom_feature_id

    @categories_fields_columns_maintainer_tracker = null

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage feature_id,
        installer: =>
          for category_def in JustdoTaskType.core_categories
            @installCategoryField category_def.category_id,
              label: category_def.label

          if @categories_fields_columns_maintainer_tracker?
            # This shouldn't happen, I put it here, just for case it does
            @categories_fields_columns_maintainer_tracker.stop()
            @categories_fields_columns_maintainer_tracker.null

          @categories_fields_columns_maintainer_tracker = Tracker.autorun =>
            installed_categories_fields = @getInstalledCategoryFields() # <- reactive resource

            installed_categories_columns_ids = _.map(_.keys(installed_categories_fields), (category_id) => @getCategoryFieldId(category_id))

            for category_id, category_field_option of installed_categories_fields
              required_fields_ids = _.keys(@getRequiredFields(category_id)) # <- This is a reactive resource

              @_setupCategoryColumnPseudoField(category_id, category_field_option)

            if (gcm = Tracker.nonreactive => APP.modules.project_page.grid_control_mux.get())?
              for tab_id, tab_def of gcm.getAllTabsNonReactive()
                if (gc = tab_def.grid_control)?
                  Tracker.nonreactive -> gc.invalidateColumns(installed_categories_columns_ids)

            return

          return

        destroyer: =>
          @categories_fields_columns_maintainer_tracker.stop()
          @categories_fields_columns_maintainer_tracker = null
          for category_def in JustdoTaskType.core_categories
            @uninstallCategoryField category_def.category_id,
              label: category_def.label

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
