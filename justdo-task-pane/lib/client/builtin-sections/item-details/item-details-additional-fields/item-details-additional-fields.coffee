APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  formatWithPrintFormatter = (gc, item_id, field, val, missing_fields_values, path) ->
    schema = gc.getSchemaExtendedWithCustomFields()

    if not (formatter_id = schema[field]?.grid_column_formatter)?
      module.logger.error "Failed to find print formatter to field #{field}"

      # Return val as is
      return val

    formatted_val =
      gc._print_formatters[formatter_id](missing_fields_values, field, path)

    if _.isString formatted_val
      return JustdoHelpers.xssGuard formatted_val

    return formatted_val

  Template.task_pane_item_details_additional_fields.helpers
    rerenderTrigger: JustdoHelpers.generateRerenderForcer()

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

      fields_projection = {
        _id: 1
      }

      for field_id in fields_missing_from_view
        fields_projection[field_id] = 1

        if not (field_schema_def = gc.getSchemaExtendedWithCustomFields()[field_id])?
          conosle.warn "Failed to find a schema definition for a field, there might be a serious issue here."

          continue

        if (grid_dependencies_fields = field_schema_def.grid_dependencies_fields)?
          for dependency_field in grid_dependencies_fields
            fields_projection[dependency_field] = 1

      missing_fields_values =
        APP.collections.Tasks.findOne(
          current_item_id, {fields: fields_projection})

      if not missing_fields_values?
        # The item got removed
        return null

      additional_fields = []
      for field_id in fields_missing_from_view
        value = missing_fields_values[field_id]

        additional_field = 
          field_id: field_id
          label: extended_schema[field_id].label
          value: value
          formatter: extended_schema[field_id].grid_column_formatter

        if not gc.isEditableField(field_id)
          additional_field.formatted_value =
            formatWithPrintFormatter(gc, current_item_id, field_id, value, missing_fields_values, current_item_path)

        additional_fields.push additional_field

      return additional_fields

  Template.task_pane_item_details_additional_field.helpers
    isEditableField: ->
      gc = APP.modules.project_page.gridControl()

      return gc.isEditableField(@field_id)

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

  Template.task_pane_item_details_additional_field_editor.onRendered ->
    parent_tpl = Template.closestInstance("task_pane_item_details_additional_field")

    field_id = parent_tpl.data.field_id

    current_item_id = module.activeItemId()

    gc = APP.modules.project_page.gridControl()

    field_def = gc.getFieldDef(field_id)

    grid_column_editor = field_def.grid_column_editor

    field_editor = gc.generateFieldEditor(field_id, current_item_id)

    $firstNode = $(@firstNode)
    $firstNode.data("editor_field_id", field_id)    
    $firstNode.data("editor", field_editor)
    $(@firstNode).html(field_editor.$dom_node)

    # Run modifications to the way the editor should work when running from the
    # More Info section
    field_editor.editor.moreInfoSectionCustomizations?($firstNode, field_editor)
    # The moreInfoSectionCustomizationsExtensions was added to let extensions to
    # the original editors to set extra special customizations without overriding
    # the original customizations.
    field_editor.editor.moreInfoSectionCustomizationsExtensions?($firstNode, field_editor)

    $(window).trigger("resize.autosize")

    return