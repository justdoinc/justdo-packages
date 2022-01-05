APP.on "justdo-task-type-initiated", ->
  tags_properties =
    "no-owner":
      text: "No Owner"

      filter_list_order: 90

      customFilterQuery: (filter_state_id, column_state_definitions, context) ->
        return {is_removed_owner: true}

  APP.justdo_task_type.registerTaskTypesGenerator "default", "no-owner",
    possible_tags: []

    conditional_tags: ["no-owner"]

    required_task_fields_to_determine:
      is_removed_owner: 1

    generator: (task_obj) ->
      tags = []

      if task_obj.is_removed_owner is true
        tags.push "no-owner"

      return tags

    propertiesGenerator: (tag) -> tags_properties[tag]

  return
