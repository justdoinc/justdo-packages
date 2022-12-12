# Add the project-owners-filter filter type to the title ("Subject") field
APP.executeAfterAppLibCode ->
  APP.collections.Tasks.attachSchema new SimpleSchema
    title:
      type: String
      grid_column_filter_settings:
        type: "owners-filter"
        options:
          customQueryGenerator: (users_ids) ->
            query = {
              $or: [
                {owner_id: {$in: users_ids}},
                {pending_owner_id: {$in: users_ids}},
              ]
            }
            
            return query

    owner_id:
      type: String
      grid_column_filter_settings:
        type: "owners-filter"

    pending_owner_id:
      type: String
      grid_column_filter_settings:
        type: "owners-filter"

  return