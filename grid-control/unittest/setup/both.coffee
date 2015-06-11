Logger.useDefaults()

TestCollections = share.TestCollections =
  default:
    new Mongo.Collection "test-col"
  correct_defaults_set_for_visible_columns_of_type_string:
    new Mongo.Collection "correct-defaults-set-for-first-visible-column-of-type-string"

TestInvalidCollections = share.TestInvalidCollections =
  no_schema:
    new Mongo.Collection "no-schema"
  no_parents:
    new Mongo.Collection "no-parents"
  no_users:
    new Mongo.Collection "no-users"
  no_visible:
    new Mongo.Collection "no-visible"
  visible_users:
    new Mongo.Collection "visible-users"
  visible_parents:
    new Mongo.Collection "visible-parents"
  first_visible_column_not_of_grid_control_type:
    new Mongo.Collection "first-visible-column-not-of-grid-control-type"
  first_visible_column_not_default:
    new Mongo.Collection "first-visible-column-not-default"
  not_first_visible_column_is_of_grid_control_type:
    new Mongo.Collection "not-first-visible-column-is-of-grid-control-type"
  field_has_unknown_formatter:
    new Mongo.Collection "field-has-unknown-formatter"
  field_has_unknown_editor:
    new Mongo.Collection "field-has-unknown-editor"

TestCollections.default.attachSchema
  parents:
    label: "Parents"

    grid_visible_column: false

    type: Object

    blackbox: true

  users:
    label: "Users"

    grid_visible_column: false

    type: [String]

  title:
    label: "Title"

    grid_visible_column: true
    grid_editable_column: true
    grid_default_grid_view: true
    grid_default_width: 200

    type: String
    optional: true

TestCollections.correct_defaults_set_for_visible_columns_of_type_string.attachSchema
  parents:
    type: Object
    blackbox: true

  users:
    type: [String]

  f1:
    type: String
    grid_visible_column: true
    grid_default_grid_view: true
    grid_editable_column: true

  f2:
    type: String
    grid_visible_column: true
    grid_editable_column: true

  f3:
    type: String
    grid_visible_column: true
    grid_editable_column: false

  f4:
    type: String
    grid_visible_column: false
    grid_editable_column: false

TestInvalidCollections.no_parents.attachSchema
  users:
    label: "Users"

    type: [String]

  title:
    label: "Title"

    grid_visible_column: true
    grid_editable_column: true
    grid_default_grid_view: true

    type: String

TestInvalidCollections.no_users.attachSchema
  parents:
    label: "Parents"

    type: Object

    blackbox: true

  title:
    label: "Title"

    grid_visible_column: true
    grid_editable_column: true
    grid_default_grid_view: true

    type: String

  f1:
    type: String
    grid_visible_column: true
    grid_default_grid_view: true

TestInvalidCollections.no_visible.attachSchema
  parents:
    type: Object

    blackbox: true

  users:
    type: [String]

TestInvalidCollections.visible_users.attachSchema
  parents:
    type: Object

    blackbox: true

  users:
    grid_visible_column: true

    type: [String]

  f1:
    type: String
    grid_visible_column: true
    grid_default_grid_view: true

TestInvalidCollections.visible_parents.attachSchema
  parents:
    grid_visible_column: true

    type: Object

    blackbox: true

  users:
    type: [String]

  f1:
    type: String
    grid_visible_column: true
    grid_default_grid_view: true

TestInvalidCollections.first_visible_column_not_default.attachSchema
  parents:
    type: Object
    blackbox: true

  users:
    type: [String]

  f1:
    type: String
    grid_visible_column: true

TestInvalidCollections.first_visible_column_not_of_grid_control_type.attachSchema
  parents:
    type: Object
    blackbox: true

  users:
    type: [String]

  f1:
    type: String
    grid_visible_column: true
    grid_column_formatter: "defaultFormatter"
    grid_default_grid_view: true


TestInvalidCollections.not_first_visible_column_is_of_grid_control_type.attachSchema
  parents:
    type: Object
    blackbox: true

  users:
    type: [String]

  f1:
    type: String
    grid_visible_column: true
    grid_default_grid_view: true

  f2:
    type: String
    grid_visible_column: true
    grid_column_formatter: "textWithTreeControls"

TestInvalidCollections.field_has_unknown_formatter.attachSchema
  parents:
    type: Object
    blackbox: true

  users:
    type: [String]

  f1:
    type: String
    grid_visible_column: true
    grid_default_grid_view: true

  f2:
    type: String
    grid_visible_column: true
    grid_column_formatter: "tT"

TestInvalidCollections.field_has_unknown_editor.attachSchema
  parents:
    type: Object
    blackbox: true

  users:
    type: [String]

  f1:
    type: String
    grid_visible_column: true
    grid_default_grid_view: true

  f2:
    type: String
    grid_visible_column: true
    grid_editable_column: true
    grid_column_editor: "tT"