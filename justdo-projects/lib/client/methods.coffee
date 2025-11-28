_.extend Projects.prototype,
  # Put here methods that aren't project specific 
  createNewProject: (options, cb) ->
    self = @

    if not options?
      options = {}

    @emit "pre-create-new-project", options

    if Meteor.userId()?
      Meteor.call "createNewProject", options, (err, project_id) ->
        if not err?
          self.emit "post-create-new-project", project_id
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

  resendEnrollmentEmail: (project_id, invited_user_id, cb) ->
    Meteor.call "resendEnrollmentEmail", project_id, invited_user_id, cb

    return
  
  updateTaskDescriptionReadDate: (task_id, cb) ->
    Meteor.call "updateTaskDescriptionReadDate", task_id, cb

    return

  getRootTasksAndProjects: (project_id, options, cb) ->
    Meteor.call "getRootTasksAndProjects", project_id, options, cb

    return

  handleJdCreationRequest: (cb) ->
    if not Meteor.userId()?
      @logger.error("Login required to handle JD creation request")

    Meteor.call "handleJdCreationRequest", (err, created_project_id) ->
      cb(err, created_project_id)
      return
    
    return