default_options = {}

options_schema =
  both:
    justdo_chat:
      type: "skip-type-check"
      optional: false
      bind_to_instance: true

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

JustdoChatBottomWindowsManager = (options) ->
  # skeleton-version: v0.0.11-onepage_skeleton

  # Developer, avoid changing this constuctor, to do stuff on init
  # for both server & client, use below the: @_bothImmediateInit()

  EventEmitter.call this

  @destroyed = false

  @logger = Logger.get("justdo-chat-bottom-windows-manager")

  @logger.debug "Init begin"
  @JA = JustdoAnalytics.setupConstructorJA(@, "justdo-chat-bottom-windows-manager")

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

Util.inherits JustdoChatBottomWindowsManager, EventEmitter

_.extend JustdoChatBottomWindowsManager.prototype,
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
    @bottom_windows_subscription = @justdo_chat.subscribeBottomWindows()

    @onDestroy =>
      @bottom_windows_subscription.stop()

    @bottom_windows_wireframe = new BottomWindowsWireframe
      right_margin: 30
      left_margin: 30
      open_window_width: 290
      min_window_width: 120
      width_between_windows: 7
      width_between_windows_to_extra_windows_button: 10
      extra_windows_button_width: 40

      extra_windows_button_template: "chat_bottom_windows_extra_windows_button"

      window_container_classes: "jdc-bottom-windows"

    @_setupBottomWindowsTracker()

    @_current_bottom_windows_defs = []

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  makeWindowVisible: (channel_type, channel_identifier, options) ->
    # If a window doesn't exists already for the channel, create one, make sure it is placed
    # in a place where it is visible to the user (not in the extra windows button).
    #
    # If a window exists already, if the window is in the extra windows button, bring it to the
    # view. Otherwise, do nothing.

    # XXX at the moment, we just use the put_first: true option, in the future,
    # we will probably need a more sufisticated sorting algorithm, putting current requested
    # window on the far right position, is the easiest to implement 
    options = _.extend {put_first: true, onComplete: undefined}, options # if put_first is false, we put last.

    if options.put_first
      sort = 1
    else
      sort = -1

    current_order =
      APP.collections.JDChatBottomWindowsChannels.findOne({}, {sort: {order: sort}, allow_undefined_fields: true})?.order

    if not current_order?
      order = 0
    else
      order = current_order - sort


    if _.isFunction options.onComplete
      onComplete = =>
        channel_conf =
          tasks_collection: APP.justdo_chat.bottom_windows_supplementary_pseudo_collections.tasks
          task_id: channel_identifier.task_id

        channel_object =
          @justdo_chat.generateClientChannelObject channel_type, channel_conf

        serialized_identifier =
          channel_object._getChannelSerializedIdentifier()

        tracker = Tracker.autorun (c) =>
          windows_arrangement = @bottom_windows_wireframe.getWindowsArrangement()

          if windows_arrangement?
            for window_arrangement_def in windows_arrangement
              if window_arrangement_def.id == serialized_identifier
                if window_arrangement_def.rendered_state == "open"
                  options.onComplete(window_arrangement_def)

                  c.stop()

          return

        setTimeout ->
          tracker.stop() # after 1 seconds stop the tracker regardless, to avoid lingering trackers in case window failed to open, for whatever reason.
        , 1000

        return

    return @_setBottomWindow(channel_type, channel_identifier, {order: order, state: "open"}, onComplete)

  removeWindow: (channel_type, channel_identifier) ->
    return @_removeBottomWindow(channel_type, channel_identifier)

  _setBottomWindow: (channel_type, channel_identifier, window_settings, cb) ->
    # This method is a low-level proxy method to the DDP method that sets/updates a bottom window
    # for a channel. It shouldn't be called directly, to request a window opening
    # use @makeWindowVisible()

    return @justdo_chat.setBottomWindow(channel_type, channel_identifier, window_settings, cb)

  _removeBottomWindow: (channel_type, channel_identifier, cb) ->
    # This method is a low-level proxy method to the DDP method that removes a bottom window
    # for a channel. It shouldn't be called directly, to request a window opening
    # use @removeWindow()

    return @justdo_chat.removeBottomWindow(channel_type, channel_identifier, cb)

  _setupBottomWindowsTracker: ->
    @_bottomWindowsTracker = Tracker.autorun =>
      bottom_windows_channels =
        APP.collections.JDChatBottomWindowsChannels.find({}, {sort: {order: 1}, allow_undefined_fields: true}).fetch()

      bottom_windows_defs = []
      for bottom_window_channel in bottom_windows_channels
        bottom_windows_defs.push @_getWindowDefForBottomWindowChannelDoc(bottom_window_channel)

      @bottom_windows_wireframe.setWindows bottom_windows_defs

      @_current_bottom_windows_defs = bottom_windows_defs

      return

    @onDestroy =>
      @_bottomWindowsTracker.stop()

      return

    return

  _getWindowDefForBottomWindowChannelDoc: (bottom_window_channel) ->
    if (channel_type = bottom_window_channel.channel_type) == "task"
      open_template = "chat_bottom_windows_task_open"
      min_template = "chat_bottom_windows_task_min"

      template_data = 
        project_id: bottom_window_channel.project_id
        task_id: bottom_window_channel.task_id

      channel_conf =
        tasks_collection: APP.justdo_chat.bottom_windows_supplementary_pseudo_collections.tasks
        task_id: bottom_window_channel.task_id

      channel_object =
        @justdo_chat.generateClientChannelObject channel_type, channel_conf

    window_def = {
      id: channel_object._getChannelSerializedIdentifier()
      type: channel_type
      window_state: bottom_window_channel.state
      open_template: open_template
      min_template: min_template
      channel_object: channel_object
      data: template_data
    }

    return window_def

  _getWindowDefTitle: (window_def) ->
    if window_def.type == "task"
      task_doc =
        APP.justdo_chat.bottom_windows_supplementary_pseudo_collections.tasks.findOne(window_def.data.task_id)

      title = "<b>##{task_doc.seqId}</b>"

      if not _.isEmpty(task_doc.title)
        title += "<b>:</b> #{JustdoHelpers.ellipsis(task_doc.title, 80)}"

      return title

    return ""

  getExtraWindows: ->
    # Returns the windows defs of the windows that belongs in the extra windows button.
    # adds an extra property 'title' with the window proposed title.
    extra_windows_ids = @bottom_windows_wireframe.getExtraWindows()

    extra_windows_defs = []
    for bottom_window_def in @_current_bottom_windows_defs
      if bottom_window_def.id in extra_windows_ids
        bottom_window_def = _.extend(bottom_window_def) # shallow copy

        bottom_window_def.title = @_getWindowDefTitle(bottom_window_def)

        extra_windows_defs.push bottom_window_def

    return extra_windows_defs

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

share.JustdoChatBottomWindowsManager = JustdoChatBottomWindowsManager