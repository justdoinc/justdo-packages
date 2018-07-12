_.extend JustdoChat.prototype,
  _setupJobs: ->
    @_setupUnreadChannelsNotificationsJobs()

    return

  _setupUnreadChannelsNotificationsJobs: ->
    for notification_type, conf of share.unread_channels_notifications_conf
      do (notification_type, conf) =>
        APP.justdo_jobs_processor.registerCronJob conf.justdo_jobs_processor_job_id, =>
          conf.job.apply(@, arguments)

          return
        , =>
          conf.stopJob.apply(@, arguments)

          return

    return
