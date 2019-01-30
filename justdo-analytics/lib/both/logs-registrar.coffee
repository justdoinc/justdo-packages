LogsRegistrarActionSchema = JustdoAnalytics.schemas.LogsRegistrarActionSchema
LogsRegistrarActionsSchema = JustdoAnalytics.schemas.LogsRegistrarActionsSchema

{symbols_regex, category_max_length} = JustdoAnalytics.schemas_consts

# Note, static object
JustdoAnalytics.logs_index = {}

# Note, all static methods
_.extend JustdoAnalytics,
  registerLogs: (category, actions) ->
    if not category?
      throw new Meteor.Error "missing-argument", "category"

    if category.length > category_max_length
      throw new Meteor.Error "invalid-argument", "Category `#{category}` length is longer than the max: #{max_category_length}"

    if not symbols_regex.test(category)
      throw new Meteor.Error "invalid-argument", "Category `#{category}` must be dash separated all-lower cased"

    # Construct temporarily so we can validate using simple schema.
    actions = {
      actions: actions
    }
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        LogsRegistrarActionsSchema,
        actions,
        {self: @, throw_on_error: true}
      )
    actions = cleaned_val.actions

    if category not of @logs_index
      @logs_index[category] = {}

    for action in actions
      if @logs_index[category][action.action_id]?
        throw new Meteor.Error("action-definition-already-exists", "Action definition #{category}::#{action.action_id} already exists")

      log_def = {
        description: action.description
      }

      if (classes = action.classes)?
        log_def.classes = classes

      @logs_index[category][action.action_id] = log_def

    return

