# Check README.md to learn more about editors definitions

GridControl.installEditor "TextareaEditor",
  init: ->
    @$input = $("""<textarea rows="1" />""")

    $editor = $("""<div class="grid-editor textarea-editor" />""")
    $editor.html(@$input).appendTo @context.container

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