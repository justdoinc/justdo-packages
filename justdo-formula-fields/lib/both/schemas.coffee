_.extend JustdoFormulaFields.prototype,
  _attachCollectionsSchemas: ->
    @_attachFormulasCollectionSchema()

    return

  _attachFormulasCollectionSchema: ->
    Schema =
      "project_id":
        type: String

        label: "Project ID"

      "custom_field_id":
        type: String

        label: "Custom field ID"

      "formula":
        type: String

        label: "Formula"

        optional: true

      "formula_field_updated_at":
        type: Date

        label: "Formula field updated at"

      "formula_field_edited_by":
        type: String

        label: "Formula field updated at"

      "formula_dependent_fields_object": # to avoid the need to process
        type: Object

        label: "Fields involved in formula"

        blackbox: true

        optional: true

      "formula_dependent_fields_array": # to avoid the need to process
        type: [String]

        label: "Fields involved in formula"

        optional: true

      "defect_found":
        type: Boolean

        label: "Defect found"

      "defect_cause":
        type: String

        label: "Defect cause"

        optional: true

      "project_removed":
        type: Boolean

        label: "Project removed"

      "plugin_disabled":
        type: Boolean

        label: "Plugin disabled"

      "formula_field_removed":
        type: Boolean

        label: "Formula Field removed"

    @formulas_collection.attachSchema Schema

    return