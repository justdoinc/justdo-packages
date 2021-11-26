tags_properties =
  "project":
    text: "Project"

    filter_list_order: 0

    customFilterQuery: (filter_state_id, column_state_definitions, context) ->
      return {"p:dp:is_project": true}

APP.justdo_task_type.registerTaskTypesGenerator "default", "is-project",
  possible_tags: ["project"]

  required_task_fields_to_determine:
    "p:dp:is_project": 1

  generator: (task_obj) ->
    tags = []

    if task_obj["p:dp:is_project"] is true
      tags.push "project"
    
    return tags

  propertiesGenerator: (tag) -> tags_properties[tag]
