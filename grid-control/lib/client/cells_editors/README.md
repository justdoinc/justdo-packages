Definning editors
=================

```coffeescript
GridControl.installEditor "CamelCaseEditorName",
  init: ->
    # Should be used to construct the editor DOM and DOM
    # behavior
    #
    # The editor dom element should be added to
    # @context.container

    return

  setInputValue: (val) ->
    # Called with the value of the editor upon:
    # * init (@doc set)
    # * @doc update
    # * When a custom code wants to show specific value
    #   on the field. (in which case val will be different
    #   from @getEditorFieldValueFromDoc())

    return

  serializeValue: ->
    # Get the value out of the editor, in the expected data
    # structure.
    #
    # Consider the default value when serializing empty editor
    # for example, if the default value for a field is undefined
    # (or not set at all), if the editor is empty its serialized
    # value should be undefined and not "", to avoid redundant
    # db update that replaces undefined with "".

    return current_val

  validator: (value) ->
    # Should return undefined if value is valid, string
    # with error message otherwise.
    #
    # Expect value to conform with @serializeValue() output
    # (but it doesn't necessary have to be the current value)
    #
    # We always check the value agains the schema definition
    # associated with this editor field, so if the schema checks
    # are sufficient, you don't need to define validator()

    # console.log "WHAT IS @context.column.validator?"
    # if _.isFunction @context.column.validator
    #   validation_results = @context.column.validator(@$input.val())
    #   if !validation_results.valid
    #     return validation_results.msg

    return undefined

  focus: ->
    # The algorithem to focus the input

    return

  destroy: ->
    # The algorithem to destroy the input

    return

```