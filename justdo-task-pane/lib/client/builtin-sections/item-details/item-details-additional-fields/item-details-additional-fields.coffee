APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  scrollToTargetColumn = (jquery_selector, gc) ->
  
    # Shine the col
    $col_header = $(jquery_selector, gc.container)
    $col_header.addClass "shine-slick-grid-column-header"

    # As of writing $frozen_col is always the "title" field.
    # `$frozen_col` is only relevant if there's a frozen col.
    # If it doesn't exists, `frozen_col_width` will be 0 to faciliate the math later.
    $frozen_col = null
    frozen_col_width = 0
    if gc.getView()[0].frozen is true
      $frozen_col = $(".slick-header-column:first", gc.container)
      frozen_col_width = $frozen_col.get(0).offsetWidth
  

    # Values for calculating whether col is in view or not
    # Note that for width calculations, we use offsetWidth instead of width to get the true width (including padding and border, but not margin)
    $slick_viewport = $(".slick-viewport", gc.container)
    slick_viewport_scroll_left = $slick_viewport.scrollLeft()
    slick_viewport_width = $slick_viewport.get(0).offsetWidth
    slick_viewport_width_without_frozen_col = slick_viewport_width - frozen_col_width
    
    col_left_position = $col_header.position().left

    # If the col is the frozen col, we don't need to perform scroll since it's always visible.
    is_col_frozen_col = $col_header.is($frozen_col)

    # The math is different in LTR vs RTL. To help understanding it, below are some examples that build up the math.
    # - When scrolled to the end of viewport (away from $frozen_col):
    #   - LTR:
    #         slick_viewport_scroll_left = sum_of_all_non_frozen_cols_offset_width - slick_viewport_width_without_frozen_col
    #   - RTL:
    #         slick_viewport_scroll_left = - (sum_of_all_non_frozen_cols_offset_width - slick_viewport_width_without_frozen_col)
    # - The `col_left_position` of the first column (next to the frozen col):
    #   - LTR:
    #         col_left_position = frozen_col_width
    #   - RTL:
    #         col_left_position = slick_header_columns_width - frozen_col_width - col_width
    # - The `col_left_position` of the last column (next to the frozen col):
    #   - LTR:
    #         col_left_position = slick_header_columns_width - col_width - 1000 (where 1000 is a constant coming from `getHeadersWidth` under `slick.grid.js`)
    #   - RTL:
    #         col_left_position = 1000 (where 1000 is a constant coming from `getHeadersWidth` under `slick.grid.js`)
    if APP.justdo_i18n.isRtl()
      col_width = $col_header.get(0).offsetWidth

      $slick_header_columns = $(".slick-header-columns")
      slick_header_columns_width = $slick_header_columns.get(0).offsetWidth

      col_position = col_left_position + col_width + frozen_col_width
      viewport_begin_position = slick_viewport_scroll_left + slick_header_columns_width
      viewport_end_position = viewport_begin_position - slick_viewport_width_without_frozen_col

      is_col_hidden_to_the_right = viewport_begin_position <= col_position
      is_col_hidden_to_the_left = viewport_end_position >= col_position

      scroll_left = col_position - slick_header_columns_width
    else # ltr
      col_position = col_left_position - frozen_col_width
    
      viewport_begin_position = slick_viewport_scroll_left
      viewport_end_position = viewport_begin_position + slick_viewport_width_without_frozen_col

      is_col_hidden_to_the_left = viewport_begin_position >= col_position
      is_col_hidden_to_the_right = viewport_end_position <= col_position

      scroll_left = col_position

    if not is_col_frozen_col and  (is_col_hidden_to_the_left or is_col_hidden_to_the_right)
      # Scroll the col into view if it's not visible

      $slick_viewport.animate { scrollLeft: scroll_left }, 500

    setTimeout ->
      $col_header.removeClass "shine-slick-grid-column-header"
    , 2500

    return

  removeTreeControlsFromFormatterOrEditor = (formatter_or_editor) ->
    # This function simply replaces "TextareaWithTreeControlsEditor" with "TextareaEditor"
    # and "textWithTreeControls" with "defaultFormatter" and do nothing otherwise.
    #
    # The reason is: TextareaWithTreeControlsEditor includes the seqId, avatar and many other components that we don't want to show
    # in the More Info section.
    if formatter_or_editor is "TextareaWithTreeControlsEditor"
      return "TextareaEditor"
    
    if formatter_or_editor is "textWithTreeControls"
      return "defaultFormatter"

    return formatter_or_editor

  formatWithPrintFormatter = (gc, item_id, field, val, dependencies_values, path) ->
    schema = gc.getSchemaExtendedWithCustomFields()
    if not (grid_visible_column = schema[field]?.grid_visible_column)? or grid_visible_column is false
      return

    if not (formatter_id = schema[field]?.grid_column_formatter)?
      project_page_module.logger.error "Failed to find print formatter to field #{field}"

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
    fields: ->
      current_item_id = project_page_module.activeItemId()
      current_item_path = project_page_module.activeItemPath()

      if not current_item_id?
        return

      gc = project_page_module.gridControl()

      # Call JustdoHelpers.getUserPreferredDateFormat() so additional fields values
      # will be reactive to the uesr's preferred date format
      JustdoHelpers.getUserPreferredDateFormat()
      # Call gc.getViewReactive(), since gc.fieldsMissingFromView() isn't reactive
      gc.getViewReactive()

      fields_missing_from_view = gc.fieldsMissingFromView()
      extended_schema = gc.getSchemaExtendedWithCustomFields()

      fields = []
      for field_id, field_def of extended_schema 
        if field_def.grid_more_info_visible_column is false
          continue
        
        if field_def.grid_visible_column isnt true
          continue

        formatter = removeTreeControlsFromFormatterOrEditor field_def.grid_column_formatter

        field = 
          field_id: field_id
          label_i18n: field_def.label_i18n
          label: field_def.label
          formatter: formatter

        if field.formatter?
          field.field_invalidate_ancestors_on_change =
            gc.getFormatterDefinition(field.formatter).invalidate_ancestors_on_change

        fields.push field

      return fields

  Template.task_pane_item_details_additional_field.helpers
    isEditableField: ->
      gc = APP.modules.project_page.gridControl()

      if not gc.isEditableField(@field_id)
        return false

      fields_to_fetch = {"#{@field_id}": 1, "#{CustomJustdoTasksLocks.locking_users_task_field}": 1}

      if (grid_dependencies_fields = gc.getSchemaExtendedWithCustomFields()?[@field_id]?.grid_dependencies_fields)?
        for dep_field_id in grid_dependencies_fields
          fields_to_fetch[dep_field_id] = 1

      current_item_obj = project_page_module.activeItemObj(fields_to_fetch)
      current_item_path = project_page_module.activeItemPath()

      if not current_item_obj? or not current_item_path?
        return false

      return gc.isDocFieldAndPathEditable(current_item_obj, @field_id, current_item_path)

    getFormatterOutput: (options) ->
      {field_info, field_and_dependencies_values} = options.hash
      gc = APP.modules.project_page.gridControl()
      
      if not (current_item_id = project_page_module.activeItemId())?
        return

      if not (current_item_path = project_page_module.activeItemPath())?
        return

      return formatWithPrintFormatter(gc, current_item_id, field_info.field_id, field_and_dependencies_values[field_info.field_id], field_and_dependencies_values, current_item_path)

    getFieldAndDependenciesValues: ->
      # Note, this method serves 2 purposes: 1) Retreiving the values. 2) Creating a reactive
      # context that invalidates upon changes to dependencies or any other aspect that might
      # affect the field value and require calculation (e.g. dependencies changes, cases where
      # sub items affects the value, and, potentially more).

      if not (current_item_id = project_page_module.activeItemId())?
        return {}

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

      return gc.collection.findOne(current_item_id, {fields: JustdoHelpers.fieldsArrayToInclusiveFieldsProjection(field_plus_dependencies)}) or {}

    isFieldOnGrid: ->
      gc = APP.modules.project_page.gridControl()
      fields_missing_from_view = gc.fieldsMissingFromView()
      return @field_id not in fields_missing_from_view

  Template.task_pane_item_details_additional_field.events
    "click .add-to-grid": (e) ->
      gc = project_page_module.gridControl()

      gc.addFieldToView @field_id

      Meteor.defer ->
        scrollToTargetColumn(".slick-header-column:last", gc)

      return

    "click .locate-on-grid": (e) ->
      gc = project_page_module.gridControl()
      grid_uid = gc.getGridUid()

      scrollToTargetColumn(".slick-header-column[id=\"#{grid_uid}#{@field_id}\"]", gc)

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

    current_item_id = project_page_module.activeItemId()

    gc = APP.modules.project_page.gridControl()

    field_def = gc.getFieldDef(field_id)

    grid_column_editor = removeTreeControlsFromFormatterOrEditor field_def.grid_column_editor

    field_editor = gc.generateFieldEditor(field_id, current_item_id, grid_column_editor)

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

    # The following was called before, it came up during optimization profiling as inefficient
    # and seemed to be unnecessary 
    # $(window).trigger("resize.autosize")

    return
