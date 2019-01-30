default_options = {}

options_schema =
  client:
    right_margin:
      type: Number
      defaultValue: 30
      optional: true
      bind_to_instance: false

    left_margin:
      type: Number
      defaultValue: 30
      optional: true
      bind_to_instance: false

    open_window_width:
      type: Number
      defaultValue: 260
      optional: true
      bind_to_instance: false

    min_window_width:
      type: Number
      defaultValue: 70
      optional: true
      bind_to_instance: false

    width_between_windows:
      type: Number
      defaultValue: 7
      optional: true
      bind_to_instance: false

    # Extra windows button

    width_between_windows_to_extra_windows_button:
      type: Number
      defaultValue: 10
      optional: true
      bind_to_instance: false

    extra_windows_button_width:
      type: Number
      defaultValue: 40
      optional: true
      bind_to_instance: false

    extra_windows_button_template:
      # The template we'll use for the extra windows button, if such button is required
      # (not enough horizontal space on window)
      type: String
      optional: false
      bind_to_instance: false

    window_container_classes:
      type: String
      defaultValue: ""
      optional: true
      bind_to_instance: false

    data_fields_to_ignore_when_cmp_changes:
      # Changes to window_def data will trigger re-rendering of the window, but, changes to fields listed under this option, are ignored. Read more under @setWindows()
      type: [String]
      optional: true
      defaultValue: null
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

BottomWindowsWireframe = (options) ->
  # skeleton-version: v0.0.11-client-only

  # Developer, avoid changing this constuctor, to do stuff on init
  # for use below the: @_immediateInit()

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("justdo-bottom-windows-wireframe")

  @logger.debug "Init begin"
  @JA = JustdoAnalytics.setupConstructorJA(@, "justdo-bottom-windows-wireframe")

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

Util.inherits BottomWindowsWireframe, EventEmitter

_.extend BottomWindowsWireframe.prototype,
  onDestroy: (proc) ->
    # not to be confused with @destroy, onDestroy registers procedures to be called by @destroy()
    @_on_destroy_procedures.push proc

    return

  _error: JustdoHelpers.constructor_error
