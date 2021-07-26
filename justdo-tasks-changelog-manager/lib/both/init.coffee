default_options = {}

options_schema =
  both:
    changelog_collection:
      type: "skip-type-check"
      optional: false
      bind_to_instance: true
    tasks_collection:
      type: "skip-type-check"
      optional: false
      bind_to_instance: true
    justdo_projects_obj:
      type: "skip-type-check"
      optional: false
      bind_to_instance: true
    # redundant_subscriptions_timeout_ms:
    #   type: Number
    #   defaultValue: 3 * 60 * 1000 # 3 mins
  server:
    removed_projects_tasks_archive_collection:
      type: "skip-type-check"
      optional: false
      bind_to_instance: true

    startup_trackers:
      # The trackers that will be loaded on init
      # without the need to call @runTracker()
      type: "skip-type-check"
      blackbox: true
      # should be array of the format:
      # [[trackerName, {options}], ...]
      # If tracker has no options, the trackerName string
      # can be passed alone
      defaultValue:
        [
          "newTaskTracker",
          "removeTaskTracker",
          "parentsChangesTracker",
          "taskUsersChangesTracker",
          "priorityChangesTracker",
          "redundantLogsTracker",
          ["simpleTasksFieldsChangesTracker", {
            tracked_fields: ["title", "status", "owner_id", "follow_up", "due_date", "state", "start_date", "end_date"]
            track_custom_fields: true
            track_pseudo_fields: true
          }]
        ]

TasksChangelogManager = (options) ->
  # skeleton-version: v0.0.4

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("tasks-changelog-manager")

  @logger.debug "Init begin"

  @options = _.extend {}, default_options, options # Apply basic defaults
  if not _.isEmpty(options_schema)
    # If options_schema is set, use it to apply strict structure on
    # @options.
    #
    # Clean and validate @options according to options_schema.
    # invalid-options error will be thrown for invalid options.
    # Takes care of binding options with bind_to_instance to
    # the instance.
    @options =
      JustdoHelpers.loadOptionsWithSchema(
        options_schema, @options, {
          self: @
          additional_schema: # Adds the `events' option to the permitted fields
            events:
              type: Object
              blackbox: true
              optional: true
        }
      )

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
      @_immediateInit() # defined in client/init.coffee
  else
    @_immediateInit() # defined in server/init.coffee

  Meteor.defer =>
    @_deferredInit() # defined in [client/server]/init.coffee

  @logger.debug "Init done"

  return @

Util.inherits TasksChangelogManager, EventEmitter

_.extend TasksChangelogManager.prototype,
  _error: JustdoHelpers.constructor_error