tags_properties =
  "start-date":
    text: "Start date bigger than end date"

    filter_list_order: 0

  "due-date":
    text: "Due date after end date"

    filter_list_order: 100

APP.justdo_task_type.registerTaskTypesGenerator "task-alerts", "core-issues",
  possible_tags: ["start-date"]

  required_task_fields_to_determine:
    "start_date": 1
    "end_date": 1

  generator: (task_obj) ->
    core_issues = []

    if task_obj["start_date"]? and task_obj["end_date"]?
      if task_obj["end_date"] < task_obj["start_date"]
        core_issues.push "start-date"

    return core_issues

  propertiesGenerator: (tag) -> tags_properties[tag]

APP.justdo_task_type.registerTaskTypesGenerator "task-alerts", "due-date",
  possible_tags: ["due-date"]

  required_task_fields_to_determine:
    "due_date": 1
    "end_date": 1

  generator: (task_obj) ->
    core_issues = []

    if task_obj["due_date"]? and task_obj["end_date"]?
      if task_obj["end_date"] < task_obj["due_date"]
        core_issues.push "due-date"

    return core_issues

  propertiesGenerator: (tag) -> tags_properties[tag]