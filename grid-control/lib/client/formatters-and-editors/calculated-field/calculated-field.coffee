#
# Calculated field formatter and editor
#
backward_compatibility_functions_regex = /^=(sum)\((.*?)\)$/i
backwardCompatibilityTransformation = (raw_doc_value) ->
  #
  # Backward compatibility with sum({direct_children_only: true/false, filter_aware: true/false})
  #
  if _.isString(raw_doc_value) and raw_doc_value[0] == "=" and (results = backward_compatibility_functions_regex.exec(raw_doc_value))?
    [m, function_name, options] = results

    # Normalize
    function_name = function_name.toLowerCase()

    if options.trim() == ""
      options = null
    else
      try
        options = JSON.parse(options)
      catch e
        options = {}

    default_options =
      direct_children_only: true
      filter_aware: false

    options = _.extend {}, default_options, options

    raw_doc_value = "=" + JustdoHelpers.lcFirst("""#{if options.filter_aware then "Filtered" else ""}#{if options.direct_children_only then "Children" else "Tree"}Sum()""")

  return raw_doc_value

#
# Actions buttons definitions:
#

# Set the actions buttons in the following format:
# 
# [
#   {
#     # IMPORTANT: remember formatters need to be very efficient,
#     # all style (background image for example) should be set in
#     # the stylesheet level.
#
#     action_name: "" # string will be prefixed with "cfld-" and set as a class
                      # give a hyphen-separated name.
#     width: # Number, the width in pixels of the buttons, used for layout calculations only (we don't set this width, only use its value for calcs)
#     action_title: "Set date" # Title to show on hover
#     action_formatter: (e, formatter_details) ->
#                              # Action to perform on click when the cell state is formatter
#                              # `e` is the event object
#                              # `formatter_details` is the output of @getEventFormatterDetails(e)
#                              #
#                              # @ is the grid_control object 
#                              # You can use: @editEventCell(e) to change to edit mode
#     action_editor: (e, editor_object) -> # Action to perform on click when the cell state is edit
#     show_if_empty: false/true # if false, we will show the icon if the item document
#                               # had value for the cell field
#     font_awesome_id: "icon-id" # if set we will insert a font awesome icon inside the icon div
#   }
# ]
#
default_buttons = [
  # {
  #     action_name: "field-settings"
  #     width: 20
  #     action_title: "Configure"
  #     font_awesome_id: "caret-down"
  #     action_formatter: (e, formatter_details) ->
  #       console.log "Clicked - Formatter"
  #     action_editor: (e, editor_object) ->
  #       console.log "Clicked - Editor"

  #       return
  #     show_if_empty: true
  # }
]

default_ext_buttons = []

calculated_field_functions = {}

functions_regex = null

updateFunctionsRegex = ->
  funcs_settings_modifiers_prefixes = "((?:filtered)?(?:tree|children))"
  funcs_ids_group_regex = "(#{_.keys(calculated_field_functions).join("|")})"
  input_part_regex = "\\((.*?)\\)"

  functions_regex = new RegExp(funcs_settings_modifiers_prefixes + funcs_ids_group_regex + input_part_regex, "ig")

  return

share.installCalculatedFieldFunction = (func_id, settings) ->
  if not /^[a-zA-Z0-9]+$/.test(func_id)
    throw new Meteor.Error("invalid-calculated-field-function-name", "Calculated field function must match /^[a-zA-Z0-9]+$/ - #{func_id} provided")

  calculated_field_functions[func_id] = settings

  updateFunctionsRegex()

  return

setupContextMenuCalcFieldsControls = ->
  tasks_collection = @collection

  APP.justdo_tasks_context_menu.registerMainSection "calc-fields",
    position: 250 # As of writing, that means between copy-paste and projects
    data:
      label: "Set function"

    listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
      if not field_info?
        # Happens when initiating the context menu
        return false
      
      if field_info.formatter_name != "calculatedFieldFormatter"
        return false

      return true

  APP.justdo_tasks_context_menu.registerSectionItem "calc-fields", "clear-formula",
    position: 100
    data:
      label: "Clear formula"
      op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        tasks_collection.update(task_id, {$set: {"#{field_info.field_name}": ""}})

        return
      icon_type: "none"
    listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
      return _.isString(field_val) and field_val[0] == "="

  supported_funcs = [
    {
      func: "sum"
      label: "Sum"
    }
    {
      func: "avg"
      label: "Average"
    }
    {
      func: "median"
      label: "Median"
    }
    {
      func: "min"
      label: "Min"
    }
    {
      func: "max"
      label: "Max"
    }
    {
      func: "count"
      label: "Count items"
    }
  ]

  item_position = 200 # Clear func is on 100
  for supported_func in supported_funcs
    {func, label} = supported_func

    do (func, label) ->
      APP.justdo_tasks_context_menu.registerSectionItem "calc-fields", func,
        position: item_position
        data:
          label: label
          is_nested_section: true
          icon_type: "none"

      APP.justdo_tasks_context_menu.registerNestedSection "calc-fields", func, "#{func}-options",
        position: 100

      APP.justdo_tasks_context_menu.registerSectionItem "#{func}-options", "#{func}-tree",
        position: 100
        data:
          label: "Tree"
          icon_type: "none"
          op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            tasks_collection.update(task_id, {$set: {"#{field_info.field_name}": "=tree#{JustdoHelpers.ucFirst(func)}()"}})

            return

      APP.justdo_tasks_context_menu.registerSectionItem "#{func}-options", "#{func}-filtered-tree",
        position: 200
        data:
          label: "Filtered tree"
          icon_type: "none"
          op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            tasks_collection.update(task_id, {$set: {"#{field_info.field_name}": "=filteredTree#{JustdoHelpers.ucFirst(func)}()"}})

            return

      APP.justdo_tasks_context_menu.registerSectionItem "#{func}-options", "#{func}-children",
        position: 300
        data:
          label: "Children"
          icon_type: "none"
          op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            tasks_collection.update(task_id, {$set: {"#{field_info.field_name}": "=children#{JustdoHelpers.ucFirst(func)}()"}})

            return

      APP.justdo_tasks_context_menu.registerSectionItem "#{func}-options", "#{func}-filtered-children",
        position: 400
        data:
          label: "Filtered children"
          icon_type: "none"
          op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            tasks_collection.update(task_id, {$set: {"#{field_info.field_name}": "=filteredChildren#{JustdoHelpers.ucFirst(func)}()"}})

            return

      return

    item_position += 100

  return

#
# Formatter
#
formatter_name = "calculatedFieldFormatter"
GridControl.installFormatter formatter_name,
  invalidate_ancestors_on_change: "structure-content-and-filters"

  gridControlInit: ->
    # Setup methods that are introduced as shortcuts for dealing with calculated fields

    setupContextMenuCalcFieldsControls.call(@)

    @getItemCalculatedFieldValue = (item_id, field_id, path=undefined) =>
      # Note path is optional, but, providing it will improve performance, and
      # has other implications, search this file for comment marked:
      # INDEX_NULL_PATH_IMPLICATION

      main_gc = @getMainGridControlOrSelf()

      return GridControl.Formatters.calculatedFieldFormatter.calculatePathCalculatedFieldValue(main_gc, field_id, path, main_gc._grid_data._grid_data_core.items_by_id[item_id])

    return

  #
  # Functions
  #
  calculatePathCalculatedFieldValue: (grid_control, field_id, path, item_obj) ->
    # Caluculate the value of field_id recursively.
    #
    # ## Calculated field returned value:
    #
    # For fields that aren't calculated fields (that doesn't begin with the = sign)
    # we simply return the value as is.
    #
    # For calculated fields, we return an object with the 'cval' field that contains
    # the calculated field value to display to the user.
    #
    # Example: {cval: calculated value to display}
    #
    # ## Errors handling:
    #
    # Returned objects that has the err property should be regarded as errors.
    # the value of the err property is the human readable (as much as possible)
    # error message that can be presented to the user. Example:
    #
    # {err: "Error to display"}
    #
    # ## Notes
    #
    # ### de-normalized arguments:
    #
    # The received argument list is not normalized as item_obj can be dervied
    # from path, denormalized to avoid looking-up the item_obj from path.
    #
    # Technically, that means that wrong data can be provided to the arg,
    # for example, non-existing path with a valid item_obj. We avoid checking
    # validity and correctness in place it isn't necessary, and we assume
    # data provided is true and correct.
    #
    # ### null path argument, and implications on future types of supported
    #     calculated fields functions INDEX_NULL_PATH_IMPLICATION:
    #
    # For the print formatters and when value is calculated by @getItemCalculatedFieldValue
    # we don't have direct way to know what path the item we are formatting
    # for printing is under. That's because gc._print_formatters.formatter(document, field_name)
    # is not called with path, and for @getItemCalculatedFieldValue, by design,
    # the path is optional.
    #
    # Because of that, if path is null, we'll find it by ourself before we
    # call the field function (that expect path to be set). 
    # Every item might be under many paths (as a result of the multiple
    # parents data structure).
    #
    # Since we don't know which path is the one the user is printing, we simply
    # choose one of the paths arbitrarily.
    #
    # That comes with a caveat: if, in the future we will want to implement a
    # calculator that traverse the tree upward, we won't be able to do so without
    # changes to the print API.

    if not (value = item_obj?[field_id])?
      # No value, raw empty value
      return ""

    if value[0] != "="
      # Nothing to calculate, raw value
      return value

    value = backwardCompatibilityTransformation(value)

    value = value.substr(1)

    if not functions_regex?
      console.warn "No functions were set for calculatedFieldFormatter"

      return {cval: value}

    if not path?
      path = grid_control._grid_data.getCollectionItemIdPath(item_obj._id)

    try
      value = value.replace functions_regex, (match, func_options_str, func_id, func_args_str) =>
        func_options_str = func_options_str.toLowerCase()
        func_id = func_id.toLowerCase()

        {func} = func_settings = calculated_field_functions[func_id]

        function_options = {}

        function_options.filter_aware = false
        if func_options_str.indexOf("filtered") >= 0
          if not func_settings.allow_filter_aware
            throw new Error("The filters aware version of #{func_id} asked for in `#{match}' is not supported.")

          function_options.filter_aware = true

        function_options.direct_children_only = true
        if func_options_str.indexOf("tree") >= 0 or func_options_str.indexOf("children") >= 0
          if not func_settings.allow_tree_ops
            throw new Error("The sub-tree version of #{func_id} asked for in `#{match}' is not supported.")

          if func_options_str.indexOf("tree") >= 0
            function_options.direct_children_only = false

        return func.call(@, function_options, grid_control, field_id, path, item_obj)
    catch e
      return {err: e.message}

    return {cval: value}

  # Defining functions for the calculated field
  #
  # Functions names in the calculated fields are case insensitive
  # and are lookedup in the list of functions under the _functions
  # object of the formatter object.
  #
  # The share.installCalculatedFieldFunction(func_id, settings) installs
  # functions that can be used by the users.
  #
  # The functions that will actually be enabled for the user are a set of
  # func_id suffixed functions that depends on the settings set for the func.
  #
  # settings.func is called with the following arguments:
  #
  #   (function_options, grid_control, field_id, path, item_obj)
  #
  # when defining func, you can assumed that the value for the field
  # in the path provided was parsed correctly to refer to the function
  # called with the function_options (i.e. the function can begin the
  # calculation immediately).
  #
  # ## Helpers
  #
  # ### @calculatePathCalculatedFieldValue():
  #
  # To get the calculated field value of another row use the @calculatePathCalculatedFieldValue()
  # helper attached to its @ .
  # Read calculatePathCalculatedFieldValue source for more details. 
  #
  # ## Return value
  #
  # You should use the arguments provided to return the calculated field value.
  # The returned value type can be of any type we can present as text in a text
  # field.
  #
  # If an error prevented the value from being calculated return an error message
  # in a JS object with the err property set to the message you want to present to
  # the user. Example: {err: "Can't divide by 0"}

  getFieldValue: (friendly_args) ->
    # Note, for print, we won't have path set in friendly args, see 
    # note in @calculatePathCalculatedFieldValue for more details.
    {formatter_obj, grid_control, field, path, doc} = friendly_args

    value = 
      @calculatePathCalculatedFieldValue(grid_control, field, path, doc)

    # If error found, return it as the value, prefixed with "Error: "
    if (err = value.err)?
      return "Error: #{err}"

    # If field is calculated field, show its returned value
    if (cval = value.cval)?
      return """<div style="font-weight: bold; text-decoration: underline; text-align: right;">#{cval}</div>"""

    return """<div style="text-align: right;">#{value}</div>"""

  #
  # Actions buttons
  #

  actions_buttons: default_buttons
  ext_actions_buttons: default_ext_buttons

  getAllActionsButtons: ->
    return @actions_buttons.concat(@ext_actions_buttons)

  getActionButtonDef: (action_name) ->
    all_actions_buttons = @getAllActionsButtons()

    return _.find all_actions_buttons, (i) -> i.action_name == action_name

  #
  # Formatters
  #
  slick_grid: ->
    friendly_args = @getFriendlyArgs()

    {formatter_obj} = friendly_args 

    field_value = formatter_obj.getFieldValue(friendly_args)

    formatter_content = ""
    content_empty = true
    if field_value != ""
      content_empty = false
      formatter_content += """
        #{field_value}
      """

    formatter_buttons = ""
    for action_button_def in formatter_obj.getAllActionsButtons()
      if not content_empty or action_button_def.show_if_empty
        # add the button only if the content isn't empty, or if it is
        # allowed to show it for non empty fields
        formatter_buttons += """
          <div class="cfld-action-btn cfld-id-#{action_button_def.action_name} slick-prevent-edit" title="#{action_button_def.action_title}">
        """

        if (icon_id = action_button_def.font_awesome_id)?
          formatter_buttons += """
            <i class="fa fa-fw fa-#{icon_id} slick-prevent-edit" aria-hidden="true"></i>
          """

        formatter_buttons += """
          </div>
        """

    formatter = """
      <div class="grid-formatter cfld-formatter">
        #{formatter_content}#{formatter_buttons}
      </div>
    """

    return formatter

  #
  # Events
  #
  slick_grid_jquery_events: [
    {
      args: ["click", ".cfld-formatter .cfld-action-btn"]
      handler: (e) ->
        btn_class_name_prefix = "cfld-id-"

        action_btn_classes =
          $(e.target).closest(".cfld-action-btn").attr("class").split(" ")
        action_btn_name_class =
          _.filter(action_btn_classes, (i) -> i.substr(0, btn_class_name_prefix.length) == btn_class_name_prefix
          )[0]
        action_name = action_btn_name_class.replace(btn_class_name_prefix, "")

        formatter_details = @getEventFormatterDetails(e)

        {column_view_state, column_field_schema,
          formatter_obj, formatter_name} = formatter_details

        action_def = formatter_obj.getActionButtonDef(action_name)

        action_def.action_formatter.call(@, e, formatter_details)

        return
    }
  ]

  print: (doc, field, path) ->
    friendly_args = @getFriendlyArgs()

    {formatter_obj} = friendly_args 

    value = formatter_obj.getFieldValue(friendly_args)

    return value

  print_formatter_produce_html: true

#
# EDITOR
#

GridControl.installEditorExtension
  editor_name: "CalculatedFieldEditor"
  extended_editor_name: "TextareaEditor"
  prototype_extensions:
    actions_buttons: default_buttons
    ext_actions_buttons: default_ext_buttons

    preEditDocValueTransformation: (raw_doc_value) ->
      processed_doc_value = backwardCompatibilityTransformation(raw_doc_value)

      return processed_doc_value

    preDbInsertionTransformation: ->
      return

    generateInputWrappingElement: ->
      $editor = $("""<div class="grid-editor cfld-editor" />""")

      $editor
        .html(@$input)
        .appendTo(@context.container);

      if not _.isNaN(parseFloat(@getEditorFieldValueFromDoc()))
        # Align numeral values to the right
        @$input.css({"text-align": "right"})

      @$input.addClass("cfld-editor-textarea")

      formatter_buttons_width = 0
      for action_button_def in @getAllActionsButtons()
        do (action_button_def) =>
          formatter_button = ""

          show_if_empty_class = if not action_button_def.show_if_empty then "cfld-hidden-if-empty" else ""

          # add the button only if the content isn't empty, or if it is
          # allowed to show it for non empty fields
          formatter_button += """
            <div class="cfld-action-btn cfld-id-#{action_button_def.action_name} #{show_if_empty_class}" title="#{action_button_def.action_title}">
          """

          if (icon_id = action_button_def.font_awesome_id)?
            formatter_button += """
              <i class="fa fa-fw fa-#{icon_id}" aria-hidden="true"></i>
            """

          formatter_button += """
            </div>
          """

          $button = $(formatter_button)
          $button.appendTo($editor)
          $button.click (e) =>
            action_button_def.action_editor(e, @)

          formatter_buttons_width += action_button_def.width

      @$input.width(@$input.width() - formatter_buttons_width - 3 - 1) # - 1 compensates the extra margin we add to .cfld-id-field-settings only for editors (to have exact alignment with formatter)

      return $editor

    #
    # Custom helpers
    #
    getAllActionsButtons: ->
      return @actions_buttons.concat(@ext_actions_buttons)
