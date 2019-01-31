default_options = {}

options_schema =
  server:
    storage:
      type: String
      optional: true
      bind_to_instance: false
      defaultValue: "console"

      # Note: on the server it is being binded to the JustdoAnalyics object under
      # @storage_types on server/init-storage.coffee (set as comma separated list)

    log_incoming_ddp:
      type: Boolean
      optional: true
      bind_to_instance: false
      defaultValue: false

    log_mongo_queries:
      type: Boolean
      optional: true
      bind_to_instance: false
      defaultValue: false

    add_aws_metadata_to_server_env:
      type: Boolean
      optional: true
      bind_to_instance: false
      defaultValue: false

    log_server_status:
      type: Boolean
      optional: true
      bind_to_instance: false
      defaultValue: false

    log_server_status_interval:
      type: Number
      optional: true
      bind_to_instance: false
      defaultValue: 1000 * 15 # Every 15 seconds

    skip_encryption:
      type: Boolean
      optional: true
      bind_to_instance: false
      defaultValue: false

    devops_public_key:
      type: String
      optional: true
      bind_to_instance: false

# options_schema
# ==============
#
# If options_schema is an object, we use it to clean and validate
# the contructor options. (otherwise ignored completly).
#
# *Notes:*
#
# * by using options_schema you must define any option that
#   the constructor can receive, options that won't be defined will be
#   omitted from the @options object.
#
# * default_options above is applied to the received options before
#   we process options_schema.
#
# * If validation fails an `@_error "invalid-options", message`
#   will be thrown, with message detailing in a human readable way the
#   validation issues.
#
# options_schema format
# ---------------------
#
# An object with the schema for options defined for each
# platform (both/server/client, server/client takes
# precedence over both).
#
# *The bind_to_instance schema option*
#
# We will recognize the `bind_to_instance` schema option.
# If `bind_to_instance` is set to true the option value
# will be assigned automatically to @[option_name].
# If `bind_to_instance` is false or doesn't exist, it is
# ignored.
#
# Note, at the moment for objects that inherits from
# constructors, it is best to ignore type checking
# by setting type to: "skip-type-check"
#
# *Example:*
#
#   options_schema =
#     both:
#       tasks_collection:
#         type: "skip-type-check"
#         optional: false
#         bind_to_instance: true # will be available under @tasks_collection
#       op_b:
#         type: Number
#         optional: true
#         defaultValue: 30
#     client:
#       op_c:
#         type: Number
#         optional: false
#     server:
#       op_d:
#         type: Number
#         optional: true
#         defaultValue: 30

JustdoAnalytics = (options) ->
  # skeleton-version: v0.0.8

  # Developer, avoid changing this constuctor, to do stuff on init
  # for both server & client, use below the: @_bothImmediateInit()

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("justdo-analytics")

  @logger.debug "Init begin"

  @options = _.extend {}, default_options, options
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
      @_bothImmediateInit()

      @_immediateInit()
  else
    @_bothImmediateInit()

    @_immediateInit()

  Meteor.defer =>
    @_bothDeferredInit()
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits JustdoAnalytics, EventEmitter

_.extend JustdoAnalytics.prototype,
  _error: JustdoHelpers.constructor_error

  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    return
