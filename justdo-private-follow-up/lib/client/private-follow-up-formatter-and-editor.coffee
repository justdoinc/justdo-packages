ext_actions_buttons = [
  {
      action_name: "private-followup-completed" # will be prefixed with "udf-id-" and set as a class
      width: 17
      action_title: "Private Follow Up Completed"
      action_formatter: (e, formatter_details) ->
        current_item_id = @getCurrentPathObjNonReactive()._id

        reset_query = {$set: {}}
        reset_query["$set"][formatter_details.field_name] = null

        this.collection.update(current_item_id, reset_query)

        return

      action_editor: (e, editor_object) ->
        editor_object.setInputValue(null)

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
