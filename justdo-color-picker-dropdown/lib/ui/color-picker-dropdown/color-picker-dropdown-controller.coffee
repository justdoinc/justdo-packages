JustdoColorPickerDropdownControllerOptionsSchema = new SimpleSchema
  available_colors:
    type: [String]
    defaultValue: ["00000000", "ffffff", "d50001", "e57c73", "f4521e", "f6bf25", "33b679", "0a8043", "019be5", "3f51b5" ,"7986cb", "8d24aa", "616161", "4285f4", "000000"]

  default_color:
    type: String
    defaultValue: "00000000"

  label:
    type: String
    optional: true
    defaultValue: null

  opener_custom_class:
    type: String

    optional: true

JustdoColorPickerDropdownController = (options) ->
  EventEmitter.call this

  if not options?
    options = {}

  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      JustdoColorPickerDropdownControllerOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )
  @options = cleaned_val

  @_selected_color_rv = new ReactiveVar(@options.default_color or @options.available_colors[0])

  return @

Util.inherits JustdoColorPickerDropdownController, EventEmitter

_.extend JustdoColorPickerDropdownController.prototype,
  getSelectedColor: ->
    return @_selected_color_rv.get()

  setSelectedColor: (color) ->
    return @_selected_color_rv.set(color)
