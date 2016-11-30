# Check README.md to learn more about editors definitions

GridControl.installEditor "UnicodeDateEditor",
  momentFormat: "YYYY-MM-DD"
  datepickerFormat: "yy-mm-dd"

  init: ->
    $editor = $("""<div class="grid-editor unicode-date-editor" />""")

    @$input = $("""<input type="text" class="editor-unicode-date" placeholder="yyyy-mm-dd" />""")

    $editor
      .html(@$input)
      .appendTo(@context.container);

    @$input.datepicker
      dateFormat: @datepickerFormat
      showOn: "button"
      buttonImageOnly: true
      buttonImage: "/packages/stem-capital_grid-control/lib/client/formatters-and-editors/unicode-date/media/calendar.gif"
      showAnim: ""
      beforeShow: => return
      onSelect: => @saveAndExit()
      onClose: =>
        @focus()

    @$input.width(@$input.width() - 18)

    @$input.bind "keydown.nav", (e) ->
      # Prevent left/right arrows from propagating to avoid grid
      # navigation - they should be used for text navigation.
      if e.keyCode == $.ui.keyCode.LEFT or e.keyCode == $.ui.keyCode.RIGHT
        e.stopImmediatePropagation()

      return

    return

  setInputValue: (val) ->
    @$input.datepicker("setDate", val)

    @focus()

    return

  serializeValue: ->
    current_val = @$input.val()

    if _.isEmpty(current_val)
      return null

    return current_val

  validator: (value) ->
    if value?
      if not moment(value, @momentFormat, true).isValid()
        return "Invalid date"

    return undefined

  focus: ->
    @$input.focus()

    val = @$input.val()
    # place the cursor in the end of the editor text
    # (instead of the default select-all on focus
    # behavior)
    @$input[0].setSelectionRange val.length, val.length

    return

  destroy: ->
    @$input.datepicker("hide")
    @$input.datepicker("destroy")
    @$input.remove()

    return