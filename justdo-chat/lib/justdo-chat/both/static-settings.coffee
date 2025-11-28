jdc_recent_activity_supplementary_pseudo_collections_prefix = "JDChatRecentActivity"
jdc_bottom_windows_supplementary_pseudo_collections = "JDChatBottomWindows"

_.extend JustdoChat,
  jdc_info_pseudo_collection_name: "JDChatInfo"

  notification_registrar_type: "justdo_chat"

  jdc_recent_activity_supplementary_pseudo_collections_prefix: jdc_recent_activity_supplementary_pseudo_collections_prefix
  jdc_recent_activity_channels_collection_name: "#{jdc_recent_activity_supplementary_pseudo_collections_prefix}Channels"
  jdc_recent_activity_messages_collection_name: "#{jdc_recent_activity_supplementary_pseudo_collections_prefix}Messages"
  jdc_recent_activity_authors_details_collection_name: "#{jdc_recent_activity_supplementary_pseudo_collections_prefix}AuthorsDetails"

  jdc_bottom_windows_supplementary_pseudo_collections: jdc_bottom_windows_supplementary_pseudo_collections
  jdc_bottom_windows_channels_collection_name: "#{jdc_bottom_windows_supplementary_pseudo_collections}Channels"

  jdc_channel_messages_authors_details_collection_name: "JDChatChannelMessagesAuthorsDetails"

  jdc_bots_info_collection_name: "JDChatBotsInfo"

  bot_user_id_prefix: "bot:"

  tasks_chat_channel_last_read_field_id: "priv:p:chat:last_read"
  tasks_chat_channel_last_message_from_field_id: "p:chat:last_message_from"
  tasks_chat_channel_last_message_date_field_id: "p:chat:last_message_date"

  # As of MongoDB 4.4, it's 
  # 1. illegal to specify positional operator in the middle of a path.
  #    Positional projection may only be used at the end, for example: a.b.$.
  #    If the query previously used a form like a.b.$.d, remove the parts following the '$' and the results will be equivalent.
  # 2. illegal to project an embedded document with any of the embedded document’s fields (e.g. {"a.b": 1, "a.b.$": 1}).")
  # This regex used to detect and replace these cases.
  positional_operator_regex: /\.\$(\..*)?/

  files_supported_channel_types: ["task"]
  
  inline_previewable_file_categories: [
    "image"
    "video"
    "pdf"
  ]

