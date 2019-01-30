# This file is the last file we load for this package and it's loaded in both
# server and client (keep in mind! don't put non-secure code that shouldn't be
# exposed to clients here).
#
# Uncomment to create an instance automatically on server/client init
#
# If you uncomment this, uncomment in package.js the load of meteorspark:app
# package.
#
# Avoid this step in packages that implements pure logic that isn't specific
# to the JustDo app. Pure logic packages should get all the context they need
# to work with collections/other plugins instances/etc. as options.

# **Method A:** If you aren't depending on any env variable just comment the following

# APP.justdo_ddp_extensions = new JustdoDdpExtensions()

# **Method B:** If you are depending on env variables to decide whether or not to load
# this package, or even if you use them inside the constructor, you need to wait for
# them to be ready, and it is better done here.

APP.collections.Projects = new Mongo.Collection "projects"

# Must be initiated for both server and client!
APP.login_state = new JustdoLoginState()

project_options = 
  justdo_accounts: APP.accounts
  projects_collection: APP.collections.Projects
  items_collection: APP.collections.Tasks
  items_private_data_collection: APP.collections.TasksPrivateData
  local_tickets_queue_collection_name: "TicketsQueues"
  local_required_actions_collection_name: "RequiredActions"

if Meteor.isClient
  APP.collections.TicketsQueues = new Mongo.Collection "TicketsQueues"
  project_options.local_tickets_queue_collection =
    APP.collections.TicketsQueues

  APP.collections.RequiredActions = new Mongo.Collection "RequiredActions"
  project_options.local_required_actions_collection =
    APP.collections.RequiredActions

  APP.hash_requests_handler = new HashRequestsHandler
    prefix: "hr"

  login_state_tracker = Tracker.autorun ->
    # Look for hash requests only when there's a logged in user
    login_state = APP.login_state.getLoginState()

    login_state_sym = login_state[0]

    if login_state_sym == "logged-in"
      APP.hash_requests_handler.run()

      return

    if login_state_sym == "logged-out"
      APP.hash_requests_handler.stop()

      return

    return

  project_options.hash_requests_handler =
    APP.hash_requests_handler

if Meteor.isServer
  APP.collections.RemovedProjectsArchiveCollection =
    new Mongo.Collection "removed_projects_archive_collection"

  # Note: stores only tasks that were removed during project removal - not
  # all removed items
  APP.collections.RemovedProjectsTasksArchiveCollection =
    new Mongo.Collection "removed_projects_tasks_archive_collection"

  # Note: stores only tasks private data that were removed during project removal - not
  # all removed private data items
  APP.collections.RemovedProjectsTasksPrivateDataArchiveCollection =
    new Mongo.Collection "removed_projects_tasks_private_data_archive_collection"

  project_options.removed_projects_archive_collection =
    APP.collections.RemovedProjectsArchiveCollection

  project_options.removed_projects_items_archive_collection =
    APP.collections.RemovedProjectsTasksArchiveCollection

  project_options.removed_projects_items_private_data_archive_collection =
    APP.collections.RemovedProjectsTasksPrivateDataArchiveCollection

APP.projects = new Projects project_options