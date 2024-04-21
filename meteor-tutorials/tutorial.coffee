defaultSpot = ->
  top: 0
  left: 0
  bottom: $(window).height()
  right: $(window).width()

defaultModal = ->
  # ensure the modal still fits on small screens
  width = Math.min( $(window).width(), 560)
  return {
    top: "10%"
    left: "50%"
    width: width
    "margin-left": -width / 2 # keep the modal centered
  }

spotPadding = 10 # How much to expand the spotlight on all sides
modalBuffer = 20 # How much to separate the modal from the spotlight

_sessionKeyPrefix = "_tutorial_step_"

class @TutorialManager
  constructor: (options, tutorial_template_instance) ->
    check(options, Object)
    check(options.steps, Array)

    @steps = options.steps
    @onFinish = options.onFinish || null
    @emitter = options.emitter

    @tutorial_template_instance = tutorial_template_instance

    # Grab existing step if it exists - but don't grab it reactively,
    # or this template will keep reloading
    if options.id?
      @sessionKey = _sessionKeyPrefix + options.id
      @step = Deps.nonreactive => Session.get(@sessionKey)

    @step ?= 0
    @stepDep = new Deps.Dependency
    @finishedDep = new Deps.Dependency

    # Build array of reactive dependencies for events
    return unless @emitter
    @buildActionDeps()

  reposition: ->
    if not @tutorial_template_instance.view.isRendered
      # console.log "Not rendered yet, nothing to do"

      return

    $spot = @tutorial_template_instance.$(".spotlight")
    $modal = @tutorial_template_instance.$(".modal-dialog")
    [spotCSS, modalCSS] = @getPositions()
    # Don't animate, just move
    $spot.css(spotCSS)
    $modal.css(modalCSS)

    return

  buildActionDeps: ->
    @actionDeps = []
    for i, step of @steps
      if step.require
        check(step.require.event, String)
        dep = new Deps.Dependency
        validator = step.require.validator
        check(validator, Function) if validator
        dep.completed = false
        @actionDeps.push(dep)

        # Bind a function to watch for this event
        checker = (->
          # Bind validator dep in closure
          val = validator
          d = dep
          return (...args) ->
            actionCompleted = if val then val.apply(this, args) else true
            if actionCompleted
              d.completed = true
              d.changed()
        )()
        @emitter.on step.require.event, checker

      else
        @actionDeps.push(null)

  # Store steps in Session variable when they change
  prev: ->
    return if @step is 0
    @step--
    @stepDep.changed()
    Session.set(@sessionKey, @step) if @sessionKey?

  next: ->
    return if @step is (@steps.length - 1)
    @step++
    @stepDep.changed()
    Session.set(@sessionKey, @step) if @sessionKey?

  # Process finish click. If there is a function to call, only call it once.
  finish: ->
    if @onFinish?
      @finishedDep.finished = true
      @finishedDep.changed()

      # If the user restarts this tutorial it should start at the beginning
      if @sessionKey?
        Session.set(@sessionKey, null)

      @onFinish()

  prevEnabled: ->
    @stepDep.depend()

    {show_prev_button} = @currentStepObject()

    if not show_prev_button? or not show_prev_button
      return false

    return @step > 0

  nextEnabled: ->
    @stepDep.depend()

    {show_next_button} = @currentStepObject()

    if not show_next_button? or not show_next_button
      return false

    return @step < (@steps.length - 1) and @stepCompleted()

  stepCompleted: ->
    @stepDep.depend()
    actionDep = @actionDeps?[@step]
    return true unless actionDep

    actionDep.depend()
    return actionDep.completed

  finishEnabled: ->
    @stepDep.depend()

    {show_next_button} = @currentStepObject()

    if not show_next_button? or not show_next_button
      return false

    return @step is @steps.length - 1 and @stepCompleted()

  # Debounce for finish button
  finishPending: ->
    @finishedDep.depend()
    return @finishedDep.finished

  currentStep: ->
    @stepDep.depend()

    return @step

  currentStepObject: ->
    return @steps[@currentStep()]

  currentTemplate: ->
    @stepDep.depend()
    template = @steps[@step].template
    # Support both string and direct references.
    return if _.isString(template) then Template[template] else template

  # Stuff below is currently not reactive
  currentLoadFunc: ->
    return @steps[@step].onLoad

  getPositions: ->
    @retryGetPositions = false

    # @stepDep.depend() if we want reactivity
    selector = @steps[@step].spot
    if _.isFunction(selector)
      selector = selector()
    return [ defaultSpot(), defaultModal() ] unless selector?

    items = $(selector)
    if items.length is 0
      @retryGetPositions = true
      return [ defaultSpot(), defaultModal() ]

    if @steps[@step].only_one_spot == true
      items = items.first()

    # Compute spot and modal positions
    hull =
      top: 5000
      left: 5000
      bottom: 5000
      right: 5000

    items.each (i) ->
      $el = $(this)
      # outer height/width used here: http://api.jquery.com/outerHeight/
      # Second computation adds support for *SOME* SVG elements
      elWidth = $el.outerWidth() || parseInt($el.attr("width"))
      elHeight = $el.outerHeight() || parseInt($el.attr("height"))
      offset = $el.offset()
      
      hull.top = Math.min(hull.top, offset.top)
      hull.left = Math.min(hull.left, offset.left)      
      hull.bottom = Math.min(hull.bottom, $(window).height() - offset.top - elHeight)
      hull.right = Math.min(hull.right, $(window).width() - offset.left - elWidth)

    # enlarge spotlight slightly and find largest side
    maxKey = null
    maxVal = 0
    for k,v of hull
      if v > maxVal
        maxKey = k
        maxVal = v
      hull[k] = Math.max(0, v - spotPadding)

    modalStyle = defaultModal()

    modal = switch
      # When the spotlight is very large, stick the modal in the center and let the user deal with it
      when maxVal < 200 then modalStyle
      # Otherwise put modal on the side with the most space
      when maxKey is "top" # go as close to top as possible
        $.extend {}, modalStyle, { top: "5%" }
      when maxKey is "bottom" # start from bottom of spot
        $.extend {}, modalStyle,
          top: $(window).height() - hull.bottom + modalBuffer
      when maxKey is "left"
        width = Math.min(hull.left - 2*modalBuffer, modalStyle.width)
        $.extend {}, modalStyle,
          left: hull.left / 2
          width: width
          "margin-left": -width/2
      when maxKey is "right"
        width = Math.min(hull.right - 2*modalBuffer, modalStyle.width)
        $.extend {}, modalStyle,
          left: $(window).width() - hull.right / 2
          width: width
          "margin-left": -width/2
    return [ hull, modal ]
