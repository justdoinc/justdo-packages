# Note, in order to use the custom fields feature it must be enabled first, refer to the README.md

GridControlCustomFields = {}

_.extend GridControlCustomFields,
  #
  # Custom fields querying / management
  #
  custom_field_definition_schema: new SimpleSchema
    custom_field_type_id:
      type: String

      optional: true

    label:
      type: String

      min: 1
      max: 30

    field_id:
      type: String

      # regEx: /^[a-z0-9][a-z0-9_]*$/i

      min: 1
      max: 100

    field_type:
      type: String

      # Update getJsTypeForFieldType() if you change the list of allowed values
      allowedValues: ["string", "strings_array", "number", "numbers_array", "date", "boolean", "select", "calc", "objects_array"]

    field_options:
      type: Object

      optional: true

      blackbox: true

    filter_type:
      # Ignored for field_type "date" (forced to: "unicode-dates-filter"), "select"
      # (forced to: "whitelist")
      type: String

      optional: true

    filter_options:
      # Will be taken into account only if filter_type is set, or if field_type is "date" (in which case
      # should be considered as if field_type got defaulted to: "unicode-dates-filter")
      type: Object

      optional: true

      blackbox: true

    grid_ranges:
      # Translates to grid_ranges
      type: [Object]

      blackbox: true

      optional: true

    grid_visible_column:
      type: Boolean

      defaultValue: true

      optional: true

    grid_more_info_visible_column:
      type: Boolean

      defaultValue: true

      optional: true

    grid_printable_column:
      type: Boolean

      defaultValue: true

      optional: true

    grid_editable_column:
      type: Boolean

      defaultValue: true

      optional: true

    user_editable_column:
      type: Boolean

      defaultValue: true

      optional: true

    grid_default_grid_view:
      type: Boolean

      defaultValue: false

      optional: true

    grid_default_grid_view_position:
      type: Number

      defaultValue: null

      optional: true

    formatter:
      type: String

      optional: true

    editor:
      type: String

      optional: true

    decimal:
      type: Boolean

      optional: true

    min:
      type: Number

      optional: true

    max:
      type: Number

      optional: true

    custom_clipboard_import_label:
      type: String

      optional: true    

    default_width:
      type: Number

      optional: true

    default_frozen_column:
      type: Boolean

      optional: true

    grid_column_custom_value_generator:
      type: Function

      blackbox: true

      optional: true

    grid_column_custom_storage_mechanism:
      type: Function

      blackbox: true

      optional: true

    grid_column_manual_and_auto_values_getter:
      type: Function

      blackbox: true

      optional: true

    grid_column_substitue_field:
      type: String

      defaultValue: null

      optional: true

    grid_column_formatter_options:
      type: Object

      blackbox: true

      optional: true

    grid_column_editor_options:
      type: Object

      blackbox: true

      optional: true

    grid_dependencies_fields:
      type: [String]

      optional: true

    grid_dependent_fields:
      type: [String]

      optional: true

    client_only:
      type: Boolean

      optional: true

    disabled:
      type: Boolean

      optional: true
    
    blackbox:
      type: Boolean

      optional: true

  getJsTypeForFieldType: (field_type) ->
    if field_type == "string"
      return String
    if field_type == "strings_array"
      return [String]
    else if field_type == "number"
      return Number
    else if field_type == "numbers_array"
      return [Number]
    else if field_type == "date"
      return String # XXX Yeah... they are strings ...
    else if field_type == "calc"
      return String
    else if field_type == "boolean"
      return Boolean
    else if field_type == "select"
      return String
    else if field_type == "objects_array"
      return [Object]
    else
      # We should never get here since custom_field_definition_schema won't pass validation if
      # field_type isn't one of the above

      console.warn "Uknown field_type #{field_type} provided to getJsTypeForFieldType"

      return String

  getFieldTypeForJSType: (js_type) ->
    if js_type == String
      return "string" # Note that "date", "calc" and "select" are also String
    if _.isArray(js_type) and js_type[0] == String
      return "strings_array"
    else if js_type == Number
      return "number"
    else if _.isArray(js_type) and js_type[0] == Number
      return "numbers_array"
    else if js_type == Boolean
      return "boolean"
    else if _.isArray(js_type) and js_type[0] == Object
      return "objects_array"
    else
      # We should never get here since custom_field_definition_schema won't pass validation if
      # js_type isn't one of the above

      console.warn "Uknown js_type #{js_type} provided to getFieldTypeForJSType"

      return String

  getCleanCustomFieldsDefinitionAndDerivedSchema: (custom_fields_definitions) ->
    error = (type, message) ->
      message = "[grid-custom-fields] #{message}"
      console.error message

      return new Meteor.Error type, message

    clean_custom_fields_definition = {}
    for custom_field_id, custom_field_definition of custom_fields_definitions
      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          GridControlCustomFields.custom_field_definition_schema,
          custom_field_definition,
          {self: @, throw_on_error: true}
        )
      clean_custom_fields_definition[custom_field_id] = cleaned_val

    custom_fields_definitions = clean_custom_fields_definition

    custom_fields_schema = {}
    for custom_field_id, custom_field_definition of custom_fields_definitions
      custom_field_schema =
        label: custom_field_definition.label
        grid_visible_column: custom_field_definition.grid_visible_column
        grid_editable_column: custom_field_definition.grid_editable_column
        user_editable_column: custom_field_definition.user_editable_column
        grid_default_grid_view: custom_field_definition.grid_default_grid_view
        type: GridControlCustomFields.getJsTypeForFieldType(custom_field_definition.field_type)
        optional: true # all custom fields aren't required
        custom_field: true
      
      if custom_field_definition.blackbox == true
        custom_field_schema.blackbox = true

      if (grid_default_grid_view_position = custom_field_definition.grid_default_grid_view_position)?
        custom_field_schema.grid_default_grid_view_position = grid_default_grid_view_position

      if (grid_more_info_visible_column = custom_field_definition.grid_more_info_visible_column)?
        custom_field_schema.grid_more_info_visible_column = grid_more_info_visible_column

      if (grid_printable_column = custom_field_definition.grid_printable_column)?
        custom_field_schema.grid_printable_column = grid_printable_column

      if (grid_column_formatter_options = custom_field_definition.grid_column_formatter_options)?
        custom_field_schema.grid_column_formatter_options = grid_column_formatter_options

      if (grid_column_editor_options = custom_field_definition.grid_column_editor_options)?
        custom_field_schema.grid_column_editor_options = grid_column_editor_options

      if (grid_dependencies_fields = custom_field_definition.grid_dependencies_fields)?
        custom_field_schema.grid_dependencies_fields = grid_dependencies_fields

      if (grid_dependent_fields = custom_field_definition.grid_dependent_fields)?
        custom_field_schema.grid_dependent_fields = grid_dependent_fields

      if (client_only = custom_field_definition.client_only)?
        custom_field_schema.client_only = client_only

      if (default_width = custom_field_definition.default_width)?
        custom_field_schema.grid_default_width = default_width

      if (default_frozen_column = custom_field_definition.default_frozen_column)?
        custom_field_schema.grid_default_frozen_column = default_frozen_column

      if (grid_column_custom_value_generator = custom_field_definition.grid_column_custom_value_generator)?
        custom_field_schema.grid_column_custom_value_generator = grid_column_custom_value_generator

      if (grid_column_custom_storage_mechanism = custom_field_definition.grid_column_custom_storage_mechanism)?
        custom_field_schema.grid_column_custom_storage_mechanism = grid_column_custom_storage_mechanism

      if (grid_column_manual_and_auto_values_getter = custom_field_definition.grid_column_manual_and_auto_values_getter)?
        custom_field_schema.grid_column_manual_and_auto_values_getter = grid_column_manual_and_auto_values_getter

      if (grid_column_substitue_field = custom_field_definition.grid_column_substitue_field)?
        custom_field_schema.grid_column_substitue_field = grid_column_substitue_field

      if (decimal = custom_field_definition.decimal)?
        custom_field_schema.decimal = decimal

      if (min = custom_field_definition.min)?
        custom_field_schema.min = min

      if (max = custom_field_definition.max)?
        custom_field_schema.max = max

      if (custom_clipboard_import_label = custom_field_definition.custom_clipboard_import_label)?
        custom_field_schema.custom_clipboard_import_label = custom_clipboard_import_label

      if (disabled = custom_field_definition.disabled)?
        custom_field_schema.disabled = disabled

      if (grid_ranges = custom_field_definition.grid_ranges)?
        custom_field_schema.grid_ranges = grid_ranges

      if Meteor.isClient
        # The following is relevant only when running on the client, on the server we won't
        # even have GridControl defined

        default_formatter_and_editor = GridControl.getDefaultFormatterAndEditorForType(custom_field_definition.field_type)

        if not custom_field_schema.grid_visible_column
          custom_field_schema.grid_column_formatter = null
          formatter_type = null
        else
          if not (formatter_type = custom_field_definition.formatter)?
            if custom_field_definition.field_type == "select"
              formatter_type = "keyValueFormatter"
            else if custom_field_definition.field_type == "date"
              formatter_type = "unicodeDateFormatter"
            else if custom_field_definition.field_type == "strings_array"
              formatter_type = "arrayDefaultFieldFormatter"
            else if custom_field_definition.field_type == "numbers_array"
              formatter_type = "arrayDefaultFieldFormatter"
            else if custom_field_definition.field_type == "calc"
              formatter_type = "calculatedFieldFormatter"
            else
              formatter_type = default_formatter_and_editor.formatter

          if formatter_type not of GridControl.Formatters
            console.warn "unknown-grid-formatter", "Unknown grid formatter #{formatter_type}, using instead the default formatter for type #{custom_field_definition.field_type}: #{default_formatter_and_editor.formatter}"

            formatter_type = default_formatter_and_editor.formatter

        if not custom_field_schema.grid_editable_column
          editor_type = null
        else
          if not (editor_type = custom_field_definition.editor)?
            if custom_field_definition.field_type == "select"
              editor_type = "SelectorEditor"
            else if custom_field_definition.field_type == "date"
              editor_type = "UnicodeDateEditor"
            else if custom_field_definition.field_type == "strings_array"
              editor_type = "ArrayCSVEditor"
            else if custom_field_definition.field_type == "numbers_array"
              editor_type = "ArrayCSVEditor"
            else if custom_field_definition.field_type == "calc"
              editor_type = "CalculatedFieldEditor"
            else
              editor_type = default_formatter_and_editor.editor

          if editor_type not of GridControl.Editors
            console.warn "unknown-grid-formatter", "Unknown grid editor #{editor_type}, using instead the default editor for type #{custom_field_definition.field_type}: #{default_formatter_and_editor.editor}"

            editor_type = default_formatter_and_editor.editor

        custom_field_schema.grid_column_formatter = formatter_type
        custom_field_schema.grid_column_editor = editor_type

        if custom_field_definition.field_type == "select"
          grid_values = {}

          order = -1
          if (select_options = custom_field_definition.field_options?.select_options)?
            for option in select_options
              grid_values[option.option_id] =
                txt: option.label
                order: order += 1
                bg_color: option.bg_color

          grid_values[""] =
            txt: ""
            html: "<div class='null-state'></div>"
            skip_xss_guard: true
            order: order += 1

          custom_field_schema.grid_values = grid_values

          grid_removed_values = {}
          if (removed_select_options = custom_field_definition.field_options?.removed_select_options)?
            for option in removed_select_options
              grid_removed_values[option.option_id] =
                txt: option.label
          custom_field_schema.grid_removed_values = grid_removed_values

          custom_field_schema.grid_column_filter_settings = {type: "whitelist"}

          # END IF field_type "select"

        else if custom_field_definition.field_type == "date"
          custom_field_schema.grid_column_filter_settings =
            type: "unicode-dates-filter"

          if (filter_options = custom_field_definition.filter_options)?
            custom_field_schema.grid_column_filter_settings.options =
              custom_field_definition.filter_options
          else
            custom_field_schema.grid_column_filter_settings.options =
              filter_options: [
                {
                  type: "relative-range",
                  id: "today",
                  label: "Today",
                  relative_range: [0, 0]
                }

                # Future
                {
                  type: "relative-range",
                  id: "tomrrow",
                  label: "Tomorrow",
                  relative_range: [1, 1]
                }

                {
                  type: "relative-range",
                  id: "yesterday",
                  label: "Yesterday",
                  relative_range: [-1, -1]
                }

                {
                  type: "relative-range",
                  id: "next-7-days",
                  label: "Next 7 days",
                  relative_range: [1, 7]
                }

                {
                  type: "relative-range",
                  id: "last-7-days",
                  label: "Last 7 days",
                  relative_range: [-7, -1]
                }

                {
                  type: "relative-range",
                  id: "next-30-days",
                  label: "Next 30 days",
                  relative_range: [1, 30]
                }

                {
                  type: "relative-range",
                  id: "last-30-days",
                  label: "Last 30 days",
                  relative_range: [-30, -1]
                }

                {
                  type: "relative-range",
                  id: "all-future",
                  label: "All future",
                  relative_range: [1, null]
                }

                {
                  type: "relative-range",
                  id: "all-past",
                  label: "All past",
                  relative_range: [null, -1]
                }
                {
                  type: "custom-range"
                }
              ]

          # END IF field_type "date"

        else
          if (filter_type = custom_field_definition.filter_type)?
            custom_field_schema.grid_column_filter_settings =
              type: filter_type

          if (filter_options = custom_field_definition.filter_options)?
            custom_field_schema.grid_column_filter_settings.options = custom_field_definition.filter_options

      custom_fields_schema[custom_field_id] = custom_field_schema

    return {custom_fields_definitions, custom_fields_schema}

  _customFieldsArrayDefinitionToObjectDefinition: (custom_fields_array) ->
    if not custom_fields_array?
      custom_fields_array = []

    custom_fields_definitions_object = {}
    for custom_field in custom_fields_array
      custom_fields_definitions_object[custom_field.field_id] = custom_field

    return custom_fields_definitions_object

  getProjectCustomFieldsDefinitions: (justdo_projects, project_id) ->
    projects_collection = justdo_projects.projects_collection

    project_doc = projects_collection.findOne(project_id, {fields: {custom_fields: 1}})

    return @_customFieldsArrayDefinitionToObjectDefinition(project_doc?.custom_fields)

  getProjectCleanCustomFieldsDefinitionAndDerivedSchema: (justdo_projects, project_id) ->
    return @getCleanCustomFieldsDefinitionAndDerivedSchema(@getProjectCustomFieldsDefinitions(justdo_projects, project_id))

  getProjectRemovedCustomFieldsDefinitions: (justdo_projects, project_id) ->
    projects_collection = justdo_projects.projects_collection

    project_doc = projects_collection.findOne(project_id, {fields: {removed_custom_fields: 1}})

    return @_customFieldsArrayDefinitionToObjectDefinition(project_doc?.removed_custom_fields)

  getProjectCleanRemovedCustomFieldsDefinitionAndDerivedSchema: (justdo_projects, project_id) ->
    return @getCleanCustomFieldsDefinitionAndDerivedSchema(@getProjectRemovedCustomFieldsDefinitions(justdo_projects, project_id))

  enableJustdoCustomFieldsForJustdoProject: (justdo_projects) ->
    collection = justdo_projects.items_collection

    collection.allowSchemaCustomFields()

    # Add collection hooks to validate the custom fields
    #
    # if Meteor.isServer
    #   collection.before.insert (userId, doc) ->
    #     # Need to take care of removing fields that are not part of the core schema
    #     # and aren't part of the custom fields.

    #     {custom_fields_schema} =
    #       GridControlCustomFields.getProjectCleanCustomFieldsDefinitionAndDerivedSchema(justdo_projects, doc.project_id)

    #     doc_fields = _.keys doc
    #     custom_fields = _.keys custom_fields_schema

    #     custom_fields_names_in_doc = _.intersection doc_fields, custom_fields

    #     custom_fields_in_doc = _.pick.apply _, doc, custom_fields_names_in_doc

    #     custom_fields_simple_schema = new SimpleSchema custom_fields_schema
    #     JustdoHelpers.simpleSchemaCleanAndValidate(
    #       custom_fields_simple_schema,
    #       custom_fields_in_doc,
    #       {throw_on_error: true}
    #     )

    #     return true

    #   collection.before.update (userId, doc, fieldNames, modifier, options) ->
    #     console.log userId, doc, fieldNames, modifier, options

    #     return false

    return

  _available_field_types: [
    {
      custom_field_type_id: "basic-string"
      type_id: "string"
      label: "Text"
    }
    {
      custom_field_type_id: "basic-number-decimal"
      type_id: "number"
      label: "Number"
      custom_field_options:
        decimal: true
    }
    {
      custom_field_type_id: "basic-date"
      type_id: "date"
      label: "Date"
    }
    {
      custom_field_type_id: "basic-select"
      type_id: "select"
      label: "Options"
      settings_button_template: "custom_field_conf_select_options_editor_opener"
    }
  ]

  _available_field_types_dep: new Tracker.Dependency()

  getAvailableCustomFieldsTypes: ->
    @_available_field_types_dep.depend()

    return @_available_field_types

  findCustomFieldTypeDefinitionByCustomFieldTypeId: (custom_field_type_id) ->
    return _.find @getAvailableCustomFieldsTypes(), (_field_type_def) ->
      return _field_type_def.custom_field_type_id == custom_field_type_id


  registerCustomFieldsTypes: (custom_field_type_id, definition) ->
    if @findCustomFieldTypeDefinitionByCustomFieldTypeId(custom_field_type_id)?
      throw new Meteor.Error("custom-field-type-id-already-defined", "Custom field of type: #{custom_field_type_id} is already defined")
    
    @_available_field_types.push _.extend {},
      custom_field_type_id: custom_field_type_id
    , definition

    @_available_field_types_dep.changed()

    return

  unregisterCustomFieldsTypes: (custom_field_type_id) ->
    if not @findCustomFieldTypeDefinitionByCustomFieldTypeId(custom_field_type_id)?
      throw new Meteor.Error("custom-field-type-id-isnt-defined", "Custom field of type: #{custom_field_type_id} is not defined")

    @_available_field_types = _.filter @_available_field_types, (field_def) ->
      return field_def.custom_field_type_id != custom_field_type_id

    @_available_field_types_dep.changed()

    return


GridControlCustomFields.registerCustomFieldsTypes "basic-calc", 
  type_id: "calc"
  label: "Smart Numbers" # Derive from the descendants