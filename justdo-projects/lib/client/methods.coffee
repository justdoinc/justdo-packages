_.extend Projects.prototype,
  # Put here methods that aren't project specific 
  createNewProject: (options, cb) ->
    if not options?
      options = {}

    @emit "pre-create-new-project", options

    if Meteor.userId()?
      Meteor.call "createNewProject", options, (err, project_id) ->
        cb(err, project_id)
    else
      @logger.error("Login required in order to create a new project")

  postRegInit: (cb) ->
    if not Meteor.userId()?
      @logger.error("Login required in order to create a new project")

    Meteor.call "postRegInit", (err, initiation_report) ->
      cb(err, initiation_report)

  configureProject: (project_id, conf, cb) ->
    if not Meteor.userId()?
      @logger.error("Login required in order to create a new project")

    Meteor.call "configureProject", project_id, conf, (err) ->
      cb(err)

  configureEmailUpdatesSubscriptions: (projects_ids, set_subscription_mode=true, cb) ->
    # set_subscription_mode should be true if you want to subscribe, false
    # to unsubscribe

    if not Meteor.userId()?
      @logger.error("Login required in order subscribe/unsubscribe project's daily updates")

    Meteor.call "configureEmailUpdatesSubscriptions", projects_ids, set_subscription_mode, (err) ->
      cb?(err)

    return

  configureEmailNotificationsSubscriptions: (projects_ids, set_subscription_mode=true, cb) ->
    # set_subscription_mode should be true if you want to subscribe, false
    # to unsubscribe

    if not Meteor.userId()?
      @logger.error("Login required in order subscribe/unsubscribe project emails notifications")

    Meteor.call "configureEmailNotificationsSubscriptions", projects_ids, set_subscription_mode, (err) ->
      cb?(err)

    return

  resendEnrollmentEmail: (project_id, invited_user_id, cb) ->
    Meteor.call "resendEnrollmentEmail", project_id, invited_user_id, cb

    return
  
  updateTaskDescriptionReadDate: (task_id, cb) ->
    Meteor.call "updateTaskDescriptionReadDate", task_id, cb

    return

  getRootTasksAndProjects: (project_id, options, cb) ->
    Meteor.call "getRootTasksAndProjects", project_id, options, cb

    return
