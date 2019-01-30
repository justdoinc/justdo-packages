JustdoDeliveryPlanner.schemas = {}

JustdoDeliveryPlanner.schemas.MemberAvailabilitySchema = new SimpleSchema
  user_id:
    label: "User ID"

    type: String

  availability_type:
    label: "Member availability type"

    type: String

    # If simple is set, only the fields prefixed with "simple_" will be regarded in computations
    # If extended is set, only the fields prefixed with "extended_" will be regarded in computations
    allowedValues: ["simple", "extended"]

  simple_daily_availability:
    # In seconds
    label: "Simple daily availability"

    type: Number

    optional: true

  extended_daily_availability:
    # In seconds
    label: "Extended daily availability"

    type: [Number]

    optional: true

  extended_daysoff_ranges:
    # Dates in ISO 8601 date format

    label: "Extended day offs"

    type: [[String, String]]

    optional: true

_.extend JustdoDeliveryPlanner.prototype,
  _attachCollectionsSchemas: ->
    Schema =
      "#{JustdoDeliveryPlanner.task_is_project_field_name}":
        label: "Deliver planner :: is project"

        grid_editable_column: false
        grid_visible_column: false

        type: Boolean
        optional: true

      "#{JustdoDeliveryPlanner.task_is_archived_project_field_name}":
        label: "Deliver planner :: is project archived"

        grid_editable_column: false
        grid_visible_column: false

        type: Boolean
        optional: true

      "#{JustdoDeliveryPlanner.task_project_members_availability_field_name}":
        label: "Deliver planner :: members availability"

        grid_editable_column: false
        grid_visible_column: false

        type: [JustdoDeliveryPlanner.schemas.MemberAvailabilitySchema]
        optional: true

      "#{JustdoDeliveryPlanner.task_baseline_projection_data_field_name}":
        label: "Deliver planner :: baseline projection data"

        grid_editable_column: false
        grid_visible_column: false

        type: Object
        blackbox: true
        optional: true

      "#{JustdoDeliveryPlanner.task_base_project_workdays_field_name}":
        label: "Deliver planner :: base project workdays"

        grid_editable_column: false
        grid_visible_column: false

        type: [Number] # 0 is sunday, 6 is saturday
        optional: true

      "#{JustdoDeliveryPlanner.task_is_committed_field_name}":
        label: "Deliver planner :: is project committed"

        grid_editable_column: false
        grid_visible_column: false

        type: Boolean
        optional: true

    @tasks_collection.attachSchema Schema

    return