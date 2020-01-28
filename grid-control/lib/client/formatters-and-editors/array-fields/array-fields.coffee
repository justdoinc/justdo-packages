GridControl.installFormatterExtension
  formatter_name: "arrayDefaultFieldFormatter"
  extended_formatter_name: "defaultFormatter"
  custom_properties: {
    valueTransformation: (value) ->
      if _.isArray(value)
        return value.join(", ")
      else
        return value
  }

GridControl.installEditorExtension
  editor_name: "ArrayCSVEditor"
  extended_editor_name: "TextareaEditor"
  prototype_extensions:
    valueTransformation: (value) ->
      if not value?
        return value

      return value.join(", ")
    isValueChanged: ->
      field_doc_value = @getEditorFieldValueFromDoc()

      if field_doc_value?
        return EJSON.stringify(field_doc_value) != EJSON.stringify(@serializeValue())
      else
        # If field_doc_value is undefined/null in the document
        # consider it changed only if @serializeValue() is defined
        return @serializeValue()?
    serializeValue: ->
      field_schema = @context.field_schema
      array_items_type = field_schema.type?[0] or String

      current_val = @$input.val()

      if not current_val? or _.isEmpty(current_val)
        return []

      return _.compact(current_val.split(/\s*,\s*/)).map(array_items_type)