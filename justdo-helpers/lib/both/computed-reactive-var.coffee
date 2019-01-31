labeled_crvs_objects = {} # {label_name: computed reactive var obj}

newAutoStoppedComputedReactiveVar = (label, comp_fn, options) ->
  # Creates a computed reactive var that destroyed automatically
  # if enclosing computation invalidates.
  crv = newComputedReactiveVar(label, comp_fn, options)

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      crv.stop()

  return crv

newComputedReactiveVar = (label, comp_fn, options) ->
  # Returns a strucutre based on a reactive var and a
  # Tracker computation running comp_fn
  #
  # label protects us from unintended multiple instances.
  # If a crv is created with label "x", following requests to
  # init crv with the same label, will return the same
  # crv, regardless of the provided comp_fn.
  # A new crv will be created only once the current crv
  # for the label will be stopped.
  #
  # You can set label to null to disable the labels feature.
  #
  # comp_fn is called with the computed reactive var object
  # as its first argument.
  #
  # Motivation for computed reactive var
  # ------------------------------------
  #
  # The real power of this helper is to extract from a
  # reactive resource, called in comp_fn, only a specific
  # property, returned by comp_fn, we want to have reactivity
  # upon its change.
  #
  # You must keep in mind that this power is limited in the following
  # way: If comp_fn got invalidated, only in the next flush the
  # value returned by the getter will be in sync.
  #
  # To overcome this we introduced getSync() that use the getter
  # to trigger reactivity but always returns the synced value.
  #
  # Main drawback of getSync()
  # --------------------------
  #
  # The main drawback of getSync though is that if upon call
  # the reactive var was out of sync, on the next flush getSync
  # will invalidate together with the sync of the reactive var,
  # and will return the exact same value*, causing
  # a redundant invalidation in depending computations.
  #
  # * as long as the value returned by comp_fn didn't change
  # between first call to flush
  #
  # Options:
  #
  #   init_val: (default: null) sets the initial value
  #   reactiveVarEqualsFunc: (default: undefined) the equals func to test whether
  #                          value changed and invalidation is needed. If undefined,
  #                          we'll use the default reactive var equals func.
  #   events: see Events section below
  #   recomp_interval: (default: null) can be set to the number
  #                   of milliseconds we will use to set an interval that calls
  #                   comp_fn, to check for changes in its output, even if it
  #                   didn't invalidated. (useful, when comp_fn isn't reactive...)
  #
  # Events
  # ------
  #
  # Returns an object inheriting from EventEmitter with the following props:
  #
  # reactive_var: a reactive var containing comp_fn output
  # stop(): stops the computation.
  #
  # Events:
  # compute: called before every comp_fn run
  # computed: called after every comp_fn run
  # stop: called after all stop procedure performed
  #

  init = -> new Structure(label, comp_fn, options)

  if not label?
    # If label is null, just init
    return init()

  # If crv already exist for label, return same one.
  if (existing_crv_obj = labeled_crvs_objects[label])?
    return existing_crv_obj

  # create new crv for label
  options = _.extend {}, options # Don't change original obj

  if not _.isArray(options.events)
    options.events = []

  options.events.push(
    ["once", "stop", ->
      delete labeled_crvs_objects[label]
    ]
  )

  return labeled_crvs_objects[label] = init()

default_options =
  init_val: null
  reactiveVarEqualsFunc: undefined # Use the default reactive var equals func
  events: [] # events to bind in init process
             # Items structure: ["hook-type", "event-name", cb]
             # Example item: ["once", "stop", ->]
  recomp_interval: null

Structure = (label, comp_fn, options) ->
  EventEmitter.call this

  @destroyed = false

  @options = _.extend {}, default_options, options

  @label = label
  @comp_fn = comp_fn

  @logger = Logger.get "ReactiveVarComp #{label}"

  for item in @options.events
    [hook_type, event_name, event_cb] = item

    @[hook_type](event_name, event_cb)

  @reactive_var = new ReactiveVar @options.init_val, @options.reactiveVarEqualsFunc

  if @options.recomp_interval
    @interval = setInterval =>
      @reactive_var.set @comp_fn(@)
    , @options.recomp_interval

  @computation = Tracker.nonreactive =>
    Tracker.autorun =>
      @emit "compute"

      @reactive_var.set @comp_fn(@)

      @emit "computed"

  return @

Util.inherits Structure, EventEmitter

_.extend Structure.prototype,
  get: ->
    if @destroyed
      # This is for case invalidation occurs but flushing
      # happens after @destroy(), in such a case, @reactive_var
      # will be null.
      return @options.init_val

    # Make sure to read documentation above before use!
    @reactive_var.get()

  getSync: ->
    if @destroyed
      # See comment for same if at @get()
      return @options.init_val

    # Make sure to read documentation above before use!
    @reactive_var.get() # only to trigger reactivity

    # always get the up-to-date value, run in a nonreactive
    # so only reactive_var will trigger invalidation.
    return Tracker.nonreactive => @comp_fn(@)

  stop: ->
    if @destroyed
      # Destroyed already
      return

    if @interval?
      clearInterval(@interval)

    if @computation?
      @destroyed = true

      @computation.stop()

      # Release to garbage collector
      @computation = null
      @reactive_var.set null
      @reactive_var = null

      @emit "stop"
      @removeAllListeners()

_.extend JustdoHelpers,
  newComputedReactiveVar: newComputedReactiveVar
  newAutoStoppedComputedReactiveVar: newAutoStoppedComputedReactiveVar
