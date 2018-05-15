JustdoChat.registerUnreadChannelsNotificationsManager
  notification_type: "email" # Must be dash-separated!
  polling_interval_ms: 1000 * 60 # 1 min
  min_unread_period_ms: 1000 * 60 * 7.5 # 7.5 min
  is_user_configurable_notification: true
  user_configuration_field_type: String
  user_configuration_field_allowedValues: ["off", "twice-daily", "once-per-unread"]
  user_configuration_field_defaultValue: "once-per-unread" # If you change the default here, you must update
                                                           # code on: 
  user_configuration_field_enabled_value: "once-per-unread"

  new_subscribers_notifications: true
  new_subscribers_notifications_threshold_ms: 1000 * 60 * 10
  new_subscribers_notifications_max_messages: 10

  sendNotificationCb: (notification_obj) ->
    {user, channel_obj, channel_type, job_storage} = notification_obj

    if channel_type != "task"
      console.warn "JustdoChat: email-unread-notifications: unsupported channel type for emails notification: #{channel_type}"

      return

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

    base_url = JustdoHelpers.getProdUrl("web-app")

    template_data =
      user: user
      project_doc: project_doc
      task_doc: task_doc

      read_link: "#{base_url}/p/#{project_id}#&t=main&p=/#{task_doc._id}/&ref=chat-mail"

      unsubscribe_link: "#{base_url}/#?hr-id=unsubscribe-c-iv-unread-emails-notifications"

    to = user.emails[0].address

    JustdoEmails.buildAndSend
      template: "notifications-iv-unread-chat"
      template_data: template_data
      to: to
      subject: "New messages are waiting under #{project_doc.title} - ##{task_doc.seqId}: #{JustdoHelpers.ellipsis(task_doc.title or "", 60)}"

    return