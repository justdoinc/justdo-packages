system_update_options_schema = new SimpleSchema
  update_id:
    type: String

  template:
    type: String

  title:
    type: String

    defaultValue: "System Update"

  show_to_users_registered_before:
    type: Date

    optional: true

    # if null will show to all existing users and following user registration
    defaultValue: null

_.extend JustdoSystemUpdates,
  systemUpdateExists: (update_id) ->
    return APP.justdo_crm.getItemByIdOrAlias("news", update_id)?
