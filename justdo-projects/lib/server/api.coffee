_ = lodash

Fiber = Npm.require "fibers"

# Allowed confs is an object shared by all the created Projects
# objects, it strictly defines which settings can be set to the
# conf sub-document of the projects collection (we make it strict
# for mongo injections concerns).
#
# Plugins developers can add more confs definitions by calling
# Projects.registerAllowedConfs().
#
# Once a conf is added to allowed_confs, we won't allow overriding
# it.
#
# The confs below are the built-in confs.
#
# built-in confs definitions moved to the justdoinc:justdo-core-project-configurations
# package
#
# new_members_invites_proxy kept here, since we don't want to expose it yet.
# (justdo-core-project-configurations code is shared with sdk developers)
allowed_confs = {
  # structure:
  #   admin_allowed_to_set: true/false
  #
  #     if false, only super admin are allowed to set.
  #
  #   value_matcher: RegExp/Matcher # regexp or Matcher
  #   validator: function # optional, function that will
  #                         get as its first parameter the value conf
  #                         value and should return true if the value
  #                         is permitted. It's ok to raise exception
  #                         if value is not permitted, or just return
  #                         false, in which case, we'll take care of
  #                         raising validation-error.
  #                         validator is called with the value only after
  #                         `value_matcher` and `allow_change` were checked.
  #                         inside the validator @ is the Projects instance. 
  #   allow_change: true/false # Whether value can be changed once set
  #   allow_unset: true # Whether value can be unset, ignored if allow_change
  #                     # is false

  new_members_invites_proxy:
    # If set, we will send the notifications about addition
    # to the project to new members (both registered and
    # unregistered) to the email set in its value, instead
    # of the new member's email
    admin_allowed_to_set: true
    value_matcher: JustdoHelpers.common_regexps.email
    allow_change: true
    allow_unset: true
} 

Projects.registerAllowedConfs = (confs) ->
  # Confs need to be an object whose array are corresponding to the setting-ids
  # you want to register and their values are the setting definition, as defined
  # above.

  for setting_key, setting_def of confs
    if setting_key of allowed_confs
      throw Error("Projects.registerAllowedConfs: can't register same project conf setting more than once: #{setting_key} already defined")

    allowed_confs[setting_key] = setting_def

  return

_.extend Projects.prototype,
  #
  # Project membership verification requirement management
  #
  skipMemberVerification: (cb) ->
    Fiber.current.skip_member_verification = true
    cb()
    delete Fiber.current.skip_member_verification

  isMemberVerificationRequired: -> Fiber.current.skip_member_verification isnt true

  #
  # Login/Membership/Admin checks
  #
  requireLogin: (user_id) ->
    if not user_id?
      throw @_error "login-required"

    check(user_id, String)

    return true

  createUser: (options, inviting_user_id) ->
    # Creates a user and initiate it
    #
    # Notes:
    #
    #   * existence of inviting_user_id won't be checked
    #
    #   * options are the same options expected by JustdoAccounts.createUser with
    #     the following extensions/changes:
    # 
    #       * init_first_project (bool, false by default): if true, we will add
    #         a project for the created user in which he is the manager.
    #
    #   * options.profile, option, if exists, will have to comply with JustdoAccounts.user_profile_schema
    #
    # Returnes the created user id.

    created_user_id =
      @justdo_accounts.createUser(options, inviting_user_id)

    if options.init_first_project
      @createNewProject({}, created_user_id)

    return created_user_id

  projectMembershipTracker: (project_id, user_id, tracker_handlers) ->
    # returns a tracker that calls the `added` tracker handler once user belongs
    # to project_id.
    # Once user removed from the project it'll call the `removed` tracker handler.
    projects_query =
      _id: project_id
      "members.user_id": user_id

    return @projects_collection.find(projects_query, {fields: {_id: 1}}).observeChanges tracker_handlers

  projectMembershipRequirementPubManager: (publication_this, project_id, callbacks) ->
    # Manages a publication that requires @userId to belong to project_id.
    #
    # * Calls callbacks.success if user_id is member of project_id.
    # * Sends error message to subscription if user isn't logged-in.
    # * Sends error message to subscription if user isn't member of project_id.
    # * Stops the subscription as soon as user_id stop being member of project_id.
    # * Stops the membership tracker onStop and calls callbacks.stop()
    #
    # Returns the membership tracker, note that this method takes care of stopping
    # it upon publication's @onStop 
    #
    # callbacks.success and callbacks.stop are being called with publication's @ as @.

    @requireLogin publication_this.userId

    found = false
    membership_tracker = @projectMembershipTracker project_id, publication_this.userId,
      added: ->
        found = true

        callbacks.success.call(publication_this)

      removed: ->
        publication_this.stop() # Stop the publication so Meteor will clean all documents
                                # sent by this publication

    publication_this.onStop ->
      membership_tracker.stop()
      callbacks.stop.call(publication_this)

    if not found
      return publication_this.error(@_error("unknown-project"))

    publication_this.ready() # we assume everything is synchronous

    return membership_tracker

  getProjectIfUserIsMember: (project_id, user_id) ->
    if @isMemberVerificationRequired()
      @requireLogin(user_id)

      return @projects_collection.findOne {_id: project_id, "members.user_id": user_id}
    else
      return @projects_collection.findOne {_id: project_id}

  requireUserIsMemberOfProject: (project_id, user_id) ->
    project = @getProjectIfUserIsMember project_id, user_id

    if not project?
      throw @_error "unknown-project"

    return project

  getProject: (project_id) ->
    return @projects_collection.findOne project_id

  getProjectIfUserIsAdmin: (project_id, user_id) ->
    check project_id, String

    query = 
      _id: project_id

    if @isMemberVerificationRequired()
      @requireLogin(user_id)

      query.members =
        $elemMatch:
          {"user_id": user_id, "is_admin": true}

    return @projects_collection.findOne query

  isProjectAdmin: (project_id, user_id) ->
    # Returns true if calling user_id is an admin of project_id
    @requireLogin(user_id)

    return @getProjectIfUserIsAdmin(project_id, user_id)?

  requireProjectAdmin: (project_id, user_id) ->
    if not (project_doc = @getProjectIfUserIsAdmin(project_id, user_id))
      throw @_error "admin-permission-required"

    return project_doc

  #
  # Project life-cycle
  #
  createNewProject: (options, user_id) ->
    @requireLogin(user_id)

    if not options?
      options = {}

    check options,
      init_first_task: Match.Maybe(Boolean) # if true we'll create first task for the project automatically

    default_options =
      init_first_task: true

    options = _.extend default_options, options

    project = 
      title: @_default_project_name
      members: [
        {
          user_id: user_id
          is_admin: true
        }
      ]

    project_id = @projects_collection.insert project

    if options.init_first_task
      @skipMemberVerification =>
        first_doc = {
          title: "Untitled Task"
          project_id: project_id

          # createNewProject might be called when no user is logged in
          # hence the autoValues/middlewares that rely on Meteor.userId()
          # won't help to set the following props
          created_by_user_id: user_id
          owner_id: user_id
        }
        @_grid_data_com.addRootChild first_doc, user_id


    return project_id

  removeProject: (project_id, user_id) ->
    @requireProjectAdmin(project_id, user_id)

    archiveProject = (cb) =>
      @removed_projects_archive_collection.insert @projects_collection.findOne project_id

      raw_projects_collection = @projects_collection.rawCollection()

      # Remove the project using the raw Meteor connection to skip collection
      # hooks (if any), to make the process reversible by _restoreProject()
      # nothing should happen as a result of removing a project - using the
      # raw connection gives us far more control over unintended consequences
      # of remove.
      query = {_id: project_id}
      APP.justdo_analytics.logMongoRawConnectionOp(@projects_collection._name, "remove", query)
      raw_projects_collection.remove query, ->
        cb()

      return

    archiveTasks = (cb) =>
      # Copy all project items to the collection where we archive the tasks
      # of removed projects
      self = @
      @items_collection.find({project_id: project_id}).forEach (task_doc) ->
        self.removed_projects_items_archive_collection.insert task_doc

      # Remove all the project tasks from the regular collection
      # We use rawCollection() to skip Collection Hooks procedures
      # that designed to clean data related to removed tasks.
      # E.g : removing related task files.
      # We don't want related data to be removed since we want to
      # be able to restore the project with all its related data.
      query = {project_id: project_id}
      APP.justdo_analytics.logMongoRawConnectionOp(@items_collection._name, "remove", query)
      @items_collection.rawCollection().remove query, ->
        cb()

        return

      return

    archiveTasksPrivateData = (cb) =>
      # Copy all project items private data to the collection where we archive the tasks
      # of removed projects
      self = @
      @items_private_data_collection.find({project_id: project_id}).forEach (task_doc) ->
        self.removed_projects_items_private_data_archive_collection.insert task_doc

      # Remove all the project tasks private data from the regular collection
      # We use rawCollection() to skip Collection Hooks procedures
      # that designed to clean data related to removed tasks.
      # E.g : removing related task files.
      # We don't want related data to be removed since we want to
      # be able to restore the project with all its related data.
      query = {project_id: project_id}
      APP.justdo_analytics.logMongoRawConnectionOp(@items_private_data_collection._name, "remove", query)
      @items_private_data_collection.rawCollection().remove query, ->
        cb()

        return

      return

    Meteor.wrapAsync(archiveProject)()
    Meteor.wrapAsync(archiveTasks)()
    Meteor.wrapAsync(archiveTasksPrivateData)()

    # Important note! [AVOID_DRASTIC_POST_PROJECT_REMOVAL_PROCEDURES]
    #
    # We want the action of project removal to be as reversible as possible.
    # That's why we avoid making it easy to determine with collection hooks when
    # a project is removed.
    # Developer, use this event to make only mild post-removal procedures that won't
    # affect things dramatically if the action will be reveresed. Example of an action
    # that is minor: for the chat, upon project removal we mark all the project tasks
    # channels as read for all members. If the project will be unremoved, having all
    # its tasks channels as read isn't regarded by us as a serious implication.
    APP.projects.emit "project-removed", project_id

    return

  _restoreProject: (project_id) ->
    # Note that there's no method that wraps this API call, if in the
    # future we'll want to have once, we'll have to add verification
    # regarding which use is performing the action - probably we'll
    # require user to be admin
    # @requireProjectAdmin(project_id, user_id)

    project_doc = @removed_projects_archive_collection.findOne project_id

    if not project_doc?
      throw @_error "unknown-project"

    restoreProject = (cb) =>
      raw_projects_collection = @projects_collection.rawCollection()

      @removed_projects_archive_collection.remove project_id

      # Restore the project document using the raw Meteor connection to skip collection
      # hooks (if any) and simple schema operations.
      # using the raw connection gives us far more control over unintended consequences
      # of the insert operation.
      APP.justdo_analytics.logMongoRawConnectionOp(@projects_collection._name, "insert", project_doc)
      raw_projects_collection.insert project_doc, ->
        cb()

    restoreTasks = (cb) =>
      # Copy all the archived tasks back to the items collection
      # We use rawCollection() to skip Collection Hooks procedures
      # for tasks insertion and keeping the tasks in their exact
      # state in the point of archiving.
      self = @
      @removed_projects_items_archive_collection.find({project_id: project_id}).forEach (task_doc) ->
        APP.justdo_analytics.logMongoRawConnectionOp(self.items_collection._name, "insert", task_doc)
        self.items_collection.rawCollection().insert task_doc, (err) ->
          if err?
            console.error(err)
          return

        return

      # Remove all the archived tasks items from the archive collection
      # We use rawCollection() to skip Collection Hooks procedures
      # that designed to clean data related to tasks when permanently
      # removing backups. For example, the removal of related task files
      # when an archived task is permanently removed.
      query = {project_id: project_id}
      APP.justdo_analytics.logMongoRawConnectionOp(@removed_projects_items_archive_collection._name, "remove", query)
      @removed_projects_items_archive_collection.rawCollection().remove query, ->
        cb()

    restoreTasksPrivateData = (cb) =>
      # Copy all the archived tasks private data back to the items collection
      # We use rawCollection() to skip Collection Hooks procedures
      # for tasks insertion and keeping the tasks in their exact
      # state in the point of archiving.
      self = @
      @removed_projects_items_private_data_archive_collection.find({project_id: project_id}).forEach (task_doc) ->
        APP.justdo_analytics.logMongoRawConnectionOp(self.items_private_data_collection._name, "insert", task_doc)
        self.items_private_data_collection.rawCollection().insert task_doc, (err) ->
          if err?
            console.error(err)
          return

        return

      # Remove all the archived tasks private data items from the archive collection
      # We use rawCollection() to skip Collection Hooks procedures
      # that designed to clean data related to tasks when permanently
      # removing backups.
      query = {project_id: project_id}
      APP.justdo_analytics.logMongoRawConnectionOp(@removed_projects_items_private_data_archive_collection._name, "remove", query)
      @removed_projects_items_private_data_archive_collection.rawCollection().remove query, ->
        cb()

    Meteor.wrapAsync(restoreProject)()
    Meteor.wrapAsync(restoreTasks)()
    Meteor.wrapAsync(restoreTasksPrivateData)()

    return

  _permanentlyRemoveArchivedProject: (project_id) ->
    # Note that there's no method that wraps this API call, if in the
    # future we'll want to have once, we'll have to add verification
    # regarding which use is performing the action - probably we'll
    # require user to be admin
    # @requireProjectAdmin(project_id, user_id)

    if not @removed_projects_archive_collection.findOne(project_id)?
      throw @_error "unknown-project"

    # Note, we use the regular Meteor Mongo connection to allow collection hooks
    # remove related data from the permanently removed project/tasks.
    # E.g remove associated files tasks
    @removed_projects_archive_collection.remove project_id
    @removed_projects_items_archive_collection.remove {project_id: project_id}

    return

  #
  # Project membership management
  #
  inviteMember: (project_id, invited_user, user_id) ->
    # Adds invited_user as a member of project_id.
    #
    # If user_id is set, we'll consider him the inviting user,
    # in such case he'll have to be one of project_id admins
    #
    # invitation structure:
    #
    #   {
    #     email:
    #
    #     profile: {
    #       *Optional*
    #
    #       The user profile for case email is new to the system.
    #       
    #       Need to comply with JustdoAccounts.user_profile_schema above.
    #
    #       Completely ignored if a user with given email already exists
    #
    #       Note, new users invite feature might be disabled in certain cases, see note below
    #     }
    #   }
    #
    # If user with email exists we'll issue an email letting him know
    # that he'd been added to the project.
    #
    # If a user with the given email doesn't exist, we will create one
    # using the details provided in invited_user, enrollment email will
    # be issued to the new user, so he can set his password.
    #
    # Important! invites to new users can be sent only there's a landing app.
    # Since enrollment procedure isn't implemented in the web app level, currently
    # invitations can be sent only if window.env.LANDING_APP_ROOT_URL
    # is set.

    #
    # Make sure proper inputs before any DB query.
    # Set invited_user_email, new_invited_user_profile
    #
    inviting_user_id = user_id # readability
    # inviting_user_id = undefined # keep for testing purposes

    if not _.isObject(invited_user) or not invited_user.email?
      throw @_error("invalid-argument", "No email provided in invited_user arg")
    invited_user_email = invited_user.email

    if not JustdoHelpers.common_regexps.email.test(invited_user_email)
      throw @_error("invalid-email")

    # new_invited_user_profile will be used only if user with
    # invited_user_email doesn't exist, otherwise will be ignored
    if (new_invited_user_profile = invited_user.profile)?
      check(JustdoAccounts.user_profile_schema.clean(new_invited_user_profile), JustdoAccounts.user_profile_schema)
    else
      new_invited_user_profile = {}

    #
    # Is invited user exists already? if not, make sure we can create later under
    # this environment (we do it here, and not after finding the project and the
    # inviting user, to avoid redundant db server hit)
    #
    invited_user_doc = Accounts.findUserByEmail(invited_user_email)

    landing_app_root_url = process.env?.LANDING_APP_ROOT_URL

    if not invited_user_doc?
      # If new user, we have to have landing_app_root_url, read comment above
      if not landing_app_root_url?
        throw @_error("env-var-missing", "LANDING_APP_ROOT_URL is unknown, can't invite a new user")

    #
    # Find project and inviting user
    #
    project_doc = @projects_collection.findOne project_id

    if not project_doc?
      throw @_error "unknown-project"

    if inviting_user_id?
      if not @isAdminOfProjectDoc(project_doc, inviting_user_id)
        throw @_error "admin-permission-required"

      # We assume that if we didn't get reject from @isAdminOfProjectDoc
      # inviting_user_id exists, no need to check existence
      inviting_user_doc = Meteor.users.findOne(inviting_user_id)
    else
      inviting_user_doc = undefined

    #
    # Create the user if he doesn't exist already
    #
    # Note: we know in this point that either user exists or landing_app_root_url exists
    if not invited_user_doc?
      # New user
      create_user_options = {
        email: invited_user_email
        profile: new_invited_user_profile
      }
      invited_user_id = @createUser(create_user_options, inviting_user_id)
      invited_user_doc = Meteor.users.findOne({_id: invited_user_id})

      #
      # Set enrollment token, the following section was taken straight from
      # Meteor's accounts:password v1.1.0.3-justdo-meteor-future-1 source
      #
      token = Random.secret()
      now = new Date()
      tokenRecord = 
        token: token
        email: invited_user_email
        when: now
        reason: 'enroll' # Future ready Meteor PR #7817

      Meteor.users.update invited_user_id, {$set: {'services.password.reset': tokenRecord}}

      # before passing to template, update user object with new token
      Meteor._ensure(invited_user_doc, 'services', 'password').reset = tokenRecord
    else
      # Existing user
      invited_user_id = invited_user_doc._id

      # Check whether already a project member
      if invited_user_id in @getMembersIdsFromProjectDoc(project_doc)
        throw @_error "member-already-exists"

    #
    # Find whether user enrollment process completed already
    #
    @_sendProjectInvite(project_doc, inviting_user_doc, invited_user_doc)

    #
    # Add project member
    #
    member_doc =
      user_id: invited_user_id
      is_admin: false

    if inviting_user_id
      member_doc.invited_by = inviting_user_id

    @projects_collection.update project_id,
      $push:
        members: member_doc
      $pull:
        removed_members:
          user_id: invited_user_id

    return invited_user_id

  resendEnrollmentEmail: (project_id, invited_user_id, inviting_user_id) ->
    project_query =
      _id: project_id
      $and: [
        {"members.user_id": inviting_user_id}, # doesn't have to be admin to work on member invited by him.
        {"members.user_id": invited_user_id}
      ]

    if not (project_doc = @projects_collection.findOne project_query)?
      throw @_error "unknown-project", "Unknown project, or members unknown in the project"

    users_docs =
      Meteor.users.find({_id: {$in: [invited_user_id, inviting_user_id]}}).fetch()

    if not (invited_user_doc = _.find users_docs, (user) -> user._id == invited_user_id)?
      throw @_error "unknown-members"

    if not (inviting_user_doc = _.find users_docs, (user) -> user._id == inviting_user_id)?
      throw @_error "unknown-members"

    if invited_user_doc.services?.password?.reset?.reason != "enroll"
      throw @_error "memebr-already-enrolled", "Member already enrolled"

    if invited_user_doc.invited_by != inviting_user_id
      throw @_error "permission-denied", "Only the inviting member can issue a new enrollement email"

    @_sendProjectInvite(project_doc, inviting_user_doc, invited_user_doc, {send_push_notification: false, send_invitation_email: true})

    return

  _sendProjectInvite: (project_doc, inviting_user_doc, invited_user_doc, options) ->
    # Assumes all the objects: project_doc, inviting_user_doc, invited_user_doc
    # are verified

    # options are:
    #
    #   send_push_notification: true (default)
    #   send_invitation_email: true (default)

    options = _.extend {
        send_push_notification: true
        send_invitation_email: true
      }, options

    if not options.send_push_notification and not options.send_invitation_email
      # Nothing to do

      return

    invited_user_is_enrolled = true
    if invited_user_doc?.services?.password?.reset?
      # if exist we are either in pass reset or enrollment
      if not invited_user_doc?.services?.password?.bcrypt?
        # if bcrypt is undefined, password never defined - enrollment hasn't completed yet
        invited_user_is_enrolled = false

    #
    # Construct notification email
    #
    web_app_root_url = process.env?.ROOT_URL # XXX We assume this function will be called only from web app, might not be true in future (in which case this check will have to change).
    landing_app_root_url = process.env?.LANDING_APP_ROOT_URL
    if not landing_app_root_url? or not web_app_root_url?
      @logger.debug "Unknown landing_app_root_url or web_app_root_url skipping notifications-added-to-new-project notification"
    else
      inviting_user_name = ""
      if (inviting_user_first_name = inviting_user_doc?.profile?.first_name)?
        inviting_user_name += inviting_user_first_name + " "

      if (inviting_user_last_name = inviting_user_doc?.profile?.last_name)?
        inviting_user_name += inviting_user_last_name + " "

      if _.isEmpty inviting_user_name
        inviting_user_name = undefined

      project_title = project_doc.title

      # Build subject
      if inviting_user_name?
        subject = "#{inviting_user_name.trim()} has "
      else
        subject = "You were "

      subject += "invited you to take part in the following JustDo: "

      main_email_line = subject # Main email line doesn't include the project name so we can wrap it with <b> tags (without risking XSS by using {{{}}})
      subject += project_title

      template_data =
        project_doc: project_doc
        invited_user_doc: invited_user_doc
        inviting_user_doc: inviting_user_doc
        main_email_line: main_email_line
        is_enrollment: false

      project_link = web_app_root_url + "/p/#{project_doc._id}"
      if not invited_user_is_enrolled
        # Notification + enrollment email
        enrollment_link = landing_app_root_url + '/#/enroll-account/' + invited_user_doc.services.password.reset.token

        if APP?.login_target?
          enrollment_link = APP.login_target.applyTargetUrl(enrollment_link, project_link)
        else
          @logger.debug "Couldn't find APP.login_target, can't set JustDo page as the post-login target"

        _.extend template_data,
          link: enrollment_link
          is_enrollment: true
          note: "If you are not interested in joining this JustDo, please ignore this email."
      else
        _.extend template_data,
          link: project_link

      Meteor.defer ->
        # Send the email after we return this method (no need to block)

        if options.send_invitation_email
          to = invited_user_doc.emails[0].address

          # new_members_invites_proxy conf
          if (new_members_invites_proxy = project_doc.conf?.new_members_invites_proxy)?
            to = new_members_invites_proxy
            _.extend template_data,
              # original_recepient will be hidden in the email body
              # Replace @ with AT to avoid email clients from automatically make it a link
              original_recepient: invited_user_email.replace("@", "AT")

          JustdoEmails.buildAndSend
            template: "notifications-added-to-new-project"
            template_data: template_data
            to: to
            subject: subject

        if options.send_push_notification
          # Send push notification
          if APP.justdo_push_notifications.isFirebaseEnabled()
            APP.justdo_push_notifications.pnUsersViaFirebase
              message_type: "prj-inv"

              # title: ""

              body: subject

              recipients_ids: [invited_user_doc._id]

              networks: ["mobile"]

              data:
                project_id: project_doc._id

    return


  upgradeAdmin: (project_id, member_id, user_id) ->
    @requireProjectAdmin(project_id, user_id)

    query =
      _id: project_id
      "members.user_id": member_id

    update =
      $set:
        "members.$.is_admin": true

    @projects_collection.update query, update

    return

  downgradeAdmin: (project_id, member_id, user_id) ->
    @requireProjectAdmin(project_id, user_id)

    project = @projects_collection.findOne project_id

    admins = _.filter project?.members, (member) -> member.is_admin
    if admins.length <= 1
      throw @_error "cant-remove-last-project-admin"

    admins_ids_excluding_member_id = _.filter(_.map(admins, (admin) -> admin.user_id), (admin_user_id) -> admin_user_id != member_id)
    admins_that_completed_enrollment_count = Meteor.users.find({_id: {$in: admins_ids_excluding_member_id}, "services.password.reset.reason": {$ne: "enroll"}}).count()

    if admins_that_completed_enrollment_count == 0
      throw @_error "cant-remove-last-project-admin"

    query =
      _id: project_id
      "members.user_id": member_id

    update =
      $set:
        "members.$.is_admin": false

    @projects_collection.update query, update

    return

  removeMember: (project_id, member_id, user_id) ->
    if user_id != member_id # user can remove himself from project even if not admin
      @requireProjectAdmin(project_id, user_id)

    project = @projects_collection.findOne project_id

    admins = _.filter project?.members, (member) -> member.is_admin
    if admins.length <= 1
      admins_ids = _.map admins, (member) -> member.user_id

      if member_id in admins_ids
        throw @_error "cant-remove-last-project-admin"

    admins_ids_excluding_member_id = _.filter(_.map(admins, (admin) -> admin.user_id), (admin_user_id) -> admin_user_id != member_id)
    admins_that_completed_enrollment_count = Meteor.users.find({_id: {$in: admins_ids_excluding_member_id}, "services.password.reset.reason": {$ne: "enroll"}}).count()

    if admins_that_completed_enrollment_count == 0
      throw @_error "cant-remove-last-project-admin"

    # The following is a bit confusing:
    # user_id is the inviting user. member_id is the member we are adding
    update =
      $pull:
        members:
          user_id: member_id
      $push:
        removed_members:
          user_id: member_id
          removed_by: user_id

    @projects_collection.update project_id, update

    # Remove member from all the project's tasks that has it

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see FETCH_PROJECT_TASKS_OF_SPECIFIC_USERS_INDEX there)
    #
    query =
      users: member_id
      project_id: project_id

    update =
      $pull:
        users: member_id

    @_grid_data_com._bulkUpdateFromSecureSource(query, update)
    @_grid_data_com._freezeAllProjectPrivateDataDocsForUsersIds(project_id, [member_id])

    return

  #
  # Project tasks data structure management
  #
  allocateNewTaskSeqId: (project_id) ->
    # Get a new sequential id for a task under project_id
    # We assume, authentications and permissions were tested.
    result = @projects_collection.findAndModify
      query:
        _id: project_id
      fields:
        lastTaskSeqId: 1
      update:
        $inc: 
          lastTaskSeqId: 1
      new: true


    return result.value.lastTaskSeqId

  #
  # Custom fields
  #
  setProjectCustomFields: (project_id, custom_fields, user_id) ->
    @requireProjectAdmin(project_id, user_id)

    project = @getProject(project_id)

    update =
      $set:
        custom_fields: custom_fields

    if (existing_custom_fields = project.custom_fields)?
      existing_custom_fields_ids = _.map existing_custom_fields, (custom_field) -> return custom_field.field_id
      custom_fields_ids = _.map custom_fields, (custom_field) -> return custom_field.field_id

      removed_fields_ids = _.difference(existing_custom_fields_ids, custom_fields_ids)

      if not _.isEmpty removed_fields_ids
        removed_fields = _.filter existing_custom_fields, (field_def) -> field_def.field_id in removed_fields_ids

        if (existing_removed_custom_fields = project.removed_custom_fields)?
          removed_fields = existing_removed_custom_fields.concat(removed_fields)

        update.$set.removed_custom_fields = removed_fields

      # For fields of type select, update the field_options.removed_options field, if necessary
      for field in custom_fields
        if field.field_type == "select"
          if (existing_field_definition = _.find(existing_custom_fields, (custom_field_def) -> custom_field_def.field_id == field.field_id))?
            new_field_definition = field

            if (existing_select_options = existing_field_definition.field_options?.select_options)? and (new_select_options = new_field_definition.field_options?.select_options)?
              existing_options_ids = _.map existing_select_options, (option) -> return option.option_id
              new_options_ids = _.map new_select_options, (option) -> return option.option_id

              removed_options_ids = _.difference(existing_options_ids, new_options_ids)

              if not _.isEmpty removed_options_ids
                removed_options = _.filter existing_select_options, (option_def) -> option_def.option_id in removed_options_ids

                if not (existing_removed_options = existing_field_definition.field_options?.removed_select_options)?
                  existing_removed_options = []

                field.field_options.removed_select_options = existing_removed_options.concat(removed_options)

    return @projects_collection.update project_id, update

  #
  # Post registration initiation
  #
  postRegInit: (user_id) ->
    @requireLogin(user_id)

    if not (user = Meteor.users.findOne({_id: user_id}))?
      throw @_error "user-not-exists"

    initiation_required = (post_reg_init = user.justdo_projects?.post_reg_init)? and post_reg_init == false

    if not initiation_required
      throw @_error "initiation-performed-already"

    Meteor.users.update user_id, {$set: {"justdo_projects.post_reg_init": true}}

    initiation_report = {
      first_project_created: false
    }

    if not @projects_collection.findOne({"members.user_id": user_id})?
      initiation_report.first_project_created = @createNewProject({}, user_id)

    return initiation_report


  configureEmailUpdatesSubscriptions: (projects_ids, set_subscription_mode=true, user_id) ->
    @requireLogin user_id

    check projects_ids, Match.OneOf(String, [String])
    check set_subscription_mode, Boolean

    if _.isString projects_ids
      projects_ids = [projects_ids]

    if projects_ids[0] == "*"
      # Special case, if projects_ids[0] == "*" and set_subscription_mode is false, unsubscribe all projects

      if set_subscription_mode == true
        throw @_error "invalid-argument", "configureEmailUpdateSubscription: projects_ids can't have '*' for set_subscription_mode request"
    
      Meteor.users.update user_id, {$set: {"justdo_projects.daily_email_projects_array": []}}

      return

    if set_subscription_mode
      # putting this requirement here and not before the if statement
      # because it's always valid to remove subscription even if the
      # user is not a member of the project anymore

      for project_id in projects_ids
        @requireUserIsMemberOfProject project_id, user_id

      Meteor.users.update user_id, {
        $addToSet: {
          "justdo_projects.daily_email_projects_array": {$each: projects_ids}
        }
      }
    else
      Meteor.users.update user_id, {
        $pullAll: {
          "justdo_projects.daily_email_projects_array": projects_ids
        }
      }

    return

  configureEmailNotificationsSubscriptions: (projects_ids, set_subscription_mode=true, user_id) ->
    @requireLogin user_id

    check projects_ids, Match.OneOf(String, [String])
    check set_subscription_mode, Boolean

    if _.isString projects_ids
      projects_ids = [projects_ids]

    if projects_ids[0] == "*"
      # Special case, if projects_ids[0] == "*" and set_subscription_mode is false, unsubscribe notifications from all projects

      if set_subscription_mode == true
        throw @_error "invalid-argument", "configureEmailUpdateSubscription: projects_ids can't have '*' for set_subscription_mode=true request"

      projects_ids = _.map @projects_collection.find({"members.user_id": user_id}, {fields: {_id: 1}}).fetch(), (doc) -> doc._id

    if set_subscription_mode
      # putting this requirement here and not before the if statement
      # because it's always valid to remove subscription even if the
      # user is not a member of the project anymore

      for project_id in projects_ids
        @requireUserIsMemberOfProject project_id, user_id

      Meteor.users.update user_id, {
        $pullAll: {
          "justdo_projects.prevent_notifications_for": projects_ids
        }
      }
    else
      Meteor.users.update user_id, {
        $addToSet: {
          "justdo_projects.prevent_notifications_for": {$each: projects_ids}
        }
      }

    return

  _isSubscribedToEmailNotifications: (project_id, user_obj) ->
    if (prevent_notifications_for = user_obj.justdo_projects?.prevent_notifications_for)?
      if project_id in prevent_notifications_for
        return false

    return true

  isSubscribedToDailyEmail: (project_id, user_id) ->
    @requireLogin user_id
    @requireUserIsMemberOfProject project_id, user_id
    
    if not (user = Meteor.users.findOne user_id)?
      throw @_error "user-not-exists"

    daily_email_projects_array = user.justdo_projects?.daily_email_projects_array

    if not _.isArray daily_email_projects_array
      return false

    if project_id in daily_email_projects_array
      return true

    return false

  configureProject: (project_id, conf, requesting_user_id) ->
    # In this method we use the term super admin to mean
    # calls with no requesting_user_id set (these calls
    # can't be initiated by the "configureProject' method).
    #
    # conf struct:
    #
    # {
    #   conf_name: null/undefined # will unset the conf
    #                             # Won't work if:
    #                             # * conf definition `allow_unset` is false
    #                             #   (validation-error will be raised)
    #                             # * conf definition `allow_change` is false
    #                             #   and value is set already (validation-error will be raised)
    #                             # IMPORTANT: client side ddp ignore undefined object values
    #                             # and doesn't send the prop at all, use null only on web clients
    #   conf_name: new_value 
    #
    #   # conf_name notes:
    # 
    #   # * **conf_name** will be ignored if:
    #   #   * It isn't in the allowed_confs
    #   #   * If requesting_user_id is set and it isn't comply
    #   #     with the `admin_allowed_to_set` value of the conf
    #   #     definition.
    #   # * A validation-error will be raised if conf_name has a value
    #   #   already and conf definition `allow_change` is set to false.
    #   # * **value** if not undefined (unset) must comply with
    #   #   `value_matcher` of the conf definition. (validation-error
    #   #    will be raised otherwise)
    # }

    # console.log {project_id, conf, requesting_user_id}

    if not _.isObject conf or _.isEmpty conf
      # nothing to do.
      return 

    permission_level = null # 0 simple member, 1 admin, 2 super admin

    if not requesting_user_id?
      permission_level = 2

      project = @getProject(project_id)
    else
      # If requesting_user_id isn't set, we assume system
      # request, hence no need to check permission
      @requireLogin requesting_user_id # To make sure is String

      project = @getProjectIfUserIsAdmin(project_id, requesting_user_id)

      if project?
        permission_level = 1
      else
        throw @_error "admin-permission-required"

    # console.log {requesting_user_id, permission_level, project}

    if permission_level != 2
      # Get allowed_confs according to user permission
      allowed_confs = _.pickBy allowed_confs, (conf_def, key) ->
        if permission_level == 1 and
            (admin_allowed_to_set = conf_def.admin_allowed_to_set)? and
            admin_allowed_to_set
          return true

        return false

    # console.log {allowed_confs}

    # Remove unknown/not permitted confs
    conf = _.pickBy conf, (conf_val, key) ->
      if key of allowed_confs
        return true
      return false

    # console.log {id: "New conf", conf}

    conf_subdocument_field_name = "conf"
    $set = {}
    $unset = {}
    for conf_name, conf_val of conf
      conf_def = allowed_confs[conf_name]
      matcher = conf_def.value_matcher

      current_value = project.conf?[conf_name]

      if not conf_def.allow_change and current_value?
        throw @_error "validation-error", "Once #{conf_name} is set, it can't be changed, #{conf_name} is set already"

      if not conf_val?
        if conf_def.allow_unset
          $unset["#{conf_subdocument_field_name}.#{conf_name}"] = ""

          continue
        else        
          throw @_error "validation-error", "#{conf_name} can't be unset"

      if _.isRegExp matcher
        if not matcher.test(conf_val)
          throw @_error "validation-error", "#{conf_name} value didn't match regexp"
      else
        check conf_val, matcher

      if (validator = conf_def.validator)? and _.isFunction validator
        if not validator.call @, conf_val
          throw  @_error "validation-error", "#{conf_name} value (#{conf_val}) rejected by validator"

      $set["#{conf_subdocument_field_name}.#{conf_name}"] = conf_val

    query = {}

    if not _.isEmpty $set
      query.$set = $set

    if not _.isEmpty $unset
      query.$unset = $unset

    # console.log {query, $set, $unset}

    if not _.isEmpty query
      # if empty, nothing to do
      @projects_collection.update project_id, query

    return undefined
