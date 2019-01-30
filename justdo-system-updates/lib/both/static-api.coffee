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
  system_updates: {}

  registerSystemUpdate: (options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        system_update_options_schema,
        options,
        {self: @, throw_on_error: true}
      )

    options = cleaned_val

    JustdoSystemUpdates.system_updates[options.update_id] = options

    return

  systemUpdateExists: (update_id) -> JustdoSystemUpdates.system_updates[update_id]?
