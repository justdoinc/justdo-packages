_.extend JustdoChecklist.prototype,
  _attachCollectionsSchemas: ->
    Schema =
      "p:checklist:is_checklist":
        label: "Is it a checklist"
        type: Boolean
        optional: true
        user_editable_column: true

      "p:checklist:is_checked":
        label: "checklist checked"
        type: Boolean
        optional: true
        user_editable_column: true

      "p:checklist:total_count":
        label: "number of leafs"
        type: Number
        optional: true

      "p:checklist:checked_count":
        label: "number of leafs"
        type: Number
        optional: true

      "p:checklist:has_partial":
        label: "has some check marks"
        type: Boolean
        optional: true

    @tasks_collection.attachSchema Schema

    return
