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
  #   require_admin_permission: true/false # If false, regular members can
  #                                        # edit this configuration as well
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
    require_admin_permission: true
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
    # XXX Developers please notice that we got a JustDo helper
    # for this feature now see fiber-var.coffee .
    #
    # If you are willing to test thoroughly can change the code here
    # to use fiber-var.
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
    @emit "pre-create-new-justdo", user_id

    if not options?
      options = {}

    check options,
      init_first_task: Match.Maybe(Boolean) # if true we'll create first task for the project automatically
      conf: Match.Maybe(Object)
      custom_fields: Match.Maybe([Object])
      derive_custom_fields_and_grid_views_from_project_id: Match.Maybe(String)

    if options.custom_fields? and options.derive_custom_fields_and_grid_views_from_project_id?
      throw @_error "invalid-parameters", "Options custom_fields and derive_custom_fields_and_grid_views_from_project_id cannot exist at the same time"

    default_options =
      init_first_task: true

    options = _.extend default_options, options

    conf = options.conf or {
      custom_features: ["justdo_private_follow_up", "justdo_planning_utilities", "justdo_projects_health", "justdo_inbound_emails", "justdo_calendar_view", "justdo_clipboard_import", "justdo-item-duplicate-control", "meetings_module"]
    }

    project = 
      title: @_default_project_name
      members: [
        {
          user_id: user_id
          is_admin: true
        }
      ]
      conf: conf
      timezone: APP.justdo_delivery_planner.getUserTimeZone user_id

    if options.custom_fields?
      project.custom_fields = options.custom_fields
    
    if options.derive_custom_fields_and_grid_views_from_project_id? and @requireProjectAdmin(options.derive_custom_fields_and_grid_views_from_project_id, user_id)
      org_project = APP.collections.Projects.findOne options.derive_custom_fields_and_grid_views_from_project_id,
        fields:
          custom_fields: 1
      if org_project?.custom_fields?
        project.custom_fields = org_project.custom_fields

      grid_views = APP.collections.GridViews.find
        "hierarchy.justdo_id": options.derive_custom_fields_and_grid_views_from_project_id
      ,
        fields:
          view: 1
          title: 1
          shared: 1
          user_id: 1
      .fetch()

    project_id = @projects_collection.insert project
    
    if grid_views?
      for grid_view in grid_views
        grid_view.type = "justdo"
        grid_view.hierarchy = {
          type: "justdo"
          justdo_id: project_id
        }
        APP.justdo_grid_views.upsert(null, grid_view, grid_view.user_id)

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
    #     add_as_guest: false (default) / true
    #
    #     users_allowed_to_edit_pre_enrollment: undefined / [] # Optional array of users
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

    if not (add_as_guest = invited_user.add_as_guest)? or not _.isBoolean(add_as_guest)
      add_as_guest = false

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
      @emit "pre-invite-new-user-member-to-justdo", invited_user
      # New user
      create_user_options = {
        email: invited_user_email
        profile: new_invited_user_profile
        users_allowed_to_edit_pre_enrollment: invited_user.users_allowed_to_edit_pre_enrollment
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
      is_guest: add_as_guest

    if inviting_user_id
      member_doc.invited_by = inviting_user_id

    @projects_collection.update project_id,
      $push:
        members: member_doc
      $pull:
        removed_members:
          user_id: invited_user_id

    # Share with the added members all the tasks that belonged only to him/her before
    # (relevant only for users that removed from the JustDo and brought back)
    tasks_that_belonged_before_only_to_that_user_and_now_remained_with_no_user = []
    APP.collections.Tasks.find({owner_id: invited_user_id, is_removed_owner: true, users: []}, {fields: {_id: 1}}).forEach (task) ->
      tasks_that_belonged_before_only_to_that_user_and_now_remained_with_no_user.push task._id
    if not _.isEmpty tasks_that_belonged_before_only_to_that_user_and_now_remained_with_no_user
      selector =
        _id:
          $in: tasks_that_belonged_before_only_to_that_user_and_now_remained_with_no_user
        project_id: project_id

      mutator =
        $push:
          users:
            $each: [invited_user_id]
      
      # @_bulkUpdate(project_id, tasks_that_belonged_before_only_to_that_user_and_now_remained_with_no_user, mutator, invited_user_id)
      # Note, we can't reuse @bulkUpdate like the code in the above line that does for us things like unfreezing private fields, and query preparation
      # @bulkUpdate is very strict about who can use, and in the choice of adding less secure options to it, and having
      # a less DRY code, I sided with less DRY code. Daniel C.

      @_grid_data_com._bulkUpdateFromSecureSource selector, mutator, Meteor.bindEnvironment (err) =>
        if err?
          console.error(err)

          return

        # Unfreeze private data fields
        @_grid_data_com._setPrivateDataDocsFreezeState([invited_user_id], tasks_that_belonged_before_only_to_that_user_and_now_remained_with_no_user, false)

        # Remove the is_removed_owner flag from the tasks the user got back
        # Don't use the following code, it is much less efficient! (since we know for sure the flag needs to be removed from these tasks...) @_grid_data_com._removeIsRemovedOwnerForTasksBelongingTo(tasks_that_belonged_before_only_to_that_user_and_now_remained_with_no_user, invited_user_id)
        @_grid_data_com._removeIsRemovedOwnerForTasks(tasks_that_belonged_before_only_to_that_user_and_now_remained_with_no_user)

        return

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

    # The following code allows only users that are allowed to edit the invited_user_id pre enrollment
    # to re-issue a new enrollment email.
    #
    # On June 2nd 2021 we (Galit and Daniel) decided to remove this requirement.
    #
    # users_allowed_to_edit_pre_enrollment = (invited_user_doc.users_allowed_to_edit_pre_enrollment or []).slice() # slice to avoid edit by reference
    # if _.isString(invited_user_doc.invited_by)
    #   users_allowed_to_edit_pre_enrollment.push invited_user_doc.invited_by

    # if inviting_user_id not in users_allowed_to_edit_pre_enrollment
    #   throw @_error "permission-denied", "User is not allowed to issue a new enrollement email"

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
            invited_user_email = to
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

  upgradeGuest: (project_id, guest_id, user_id) ->
    @requireProjectAdmin(project_id, user_id)

    query =
      _id: project_id

      members:
        $elemMatch:
          {"user_id": guest_id, "is_guest": true}

    update =
      $set:
        "members.$.is_guest": false

    @projects_collection.update query, update

    return

  makeGuest: (project_id, member_id, user_id) ->
    @requireProjectAdmin(project_id, user_id)

    query =
      _id: project_id

      members:
        $elemMatch:
          {"user_id": member_id, "is_admin": false}

    update =
      $set:
        "members.$.is_guest": true

    @projects_collection.update query, update

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

    if not @processHandlers("BeforeDowngradeAdmin", project_id, member_id, user_id)
      throw @_error "forbidden", "Admin downgrade denied"

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

  registerCustomCompoundBulkUpdate: (type_id, opsGenerator) ->
    if @custom_compound_bulk_update[type_id]?
      throw @_error "invalid-argument", "A custom compound bulk update with the type: #{type_id} is already set"

    @custom_compound_bulk_update[type_id] =
      opsGenerator: opsGenerator

    return

  customCompoundBulkUpdate: (project_id, type_id, payload, user_id) ->
    if not @custom_compound_bulk_update[type_id]?
      throw @_error "invalid-argument", "Unknown custom compound bulk update type: #{type_id}"

    ops = @custom_compound_bulk_update[type_id].opsGenerator(payload)

    JustdoHelpers.runCbInFiberScope "skip-allowed_bulk_update_modifiers-check", true, =>
      @compoundBulkUpdate(project_id, ops, user_id)
      return

    return

  compoundBulkUpdate: (project_id, ops, user_id) ->
    # compoundBulkUpdate is just a wrapper proxy for bulkUpdate, we won't introduce events handlers for it.
    #
    # ops is of the form:
    #
    # [[item_id, modifier], ...] OR
    # [[[items_ids], modifier], ...]

    if not _.isArray ops
      throw @_error "invalid-argument", "ops must be an array"

    # Rest of argument validation will be handled by bulkUpdate

    for op in ops
      if not _.isArray op
        throw @_error "invalid-argument", "ops must be an array of arrays"

      [items_ids, modifier] = op

      if _.isString items_ids
        items_ids = [items_ids]

      @bulkUpdate(project_id, items_ids, modifier, user_id)

    return

  bulkUpdate: (project_id, items_ids, modifier, user_id) ->
    check project_id, String
    check items_ids, [String]
    # Modifier is thoroughly checked by _bulkUpdate
    check user_id, String

    if not @processHandlers("BeforeBulkUpdateExecution", project_id, items_ids, modifier, user_id)
      return

    cb = (err) =>
      @processHandlers("AfterBulkUpdateExecution", project_id, items_ids, modifier, user_id, err)
      return

    return @_bulkUpdateWithCb(project_id, items_ids, modifier, cb, user_id)

  _bulkUpdate: (project_id, items_ids, modifier, user_id) ->
    return @_bulkUpdateWithCb project_id, items_ids, modifier, undefined, user_id

  _bulkUpdateWithCb: (project_id, items_ids, modifier, cb, user_id) ->
    check project_id, String
    check items_ids, [String]
    # Modifier is thoroughly checked below
    check cb, Match.Maybe(Function)
    check user_id, String

    @requireUserIsMemberOfProject project_id, user_id

    #
    # Validate inputs
    #
    if JustdoHelpers.getFiberVar("skip-allowed_bulk_update_modifiers-check") isnt true
      # To avoid security risk, we are whitelisting the allowed bulkUpdates
      try
        check(modifier, Match.OneOf.apply(Match, @allowed_bulk_update_modifiers))
      catch e
        throw @_error "invalid-argument", "_bulkUpdateWithCb: modifier provided isn't allowed", modifier
    
    # IMPORTANT
    # IMPORTANT A lot of the code here is repeated under grid-data/lib/grid-data-com/grid-data-com-server-api.coffee ~line 1036
    # IMPORTANT
    if modifier.$push?.users?
      # We transition from $push to $addToSet to avoid duplicates (e.g. if A->B are tasks B has users a, b
      # but A only user a if b is added to A $push will add it another time to B)
      if modifier.$addToSet?.users?
        throw @_error "operation-blocked", "bulkUpdate doesn't support both $push.users and $addToSet.users in the same call"

      Meteor._ensure(modifier, "$addToSet")

      modifier.$addToSet.users = modifier.$push.users

      delete modifier.$push

    #
    # Exec
    #

    # Returns the count of changed items
    selector = 
      _id:
        $in: items_ids
      users: user_id
      project_id: project_id

    # We make sure that the middleware don't change this condition, too risky.
    selector.users = user_id

    # XXX in terms of security we rely on the fact that the user belongs to
    # the requested items (see selector query) to let him/her do basically
    # whatever action they like (worst case... he destory his own data.
    # perhaps in the future we'd like to apply some more checks here.

    added_users = []
    removed_users = []

    if (pushed_users = modifier.$addToSet?.users?.$each)?
      added_users = added_users.concat(pushed_users)

    if (pulled_users = modifier.$pull?.users?.$in)?
      removed_users = removed_users.concat(pulled_users)

    if not _.isEmpty added_users
      @_grid_data_com._setPrivateDataDocsFreezeState(added_users, items_ids, false)
      # Important, if you change the logic here, note that in the process of inviteMember
      # we also call @_setPrivateDataDocsFreezeState()

    if not _.isEmpty removed_users
      @_grid_data_com._setPrivateDataDocsFreezeState(removed_users, items_ids, true)
      # Important, if you change the logic here, note that in the process of removeMember
      # we do something similar using a slight different API: _freezeAllProjectPrivateDataDocsForUsersIds

    @_grid_data_com._bulkUpdateFromSecureSource selector, modifier, Meteor.bindEnvironment (err) =>
      if err?
        console.error(err)
      else
        @_grid_data_com._removeIsRemovedOwnerForTasksBelongingTo(items_ids, added_users)

      JustdoHelpers.callCb cb, err

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

    if not @processHandlers("BeforeRemoveMember", project_id, member_id, user_id)
      throw @_error "forbidden", "Member removal denied"

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

    bulk_updates_on_tasks_collections = [
      {
        #
        # Take care of removing pending transfer requests to the user in the project tasks
        #
        update_description: "remove pending ownership transfer query" # Used just when reporting errors

        query:
          users: member_id
          project_id: project_id
          pending_owner_id: member_id

        mutator:
          $set:
            pending_owner_id: null
      }

      {
        # Remove member from all the project's tasks that has it

        #
        # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
        # and to drop obsolete indexes (see FETCH_PROJECT_TASKS_OF_SPECIFIC_USERS_INDEX there)
        #
        update_description: "remove member from all the project's tasks that has it" # Used just when reporting errors

        query:
          users: member_id
          project_id: project_id

        mutator:
          $pull:
            users: member_id
      }

      {
        # Set the is_removed_owner field to true on all the tasks that the removed user owned

        update_description: "set the is_removed_owner flag on owned tasks" # Used just when reporting errors

        query:
          project_id: project_id
          owner_id: member_id

        mutator:
          $set:
            is_removed_owner: true
      }
    ]

    bulk_updates_on_tasks_collections_async_series_tasks = _.map bulk_updates_on_tasks_collections, (task_def) =>
      return (cb) => @_grid_data_com._bulkUpdateFromSecureSource task_def.query, task_def.mutator, (err) =>
        if err?
          console.error("removeMember failed during op: #{task_def.update_description}", err)

        cb(err)

        return

    async.series bulk_updates_on_tasks_collections_async_series_tasks, (err) =>
      if err?
        # If failed do nothing, errors already printed
        return

      @_grid_data_com._freezeAllProjectPrivateDataDocsForUsersIds(project_id, [member_id])

      @processHandlers("AfterRemoveMember", project_id, member_id, user_id)

      return

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

  configureProject: (project_id, conf, user_id) ->
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
    #   #   * If user_id isn't comply with the `require_admin_permission
    #   #     value of the conf definition.
    #   # * A validation-error will be raised if conf_name has a value
    #   #   already and conf definition `allow_change` is set to false.
    #   # * **value** if not undefined (unset) must comply with
    #   #   `value_matcher` of the conf definition. (validation-error
    #   #    will be raised otherwise)
    # }

    # console.log "STEP 1", {project_id, conf, user_id}

    if not _.isObject conf or _.isEmpty conf
      return 

    permission_level = -1 # 0 regular member, 1 admin

    @requireLogin user_id # To make sure is String

    if (project = @getProjectIfUserIsAdmin(project_id, user_id))?
      permission_level = 1
    else if (project = @getProjectIfUserIsMember(project_id, user_id))?
      permission_level = 0
    else
      throw @_error "unknown-project"

    # console.log "STEP 2", {user_id, permission_level, project}

    # Get allowed_confs according to user permission
    permitted_confs = _.pickBy allowed_confs, (conf_def, key) ->
      if not (require_admin_permission = conf_def.require_admin_permission)? or
         not require_admin_permission
        return true

      if require_admin_permission and permission_level == 1
        return true

      return false

    # console.log "STEP 3", {permitted_confs}

    # Remove unknown/not permitted confs
    conf = _.pickBy conf, (conf_val, key) ->
      if key of permitted_confs
        return true
      return false

    # console.log "STEP 4", {id: "New conf", conf}

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

  updateTaskDescriptionReadDate: (task_id, user_id) ->
    check task_id, String
    check user_id, String

    task_doc = APP.collections.Tasks.findOne
      _id: task_id
      users: user_id
    ,
      fields:
        _id: 1
        project_id: 1

    if not task_doc
      throw @error "task-not-found"
    
    private_fields_mutator =
      $currentDate:
        "#{Projects.tasks_description_last_read_field_id}": true

    APP.projects._grid_data_com._upsertItemPrivateData task_doc.project_id, task_doc._id, private_fields_mutator, user_id

    return