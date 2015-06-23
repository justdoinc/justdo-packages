SimpleSchema.extendOptions
  # grid_visible_column:
  #
  # If true, allow presenting the field's data in a grid's column.
  #
  # Important 1: at least one field should have this option set to true.
  # Important 2: `parents and `users` fields can't have this option set to true.
  #
  # If undefined considered as false
  grid_visible_column: Match.Optional(Boolean)

  # grid_editable_column:
  #
  # If true, allow editing this field using slick grid editor 
  #
  # If grid_editable_column option is false this option has no effect
  #
  # If undefined considered as false
  grid_editable_column: Match.Optional(Boolean)

  # grid_default_grid_view:
  #
  # If true, a column for this field will be added if the user didn't
  # define a grid view (part of the default grid view).
  #
  # Ignored for fields that aren't visible
  #
  # Important: Since the first visible field has a special meaning (it holds the grid controls),
  # it must be default.
  #
  # If undefined considered as false
  grid_default_grid_view: Match.Optional(Boolean)

  # grid_default_width:
  #
  # Width in the default grid-view.
  #
  # If undefined, SlickGrid defaults' are used
  grid_default_width: Match.Optional(Number)

  # grid_content_type and grid_column_editor defaults:
  #
  # The `type` option of a field affects the default formatter and editor
  # we use for that column cell (the grid_column_formatter and grid_column_editor
  # options) in the following way:
  #
  # Default grid_column_formatter is set only for visible fields
  # and default grid_column_editor is set only for editable fields.
  #
  # Defaults are currently defined for fields of type: String, Date, Boolean
  #
  # Fields of types that default editor/formatter weren't set for
  # will be treated as: String
  #
  #
  # Defaults by type:
  # String:
  #   If first column:
  #     grid_column_formatter: "textWithTreeControls"
  #     grid_column_editor: "TextWithTreeControlsEditor"
  #   Else:
  #     grid_column_formatter: "defaultFormatter" # slick grid default.
  #     grid_column_editor: "TextEditor"
  #
  # Date:
  #   If first column:
  #     grid_column_formatter: "textWithTreeControls"
  #     grid_column_editor: "TextWithTreeControlsEditor"
  #   Else:
  #     grid_column_formatter: "unicodeDateFormatter"
  #     grid_column_editor: "UnicodeDateEditor"
  #
  # Boolean:
  #   If first column:
  #     grid_column_formatter: "textWithTreeControls"
  #     grid_column_editor: "TextWithTreeControlsEditor"
  #   Else:
  #     grid_column_formatter: "checkboxFormatter"
  #     grid_column_editor: "checkboxEditor"

  # grid_column_formatter:
  #
  # Sets the formatter for the column.
  #
  # Formatter name should be the key given to that formatter in PACK.Formatters object.
  # See /grid-control/lib/client/cells_formatters folder.
  #
  # The first defined visible column (first visible field in schema definition) must
  # be one that has tree control as defined in the "PACK.TreeControlFormatters" list
  # defined under /grid-control/client/cells_formatters/tree_control_formatter.coffee.
  # The rest of the columns should not have tree control (will throw error)
  #
  # If undefined in visible field will be set according to type option as defined above.
  grid_column_formatter: Match.Optional(String)

  # grid_column_editor:
  #
  # Sets the editor for the column. (Ignored if grid_editable_column is true for that field).
  #
  # Editor name should be the key given to that editor in PACK.Editors object.
  #
  # See /grid-control/lib/client/cells_editors foleder.
  #
  # If undefined in visible and editable field will be set according to type option as defined above.
  grid_column_editor: Match.Optional(String)

  # grid_effects_metadata_rendering:
  #
  # If true, changes made to that field will trigger re-rendering of the entire row
  # that holds it.
  #
  # If undefined considered as false
  grid_effects_metadata_rendering: Match.Optional(Boolean) # if set and is true, edits specific to this cell will trigger re-rendering of the entire row

  # grid_values:
  #
  # Specify possible values and their labels (Used by some formatters/editors).
  #
  # Format:
  # {
  #   value: "Label"
  # }
  #
  # Alternatively you can specify a function that get the current grid_control as
  # its fisrt argument parameter and returns an object of the above format.
  #
  # function (grid_control) {
  #   return {value: "Label"};
  # }
  #
  # XXX not implemented
  # XXX If the function is a reactive resource editors/formatters that uses it should react
  # XXX to changes upon invalidation.
  #
  # Note: this option is in use by some of the editors/formatters it has no effect otherwise.
  #
  # If relevant to the current field editor/formatter and is undefined considered as an empty object.
  grid_values: Match.Optional(Match.OneOf(Function, Object))