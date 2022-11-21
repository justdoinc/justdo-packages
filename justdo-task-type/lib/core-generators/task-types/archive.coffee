APP.on "justdo-task-type-initiated", ->
  tags_properties =
    "archived":
      text: "Archived"

      filter_list_order: 1

      customFilterQuery: (filter_state_id, column_state_definitions, context) ->
        return {archived: {$ne: null}}

  APP.justdo_task_type.registerTaskTypesGenerator "default", "is-archived",
    possible_tags: ["archived"]

    required_task_fields_to_determine:
      archived: 1

    generator: (task_obj) ->
      tags = []

      if _.isDate task_obj.archived
        tags.push "archived"

      return tags

    propertiesGenerator: (tag) -> tags_properties[tag]

  return
