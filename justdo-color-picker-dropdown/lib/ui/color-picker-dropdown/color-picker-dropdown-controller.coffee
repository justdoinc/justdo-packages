JustdoColorPickerDropdownControllerOptionsSchema = new SimpleSchema
  available_colors:
    type: [String]
    defaultValue: [
      "00000000", "ffffff", "90a4ae", "455a64", "37474f", "000000",
      "f44336", "ffcdd2", "fb9797", "d32f2f", "b71c1c", "6f0505",
      "9D4EDD", "E0AAFF", "C77DFF", "7B2CBF", "5A189A", "3C096C",
      "3f51b5", "c5cae9", "7986cb", "303f9f", "1a237e", "080f5d",
      "03a9f4", "b3e5fc", "4fc3f7", "0288d1", "01579b", "023d6b",
      "2dca33", "CCFF33", "9EF01A", "38B000", "008000", "006400",
      "FFD000", "FFEA00", "FFDD00", "FFB700", "FFA200", "de7702",
      "FC8E4A", "FED9C2", "FDB486", "FB690E", "C94F03", "8D3702"
    ]

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
