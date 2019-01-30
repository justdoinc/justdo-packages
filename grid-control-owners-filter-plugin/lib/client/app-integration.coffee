# Add the project-owners-filter filter type to the title ("Subject") field
APP.executeAfterAppLibCode ->
  APP.collections.Tasks.attachSchema new SimpleSchema
    title:
      type: String
      grid_column_filter_settings:
        type: "owners-filter"
        options: {}

  return