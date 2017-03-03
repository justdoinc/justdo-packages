# Check README.md to learn more about editors definitions

GridControl.installEditor "TextareaEditor",
  init: ->
    @$input = $("""<textarea rows="1" class="mousetrap" />""")

    $wrapper = @generateInputWrappingElement()

    $wrapper.appendTo @context.container

    @$input.bind "keydown.nav", (e) ->
      # Prevent left/right arrows from propagating to avoid grid
      # navigation - they should be used for text navigation.
      if e.keyCode == $.ui.keyCode.LEFT or e.keyCode == $.ui.keyCode.RIGHT
        e.stopImmediatePropagation()

      return

    return

  setInputValue: (val) ->
    @$input.val(val)

    @focus()

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
    # place the cursor in the end of the editor text
    # (instead of the default select-all on focus
    # behavior)
    @$input[0].setSelectionRange val.length, val.length

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