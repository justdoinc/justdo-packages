#
# Calculated field formatter and editor
#

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

share.installCalculatedFieldFunction = (function_name, func) ->
  if not /^[a-z_0-9]+$/.test(function_name)
    throw new Meteor.Error("invalid-calculated-field-function-name", "Calculated field function must be all lowered case underscored name /^[a-z_0-9]+$/ - #{function_name} provided")

  calculated_field_functions[function_name] = func

  return

#
# Formatter
#
formatter_name = "calculatedFieldFormatter"
GridControl.installFormatter formatter_name,
  invalidate_ancestors_on_change: "structure-content-and-filters"

  #
  # Functions
  #
  functions_regex: /^=([a-z_0-9]+?)\((.*?)\)$/i

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
    #     calculated fields functions:
    #
    # For the print formatters we don't have direct way to know what
    # path the item we are formatting for printing is under. That's
    # because gc._print_formatters.formatter(document, field_name) is not
    # called with path.
    #
    # Because of that, if path is null, we'll find it by ourself before we
    # call the field function (that expect path to be set). 
    # Every item might be under many paths (as a resulte of the multiple
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

    # Run the function
    if not (results = @functions_regex.exec(value))?
      return {err: "Syntax error"}

    [m, function_name, options] = results

    # Normalize
    function_name = function_name.toLowerCase()

    if function_name not of @_functions
      return {err: "Unknown function: #{function_name}()"}

    if options.trim() == ""
      options = null
    else
      try
        options = JSON.parse(options)
      catch e
        return {err: "couldn't parse options provided to function"}

    if not path?
      path = grid_control._grid_data.getCollectionItemIdPath(item_obj._id)

    return {cval: @_functions[function_name].call(@, options, grid_control, field_id, path, item_obj)}

  # Defining functions for the calculated field
  #
  # Functions names in the calculated fields are case insensitive
  # and are lookedup in the list of functions under the _functions
  # object of the formatter object.
  #
  # The share.installCalculatedFieldFunction(func_name, func) installs
  # functions that can be used by the users.
  #
  # func is called with the following arguments:
  #
  #   (function_options, grid_control, field_id, path, item_obj)
  #
  # when defining func, you can assumed that the value for the field
  # in the path provided was parsed correctly to refer to the function
  # called with the function_options (i.e. the function can begin the
  # calculation immediately).
  #
  # ## The function_options argument
  # 
  # Functions can get as their first argument a JSON object that represents
  # the function object - XXX in the future more types of arguments will be
  # implemented. If no options argument provided, function_options will be
  # simply null.
  #
  # If such a JSON object provided, its parsed value will be passed in the
  # function_options argument below - never trust user provided data! make
  # sure it is secured before working with it.
  #
  # Example 1: for calculated field with the value '=SUM({"filter_aware": false})'
  # the sum function will be called with function_options set to
  # {filter_aware: false}.
  #
  # Example 2: For '=SUM()' function_options will be null.
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
  _functions: calculated_field_functions # Do not edit this object manualy, use
                                         # share.installCalculatedFieldFunction

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
      return "<u><b>#{cval}</b></u>"

    return value

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

  print: (doc, field) ->
    friendly_args = @getFriendlyArgs()

    {formatter_obj} = friendly_args 

    value = formatter_obj.getFieldValue(friendly_args)

    return value
    

#
# EDITOR
#

GridControl.installEditorExtension
  editor_name: "CalculatedFieldEditor"
  extended_editor_name: "TextareaEditor"
  prototype_extensions:
    actions_buttons: default_buttons
    ext_actions_buttons: default_ext_buttons

    generateInputWrappingElement: ->
      $editor = $("""<div class="grid-editor cfld-editor" />""")

      $editor
        .html(@$input)
        .appendTo(@context.container);

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
