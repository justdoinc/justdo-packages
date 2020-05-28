APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  formatWithPrintFormatter = (gc, item_id, field, val, dependencies_values, path) ->
    schema = gc.getSchemaExtendedWithCustomFields()

    if not (formatter_id = schema[field]?.grid_column_formatter)?
      module.logger.error "Failed to find print formatter to field #{field}"

      # Return val as is
      return val

    printFormatter = gc._print_formatters[formatter_id]

    formatted_val =
      printFormatter(dependencies_values, field, path)

    if _.isString formatted_val
      if printFormatter.html_output is true
        xssGuard_options =
          allow_html_parsing: true
          enclosing_char: ""
      else
        xssGuard_options = {}

      return JustdoHelpers.xssGuard formatted_val, xssGuard_options

    return formatted_val

  Template.task_pane_item_details_additional_fields.helpers
    additionalFields: ->
      current_item_id = module.activeItemId()
      current_item_path = module.activeItemPath()

      if not current_item_id?
        return

      gc = module.gridControl()

      # Call JustdoHelpers.getUserPreferredDateFormat() so additional fields values
      # will be reactive to the uesr's preferred date format
      JustdoHelpers.getUserPreferredDateFormat()
      # Call gc.getViewReactive(), since gc.fieldsMissingFromView() isn't reactive
      gc.getViewReactive()

      fields_missing_from_view = gc.fieldsMissingFromView()
      extended_schema = gc.getSchemaExtendedWithCustomFields()

      additional_fields = []
      for field_id in fields_missing_from_view
        additional_field = 
          field_id: field_id
          label: extended_schema[field_id].label
          formatter: extended_schema[field_id].grid_column_formatter

        if additional_field.formatter?
          additional_field.field_invalidate_ancestors_on_change =
            gc.getFormatterDefinition(additional_field.formatter).invalidate_ancestors_on_change

        additional_fields.push additional_field

      return additional_fields

  Template.task_pane_item_details_additional_field.helpers
    isEditableField: ->
      gc = APP.modules.project_page.gridControl()

      if not gc.isEditableField(@field_id)
        return false

      current_item_obj = module.activeItemObj({"#{@field_id}": 1, "#{CustomJustdoTasksLocks.locking_users_task_field}": 1})
      current_item_path = module.activeItemPath()

      if not current_item_obj? or not current_item_path?
        return false

      return gc.isDocFieldAndPathEditable(current_item_obj, @field_id, current_item_path)

    getFormatterOutput: (options) ->
      {field_info, field_and_dependencies_values} = options.hash
      gc = APP.modules.project_page.gridControl()
      
      if not (current_item_id = module.activeItemId())?
        return

      if not (current_item_path = module.activeItemPath())?
        return

      return formatWithPrintFormatter(gc, current_item_id, field_info.field_id, field_and_dependencies_values[field_info.field_id], field_and_dependencies_values, current_item_path)

    getFieldAndDependenciesValues: ->
      # Note, this method serves 2 purposes: 1) Retreiving the values. 2) Creating a reactive
      # context that invalidates upon changes to dependencies or any other aspect that might
      # affect the field value and require calculation (e.g. dependencies changes, cases where
      # sub items affects the value, and, potentially more).

      if not (current_item_id = module.activeItemId())?
        return

      gc = APP.modules.project_page.gridControl()

      schema = gc.getSchemaExtendedWithCustomFields()

      dependencies =
        gc.getSchemaExtendedWithCustomFields()?[@field_id]?.grid_dependencies_fields or []
      field_plus_dependencies = [@field_id].concat(dependencies)

      if @field_invalidate_ancestors_on_change in ["structure-and-content", "structure-content-and-filters"]
        options =
          tracked_fields: field_plus_dependencies
          filters_aware: @field_invalidate_ancestors_on_change == "structure-content-and-filters"
        gc.invalidateOnCollectionItemDescendantsChanges(current_item_id, options)

      return gc.collection.findOne(current_item_id, {fields: JustdoHelpers.fieldsArrayToInclusiveFieldsProjection(field_plus_dependencies)})

  Template.task_pane_item_details_additional_field.events
    "click .add-to-grid": (e) ->
      gc = module.gridControl()

      gc.addFieldToView @field_id

      Meteor.defer ->
        # Shine the row
        $row_header = $(".slick-header-column:last", gc.container)
        $row_header.addClass "shine-slick-grid-column-header"
        $slick_viewport = $(".slick-viewport", gc.container)
        $slick_viewport.animate { scrollLeft: $(".grid-canvas", gc.container).width() }, 500
        setTimeout ->
          $row_header.removeClass "shine-slick-grid-column-header"
        , 2000

      return

  Template.task_pane_item_details_additional_field_editor_rerender_wrapper.onCreated ->
    @rerenderForcer = JustdoHelpers.generateRerenderForcer()

    return 

  Template.task_pane_item_details_additional_field_editor_rerender_wrapper.helpers
    rerenderTrigger: ->
      tpl = Template.instance()

      return tpl.rerenderForcer()

  Template.task_pane_item_details_additional_field_editor.onRendered ->
    field_id = @data.field_info.field_id

    current_item_id = module.activeItemId()

    gc = APP.modules.project_page.gridControl()

    field_def = gc.getFieldDef(field_id)

    grid_column_editor = field_def.grid_column_editor

    field_editor = gc.generateFieldEditor(field_id, current_item_id)

    $field_editor_container = this.$(".field-editor")
    $field_editor_container.data("editor_field_id", field_id)    
    $field_editor_container.data("editor", field_editor)
    $field_editor_container.html(field_editor.$dom_node)

    # Run modifications to the way the editor should work when running from the
    # More Info section
    field_editor.editor.moreInfoSectionCustomizations?($field_editor_container, field_editor)
    # The moreInfoSectionCustomizationsExtensions was added to let extensions to
    # the original editors to set extra special customizations without overriding
    # the original customizations.
    field_editor.editor.moreInfoSectionCustomizationsExtensions?($field_editor_container, field_editor)

    $(window).trigger("resize.autosize")

    return
