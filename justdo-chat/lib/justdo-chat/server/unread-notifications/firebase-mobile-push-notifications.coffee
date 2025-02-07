if APP.justdo_push_notifications.isFirebaseEnabled()
  JustdoChat.registerUnreadChannelsNotificationsManager
    notification_type: "firebase-mobile" # Must be dash-separated!
    polling_interval_ms: 1000 # 1 second
    min_unread_period_ms: 1000 * 3 # 3 second
    is_user_configurable_notification: false

    # At the moment, the following aren't in use! Ignore!
    new_subscribers_notifications: true
    new_subscribers_notifications_threshold_ms: 1000 * 60 * 10
    new_subscribers_notifications_max_messages: 10

    sendNotificationCb: (notification_obj) ->
      {user, channel_obj, channel_type, job_storage} = notification_obj

      if channel_type not in APP.justdo_chat.getSupportedChannelTypes()
        console.warn "JustdoChat: firebase-mobile-unread-notifications: unsupported channel type for firebase-mobile notification: #{channel_type}"

        return
      
      options = 
        message_type: "unread-chat"
        recipients_ids: [user._id]
        networks: ["mobile"]
        data:
          channel_type: channel_type
          channel_id: channel_obj.getChannelDocNonReactive()._id

      if channel_type is "task"
        task_doc = channel_obj.getIdentifierTaskDoc() # Cached, don't worry

        if not job_storage.projects_docs_cache?
          job_storage.projects_docs_cache = {}

        # Multiple task channels might share the same project, we don't want it to be queryied more than once.
        # hence, we keep it in the job_storage to request it only once for this job run.
        if (project_id = channel_obj.getIdentifierProjectId()) of job_storage.projects_docs_cache
          project_doc = job_storage.projects_docs_cache[project_id]
        else
          project_doc = channel_obj.getIdentifierProjectDoc()

          job_storage.projects_docs_cache[project_id] = project_doc

        options.body = "New chat message re: \r\n #{JustdoHelpers.ellipsis(task_doc.title, 70)}"
        options.data.project_id = project_doc._id
        options.data.task_id = task_doc._id
      
      if channel_type is "user"
        sender_display_name = JustdoHelpers.displayName channel_obj.getCounterpartUser()
        options.body = "New chat message from #{sender_display_name}"

      # APP.justdo_push_notifications.pnUsersViaFirebase
      #   message_type: "chat-msg"

      #   # title: "New chat message received"

      #   body: "New message - ##{task_doc.seqId}: #{JustdoHelpers.ellipsis task_doc.title, 80} :: #{project_doc.title}"

      #   recipients_ids: [user._id]

      #   networks: ["mobile"]

      #   data:
      #     channel_type: channel_type
      #     channel_id: channel_obj.getChannelDocNonReactive()._id
      #     project_id: project_doc._id
      #     task_id: task_doc._id


      APP.justdo_push_notifications.pnUsersViaFirebase options

      return