APP.on "justdo-task-type-initiated", ->
  tags_properties =
    "project":
      text: "Project"
      text_i18n: "projects"

      filter_list_order: 0

      customFilterQuery: (filter_state_id, column_state_definitions, context) ->
        return {[JustdoDeliveryPlanner.task_is_project_field_name]: true, [JustdoDeliveryPlanner.task_is_archived_project_field_name]: {$ne: true}}
    "closed_project":
      text: "Closed Project"
      text_i18n: "closed_project_type_label"
      is_conditional: true

      filter_list_order: 1

      customFilterQuery: (filter_state_id, column_state_definitions, context) ->
        return {[JustdoDeliveryPlanner.task_is_project_field_name]: true, [JustdoDeliveryPlanner.task_is_archived_project_field_name]: true}

  possible_tags = []
  conditional_tags = []
  for tag_id, tag_def of tags_properties
    if tag_def.is_conditional
      conditional_tags.push tag_id
    else
      possible_tags.push tag_id

  APP.justdo_task_type.registerTaskTypesGenerator "default", "is-project",
    possible_tags: possible_tags
    conditional_tags: conditional_tags

    required_task_fields_to_determine:
      [JustdoDeliveryPlanner.task_is_project_field_name]: 1
      [JustdoDeliveryPlanner.task_is_archived_project_field_name]: 1

    generator: (task_obj) ->
      tags = []

      if task_obj[[JustdoDeliveryPlanner.task_is_project_field_name]] is true
        if task_obj[[JustdoDeliveryPlanner.task_is_archived_project_field_name]] is true
          tags.push "closed_project"
        else
          tags.push "project"
      
      return tags

    propertiesGenerator: (tag) -> tags_properties[tag]

  return