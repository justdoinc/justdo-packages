amplify_key = "bootstrap-themes-manager"
default_template_name = "default"

default_options = {}

options_schema = null

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
#         bind_to_instance: true
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

BootstrapThemesManager = (options) ->
  # skeleton-version: v0.0.13-onepage_skeleton

  # Developer, avoid changing this constuctor, to do stuff on init
  # for both server & client, use below the: @_bothImmediateInit()

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("bootstrap-themes-manager")

  @logger.debug "Init begin"
  @JA = JustdoAnalytics.setupConstructorJA(@, "bootstrap-themes-manager")

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

  @_on_destroy_procedures = []

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

  Meteor.defer =>
    @_deferredInit()

  @logger.debug "Init done"

  return @

Util.inherits BootstrapThemesManager, EventEmitter

_.extend BootstrapThemesManager.prototype,
  _error: JustdoHelpers.constructor_error

  # In an effort to encourage standard errors types we will
  # issue a warning if an error of type other than the following
  # will be used.
  #
  # Errors types should be hyphen-separated
  # The value is the default message
  #
  # Throw errors by: throw @_error("error-type", "Custom message")
  #
  # Note that there's a list of common_errors_types that are used
  # as the base for all the packages based on
  # justdo-package-skeleton >= 0.0.4
  _errors_types:
    _.extend {}, JustdoHelpers.common_errors_types,{}

  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @setTheme(@getLastUsedThemeName())

    return

  getLastUsedThemeName: ->
     return amplify.store(amplify_key) or default_template_name

  setTheme: (theme_name) ->
    amplify.store amplify_key, theme_name

    $("#bootstrap-theme").remove()

    $(document.head).append("""<link id="bootstrap-theme" rel="stylesheet" href="/packages/twbs_bootstrap/bootstrap4/themes/#{theme_name}/bootstrap.css">""");

    return

  onDestroy: (proc) ->
    @_on_destroy_procedures.push proc

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @destroyed = true

    @logger.debug "Destroyed"

    return

share.BootstrapThemesManager = BootstrapThemesManager
