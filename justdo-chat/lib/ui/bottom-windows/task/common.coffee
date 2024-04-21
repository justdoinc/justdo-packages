share.generateClientChannelObjectForTaskBottomWindowTemplates = (task_id) ->
  channel_conf =
    tasks_collection: APP.justdo_chat.bottom_windows_supplementary_pseudo_collections.tasks
    task_id: task_id

  channel_object =
    APP.justdo_chat.generateClientChannelObject "task", channel_conf

  return channel_object