JustdoChat.registerChannelType
  channel_type: "task" # Must be dash-separated! should be == @channel_type in client/server constructor
  channel_type_camel_case: "Task" # Should be the same as the camel case form used in the client/server constructors names

  channel_identifier_fields_simple_schema: new SimpleSchema # Read about the identifier fields on the comment for @getChannelIdentifier() under channel-base-client.coffee
    task_id:
      label: "Task id"

      type: String

  channel_augemented_fields_simple_schema: new SimpleSchema # Read about the identifier fields on the comment for @getChannelAugmentedFields() under channel-base-client.coffee
    project_id:
      label: "Project id"

      type: String
