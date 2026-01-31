# Test Data Helper Functions
#
# Utility functions for creating test data in fixtures.
# These are designed to be idempotent - they check if data exists before creating.
#
# All helper functions use TEST_CONSTANTS for consistency with Cypress tests.

# Default test password (sha-256 hash of "test_password")
DEFAULT_TEST_PASSWORD =
  digest: "10a6e6cc8311a3e2bcc09bf6c199adecd5dd59408c343e926b129c4914f3cb01"
  algorithm: "sha-256"

# Default account options
DEFAULT_ACCOUNT_OPTIONS =
  password: DEFAULT_TEST_PASSWORD
  signed_legal_docs: ["terms_conditions", "privacy_policy"]
  send_verification_email: false

# Default profile - using a function to defer evaluation until TEST_CONSTANTS is available
getDefaultProfile = ->
  timezone: TEST_CONSTANTS?.defaults?.timezone or "America/New_York"

# Create or get a user by email
# @param options [Object]
#   - email: [String] User's email address (required)
#   - password: [Object] Password object with digest and algorithm (optional, defaults to test_password)
#   - profile: [Object] User profile with first_name, last_name, timezone (optional)
#   - isSiteAdmin: [Boolean] Whether user should be site admin (optional)
#   - isProxy: [Boolean] Whether user is a proxy user (optional)
# @return [Object] The user document
createOrGetUser = (options) ->
  unless options.email?
    throw new Error("[createOrGetUser] email is required")
  
  # Check if user already exists
  existingUser = Meteor.users.findOne({"emails.address": options.email})
  if existingUser?
    return existingUser
  
  # Build user options
  userOptions = _.extend {}, DEFAULT_ACCOUNT_OPTIONS,
    email: options.email
    password: options.password or DEFAULT_TEST_PASSWORD
    profile: _.extend {}, getDefaultProfile(), options.profile or {}
  
  # Create the user
  if options.isProxy
    # Check if APP.accounts is available
    unless APP?.accounts?.createProxyUsers?
      throw new Error("[createOrGetUser] APP.accounts.createProxyUsers is not available")
    user_id = APP.accounts.createProxyUsers([userOptions])[0]
  else
    unless APP?.accounts?.createUser?
      throw new Error("[createOrGetUser] APP.accounts.createUser is not available")
    user_id = APP.accounts.createUser(userOptions)
  
  # If site admin, set up site admin status
  if options.isSiteAdmin
    Meteor.users.update user_id, {$set: {"emails.0.verified": true}}
    unless APP?.justdo_site_admins?.setUsersAsSiteAdminsSecureSource?
      throw new Error("[createOrGetUser] APP.justdo_site_admins is not available")
    APP.justdo_site_admins.setUsersAsSiteAdminsSecureSource(user_id)
  
  # Return the created user document
  return Meteor.users.findOne(user_id)

# Create a test project
# @param options [Object]
#   - title: [String] Project title (optional, defaults to TEST_CONSTANTS.projects.defaultTitle)
#   - owner_id: [String] User ID of the project owner (required)
#   - members: [Array<String>] User IDs of additional project members (optional)
#   - init_first_task: [Boolean] Whether to create first task (optional, defaults to false)
# @return [Object] The project document
createTestProject = (options) ->
  unless options.owner_id?
    throw new Error("[createTestProject] owner_id is required")
  
  # Check if APP.projects is available
  unless APP?.projects?
    throw new Error("[createTestProject] APP.projects is not available")
  
  # Create the project using the server-side API
  project_id = APP.projects.createNewProject
    init_first_task: options.init_first_task ? false
  , options.owner_id
  
  # Set custom title if provided (or use default)
  title = options.title or TEST_CONSTANTS.projects.defaultTitle
  APP.projects.projects_collection.update project_id,
    $set: {title: title}
  
  # Add additional members if specified
  if options.members?.length > 0
    for member_id in options.members
      # Use inviteMember API - invited_user needs to be an object with user_id
      APP.projects.inviteMember project_id, {user_id: member_id}, options.owner_id
  
  return APP.projects.projects_collection.findOne(project_id)

# Create a test task
# @param options [Object]
#   - project_id: [String] Project ID (required)
#   - title: [String] Task title (required)
#   - parent_id: [String] Parent task ID (optional, for subtasks - use "/" for root)
#   - user_id: [String] User ID performing the action (required)
# @return [Object] The task document
createTestTask = (options) ->
  unless options.project_id?
    throw new Error("[createTestTask] project_id is required")
  unless options.title?
    throw new Error("[createTestTask] title is required")
  unless options.user_id?
    throw new Error("[createTestTask] user_id is required")
  
  # Check if APP.projects is available
  unless APP?.projects?
    throw new Error("[createTestTask] APP.projects is not available")
  
  # Get the project
  project = APP.projects.projects_collection.findOne(options.project_id)
  unless project?
    throw new Error("[createTestTask] Project not found: #{options.project_id}")
  
  # Build task data
  taskData =
    title: options.title
    project_id: options.project_id
    created_by_user_id: options.user_id
    owner_id: options.user_id
  
  # Use the grid data component to create the task
  # addRootChild adds to root level, addChild requires a parent path
  if options.parent_id? and options.parent_id isnt "/"
    task_id = APP.projects._grid_data_com.addChild options.parent_id, taskData, options.user_id
  else
    task_id = APP.projects._grid_data_com.addRootChild taskData, options.user_id
  
  return APP.projects._grid_data_com.items_collection.findOne(task_id)

# Helper to run code as a specific user
# @param userId [String] The user ID to run as
# @param fn [Function] The function to execute
# @return [Any] The return value of fn
_currentTestUserId = null

runAsUser = (userId, fn) ->
  # In server tests, we can use this pattern to simulate user context
  # This is a simplified version - actual implementation may vary
  _currentTestUserId = userId
  try
    return fn()
  finally
    _currentTestUserId = null

# Get current test user ID (for use in runAsUser context)
getCurrentTestUserId = ->
  _currentTestUserId
