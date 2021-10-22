#
# Unicode date formatter and editor
#

# This is the format we expect the raw data to be provided
# to the formatter/editor as
raw_data_moment_format = "YYYY-MM-DD"

normalizeUserPreferenceDateFormatAndFormatToUnicodeDateString = (user_format_date_string) ->
  if not user_format_date_string? or user_format_date_string == ""
    return ""

  return moment(user_format_date_string, JustdoHelpers.getUserPreferredDateFormat()).format(raw_data_moment_format)

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
#     action_name: "" # string will be prefixed with "udf-" and set as a class
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
  {
      action_name: "date-setter"
      width: 17
      action_title: "Set date"
      action_formatter: (e, formatter_details) ->
        # On the formatter we start edit mode and open the date
        # picker immediately.
        # Note we don't want to load jQuery ui's date picker on the
        # formatter level as it is too wasteful in resources do for
        # every single formatter...
        @editEventCell e, (editor_object) ->
          editor_object.showPicker?() # We assume the editor is based on unicode_date...
      action_editor: (e, editor_object) ->
        editor_object.togglePicker()

        return
      show_if_empty: true
  }
]

default_ext_buttons = []

#
# Formatter
#
GridControl.installFormatter "unicodeDateFormatter",
  #
  # Helpers:
  # accessible through the 'formatter_obj' of the object returned
  # by @getFriendlyArgs()
  #


  actions_buttons: default_buttons
  ext_actions_buttons: default_ext_buttons

  getAllActionsButtons: ->
    return @actions_buttons.concat(@ext_actions_buttons)

  getActionButtonDef: (action_name) ->
    all_actions_buttons = @getAllActionsButtons()

    return _.find all_actions_buttons, (i) -> i.action_name == action_name

  slickGridColumnStateMaintainer: ->
    if not Tracker.active
      @logger.warn "slickGridColumnStateMaintainer: called outside of computation, skipping"

      return

    # Create a dependency and depend on it.
    dep = new Tracker.Dependency()
    dep.depend()

    profile_date_format_computation = null
    Tracker.nonreactive =>
      # Run in an isolated reactivity scope
      profile_date_format_computation = Tracker.autorun =>
        current_val = JustdoHelpers.getUserPreferredDateFormat() # Reactive
        cached_val = @getCurrentColumnData("user_preferred_date_format") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("user_preferred_date_format", current_val)

          dep.changed()

        return

    Tracker.onInvalidate ->
      profile_date_format_computation.stop()

    return

  #
  # Formatters
  #
  slick_grid: ->
    friendly_args = @getFriendlyArgs()
    {formatter_obj, value, formatter_options} = friendly_args

    # We can't tell for sure whether slickGridColumnStateMaintainer is the
    # only one to affect the column cache, therefore, we don't rely on it
    # to set the value for us. We set the value ourself if we don't find one.
    if not (user_preferred_date_format = @getCurrentColumnData("user_preferred_date_format"))?
      user_preferred_date_format = Tracker.nonreactive => JustdoHelpers.getUserPreferredDateFormat.call(@)
      @setCurrentColumnData("user_preferred_date_format", user_preferred_date_format)

    unicode_date_string =
      JustdoHelpers.normalizeUnicodeDateStringAndFormatToUserPreference(value, user_preferred_date_format)

    formatter_content = ""
    content_empty = true
    if unicode_date_string != ""
      content_empty = false
      formatter_content += """
        #{unicode_date_string}
      """

    formatter_buttons = ""
    for action_button_def in formatter_obj.getAllActionsButtons()
      if not content_empty or action_button_def.show_if_empty
        # add the button only if the content isn't empty, or if it is
        # allowed to show it for non empty fields
        formatter_buttons += """
          <div class="udf-action-btn udf-id-#{action_button_def.action_name} slick-prevent-edit" title="#{action_button_def.action_title}">
        """

        if (icon_id = action_button_def.font_awesome_id)?
          formatter_buttons += """
            <i class="fa fa-fw fa-#{icon_id} slick-prevent-edit" aria-hidden="true"></i>
          """

        formatter_buttons += """
          </div>
        """

    custom_classes = ""
    if (customClasses = friendly_args.formatter_options?.customClasses)
      custom_classes = customClasses(friendly_args) or ""

    html_comment = undefined
    if (htmlCommentGenerator = friendly_args.formatter_options?.htmlCommentGenerator)
      html_comment = htmlCommentGenerator(friendly_args)

      if not _.isString(html_comment) or html_comment.trim() == ""
        html_comment = undefined

    comment_jd_tt = ""
    if html_comment?
       comment_jd_tt = """ jd-tt="html?tt-pos_my=left%20top&tt-pos_at=right%2B2px%20top&html=#{encodeURIComponent(html_comment)}" """

    formatter = """
      <div class="grid-formatter uni-date-formatter #{custom_classes}"#{comment_jd_tt}>
        #{formatter_content}#{formatter_buttons}#{if html_comment? then """<div class="comment-indicator">◥</div>""" else ""}
      </div>
    """

    return formatter

  #
  # Events
  #
  slick_grid_jquery_events: [
    {
      args: ["click", ".uni-date-formatter .udf-action-btn"]
      handler: (e) ->
        btn_class_name_prefix = "udf-id-"

        action_btn_classes =
          $(e.target).closest(".udf-action-btn").attr("class").split(" ")
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
    {formatter_obj, value} = @getFriendlyArgs()

    return JustdoHelpers.normalizeUnicodeDateStringAndFormatToUserPreference(value)

#
# EDITOR
#

# Check README.md to learn more about editors definitions

GridControl.installEditor "UnicodeDateEditor",
  actions_buttons: default_buttons
  ext_actions_buttons: default_ext_buttons

  init: ->
    $editor = $("""<div class="grid-editor unicode-date-editor" />""")

    @$input = $("""<input type="text" class="editor-unicode-date" placeholder="#{JustdoHelpers.getUserPreferredDataFormatInJqueryUiFormat()}" />""")

    $editor
      .html(@$input)
      .appendTo(@context.container);

    formatter_buttons_width = 0
    for action_button_def in @getAllActionsButtons()
      do (action_button_def) =>
        formatter_button = ""

        show_if_empty_class = if not action_button_def.show_if_empty then "udf-hidden-if-empty" else ""

        # add the button only if the content isn't empty, or if it is
        # allowed to show it for non empty fields
        formatter_button += """
          <div class="udf-action-btn udf-id-#{action_button_def.action_name} #{show_if_empty_class}" title="#{action_button_def.action_title}">
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

    @$input.datepicker
      dateFormat: JustdoHelpers.getUserPreferredDataFormatInJqueryUiFormat()
      showOn: "button"
      buttonImageOnly: true
      showAnim: ""
      firstDay: Meteor?.user()?.profile?.first_day_of_week or 0
      onSelect: => @saveAndExit()
      onClose: => @focus()

    @$input.width(@$input.width() - formatter_buttons_width - 3 - 1) # - 1 compensates the extra margin we add to .udf-id-date-setter only for editors (to have exact alignment with formatter)

    @$input.bind "keydown.nav", (e) ->
      # Prevent left/right arrows from propagating to avoid grid
      # navigation - they should be used for text navigation.
      if e.keyCode == $.ui.keyCode.LEFT or e.keyCode == $.ui.keyCode.RIGHT
        e.stopImmediatePropagation()

      return

    @$input.change =>
      if not @serializeValue()?
        $editor.addClass "udf-empty"
      else
        $editor.removeClass "udf-empty"

    @$input.change()

    return

  setInputValue: (val) ->
    if not val?
      val = null # val must be null to be interpreted as clear (undefined ignored)

    @$input.datepicker("setDate", JustdoHelpers.normalizeUnicodeDateStringAndFormatToUserPreference(val))
    @$input.change()

    return

  serializeValue: ->
    current_val = normalizeUserPreferenceDateFormatAndFormatToUnicodeDateString(@$input.val())

    if _.isEmpty(current_val)
      return null

    return current_val

  validator: (value) ->
    if value?
      if not moment(value, raw_data_moment_format, true).isValid()
        return "Invalid date"

    return undefined

  focus: ->
    @$input.focus()

    val = @$input.val()

    # try/catch required since IE11 fails when val.length == 0
    try
      # place the cursor in the end of the editor text
      # (instead of the default select-all on focus
      # behavior)
      @$input[0].setSelectionRange val.length, val.length
    catch e

    return

  destroy: ->
    @hidePicker()
    @$input.datepicker("destroy")
    @$input.remove()

    return

  #
  # Custom helpers
  #
  showPicker: ->
    @$input.datepicker("show")

  hidePicker: ->
    @$input.datepicker("hide")

  togglePicker: ->
    if $("#ui-datepicker-div").is(":visible")
      @hidePicker()
    else
      @showPicker()

  getAllActionsButtons: ->
    return @actions_buttons.concat(@ext_actions_buttons)

  moreInfoSectionCustomizations: ($firstNode, field_editor) ->
    $firstNode.find(".editor-unicode-date")
      .keydown (e) ->
        if e.which == 13
          field_editor.save()

          $(e.target).blur()

          return

        if e.which == 27
          field_editor.cancel()

          $(e.target).blur()

          return

      .blur (e) ->
        if not $("#ui-datepicker-div").is(":visible")
          field_editor.save()

        return

      .data().datepicker.settings.onSelect = ->
        field_editor.save()

        return

    return
