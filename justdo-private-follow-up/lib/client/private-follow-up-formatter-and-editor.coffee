# If you change the suggestUndoClear update follow-up-formatter-and-editor.coffee as well
suggestUndoClear = (collection, doc_id, field_id, field_label, cleared_value) ->
  JustdoSnackbar.show
    text: "#{field_label} cleared"
    actionText: "Undo"
    onActionClick: =>
      undo_query = {$set: {}}
      undo_query["$set"][field_id] = cleared_value

      collection.update(doc_id, undo_query)

      JustdoSnackbar.close()

      return

  return

ext_actions_buttons = [
  {
      action_name: "private-followup-completed" # will be prefixed with "udf-id-" and set as a class
      width: 17
      action_title: "Private Follow Up Completed"
      action_formatter: (e, formatter_details) ->
        current_item_doc = @getCurrentPathObjNonReactive()
        current_item_id = current_item_doc._id

        cleared_value = current_item_doc[formatter_details.field_name]

        reset_query = {$set: {}}
        reset_query["$set"][formatter_details.field_name] = null

        @collection.update(current_item_id, reset_query)

        suggestUndoClear(@collection, current_item_id, formatter_details.field_name, formatter_details.column_field_schema?.label, cleared_value)

        return

      action_editor: (e, editor_object) ->
        cleared_value = editor_object.doc[editor_object.context?.field_name]

        editor_object.setInputValue(null)

        suggestUndoClear(editor_object.context?.grid_control?.collection, editor_object.context?.item?._id, editor_object.context?.field_name, editor_object.context?.field_schema?.label, cleared_value)

        editor_object.saveAndExit()

        return

      show_if_empty: false
      font_awesome_id: "check"
  }
]

GridControl.installFormatterExtension
  formatter_name: "unicodeDatePrivateFollowUpDateFormatter"
  extended_formatter_name: "unicodeDateFormatter"
  custom_properties: {
    ext_actions_buttons: ext_actions_buttons
  }

GridControl.installEditorExtension
  editor_name: "UnicodeDatePrivateFollowUpDateEditor"
  extended_editor_name: "UnicodeDateEditor"
  prototype_extensions: {
    ext_actions_buttons: ext_actions_buttons
    moreInfoSectionCustomizationsExtensions: ($firstNode, field_editor) ->
      $firstNode.find(".udf-id-private-followup-completed").click ->
        Meteor.defer ->
          field_editor.save()

          return

        return

      return
  }
