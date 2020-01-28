# Check README.md to learn more about editors definitions

GridControl.installEditor "TextareaEditor",
  init: ->
    custom_style = ""

    if @context.schema.type is Number
      custom_style += " text-align: right;"
    else
      custom_style += " text-align: left;" # left is needed, since we user dir="auto" that affect direction in a way non desirable by us

    @$input = $("""<textarea dir="auto" rows="1" class="mousetrap" #{if custom_style != "" then " style=\"#{custom_style}\"" else ""} />""")

    $wrapper = @generateInputWrappingElement()

    $wrapper.appendTo @context.container

    @$input.bind "keydown.nav", (e) ->
      # Prevent left/right arrows from propagating to avoid grid
      # navigation - they should be used for text navigation.
      if e.keyCode == $.ui.keyCode.LEFT or e.keyCode == $.ui.keyCode.RIGHT
        e.stopImmediatePropagation()

      return

    return

  valueTransformation: (value) -> value

  setInputValue: (val) ->
    @$input.val(@valueTransformation(val))

    @$input.autosize()

    # if autosize already initiated for the element consecutive
    # calls to @$input.autosize() won't recalculate its height,
    # we must trigger the "autosize.resize" event to recalculate
    # the input size in that case.
    @$input.trigger("autosize.resize")

    return

  serializeValue: ->
    current_val = @$input.val()

    field_schema = @context.field_schema

    if field_schema.type is Number
      # By default, Number fields in simple schema are restricted to
      # integers values (floats will result in validation error).
      #
      # That behavior can change to allow float by setting the:
      # `decimal: true` option.
      #
      # We parse the text value accordingly:
      if field_schema.decimal
        current_val = parseFloat(current_val)
      else
        current_val = parseInt(current_val, 10)

      if _.isNaN(current_val)
        # Consider as empty value if null values allowed for this field
        # (`optional: true` in the field simple schema). Otherwise, set
        # to 0
        if field_schema.optional
          return null
        else
          return 0

    else
      # _.isEmpty will always return true for Numbers, relevant
      # only when working with strings
      if _.isEmpty(current_val)
        return null

    return current_val

  validator: (value) ->
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
    @$input.remove()

    return

  #
  # Custom helpers
  #
  generateInputWrappingElement: ->
    # Separate the wrapping element generator, to allow its replacement
    # by inheriting editors (see TextareaWithTreeControlsEditor for example)
    $wrapper = $("""<div class="grid-editor textarea-editor" />""")
    $wrapper.html(@$input)

    return $wrapper


  moreInfoSectionCustomizations: ($firstNode, field_editor) ->
    $firstNode.find("textarea")
      .keydown (e) ->
        if e.which == 13 and not e.shiftKey
          field_editor.save()

          $(e.target).blur()

          return

        if e.which == 27
          field_editor.cancel()

          $(e.target).blur()

          return

      .blur (e) ->
        field_editor.save()

      return