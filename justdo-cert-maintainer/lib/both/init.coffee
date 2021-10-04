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

JustdoCertMaintainer = ->
  # skeleton-version: v3.0.1

  # Developer, avoid changing this constuctor, to do stuff on init
  # for both server & client, use below the: @_bothImmediateInit()

  EventEmitter.call @

  @destroyed = false

  @logger = Logger.get("justdo-cert-maintainer")
  @JA = JustdoAnalytics.setupConstructorJA(@, "justdo-cert-maintainer")

  @logger.debug "Init begin"

  @_on_destroy_procedures = []

  JustdoHelpers.loadEventEmitterHelperMethods(@)

  @_on_destroy_procedures = []

  if Meteor.isClient
    # React to invalidations
    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        @logger.debug "Enclosing computation invalidated, destroying"
        @destroy() # defined in client/api.coffee

        return

    # on the client, call @_immediateInit() in an isolated
    # computation to avoid our init procedures from affecting
    # the encapsulating computation (if any)
    Tracker.nonreactive =>
      @_bothImmediateInit()

      @_immediateInit()

      return

  else
    @_bothImmediateInit()

    @_immediateInit()

  Meteor.defer =>
    @_bothDeferredInit()
    @_deferredInit()

    return

  @logger.debug "Init done"

  return @

Util.inherits JustdoCertMaintainer, EventEmitter

_.extend JustdoCertMaintainer.prototype,
  _error: JustdoHelpers.constructor_error

  onDestroy: (proc) ->
    # not to be confused with @destroy, onDestroy registers procedures to be called by @destroy()
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
