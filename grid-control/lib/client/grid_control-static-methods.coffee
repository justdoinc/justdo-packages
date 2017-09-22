GridControl.getDefaultFormatterAndEditorForType = (type) ->
  # Set default formatter/editor according to field type

  # Note, the following serves as the defaults if the type provided is not
  # present in the following if/else
  formatter = "defaultFormatter"
  editor = "TextareaEditor"

  if type is String
    formatter = "defaultFormatter"
    editor = "TextareaEditor"
  if type is Date
    formatter = "unicodeDateFormatter"
    editor = "UnicodeDateEditor"
  if type is Boolean
    formatter = "checkboxFormatter"
    editor = "CheckboxEditor"

  return {formatter, editor}