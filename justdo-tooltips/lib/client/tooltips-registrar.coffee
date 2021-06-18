_.extend JustdoTooltips.prototype,
  _registerTooltipOptionsSchema: new SimpleSchema
    id:
      type: String

    template:
      type: String

      custom: ->
        if not Template[@value]?
          return "Unknown template provided"

        return undefined

    raw_default_options:
      type: Object

      blackbox: true

      defaultValue: {}

      custom: ->
        for option, val of @value
          if not _.isString val
            return throw new Error("All default options values must be Strings")

        return

    rawOptionsLoader:
      type: Function

      defaultValue: (raw_options) ->
        return raw_options

    display_delay:
      type: Number

      defaultValue: JustdoTooltips.delay_before_showing_tooltip

      optional: true

    hide_delay:
      type: Number

      defaultValue: JustdoTooltips.delay_before_hiding_tooltip

      optional: true

    pos_my:
      type: String
      
      defaultValue: "left top"

      optional: true

    pos_at:
      type: String
      
      defaultValue: "left bottom+2px"

      optional: true

    pos_collision:
      type: String
      
      defaultValue: "flip flip"

      optional: true

  registerTooltip: (options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerTooltipOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    @registered_tooltips[options.id] = options

    return
