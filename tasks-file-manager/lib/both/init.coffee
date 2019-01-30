default_options =
  tasks_collection: null
  removed_projects_tasks_archive_collection: null # Relevant for Server only, no need to provide for client init!
  api_key: ""
  secret: ""

TasksFileManager = (options) ->
  # skeleton-version: v0.0.2

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("tasks-file-manager")

  @logger.debug "Init begin"

  @options = _.extend {}, default_options, options

  if not @options.tasks_collection?
    throw @_error "missing-option", "tasks_collection option is required"

  @tasks_collection = @options.tasks_collection

  if Meteor.isServer
    @removed_projects_tasks_archive_collection = @options.removed_projects_tasks_archive_collection

  JustdoHelpers.loadEventEmitterHelperMethods(@)
  @loadEventsFromOptions() # loads @options.events, if exists

  @_attachCollectionsSchemas()

  if Meteor.isClient
    # React to invalidations
    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        @logger.debug "Enclosing computation invalidated, destroying"
        @destroy() # defined in client/api.coffee

    # on the client, call @_immediateInit() in an isolated
    # computation to avoid our init procedures from affecting
    # the encapsulating computation (if any)
    Tracker.nonreactive =>
      @_immediateInit()
  else
    @_immediateInit()

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits TasksFileManager, EventEmitter

_.extend TasksFileManager.prototype,
  _error: JustdoHelpers.constructor_error
