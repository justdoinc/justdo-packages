Template.tutorial.helpers
  tutorialManager: -> Template.instance().tm = new TutorialManager(@, Template.instance())

Template.tutorial.onCreated ->
  retry_count = 5
  # Add resizer on first render
  @resizer = =>
    # XXX condiser DRYing with @tm.reposition()
    $spot = @$(".spotlight")
    $modal = @$(".modal-dialog")
    [spotCSS, modalCSS] = @tm.getPositions()
    # Don't animate, just move
    $spot.css(spotCSS)
    $modal.css(modalCSS)

    # Sometimes the element doesn't exist, wait 300ms and try again, the DOM
    # may not be ready yet.
    if @tm.retryGetPositions == true and retry_count > 0
      retry_count -= 1
      Meteor.setTimeout @resizer, 300
    else
      retry_count = 5

Template.tutorial.onRendered ->
  # attach a window resize handler
  $(window).on('resize', @resizer)
  $(window).on('scroll', @resizer)

  # Make modal draggable so it can be moved out of the way if necessary
  $modal = @$(".modal-dialog")
  $modal.drags
    handle: ".modal-footer"

  @autorun =>
    current_step = @tm.currentStep()
    current_step_obj = @tm.currentStepObject()

    # nextStepTrigger handling
    if (nextStepTrigger = current_step_obj.nextStepTrigger)?
      if nextStepTrigger(@)
        if current_step == (@tm.steps.length - 1)
          @tm.finish()
        else
          @tm.next()

    # prevStepTrigger handling
    if current_step != 0
      if (prevStepTrigger = current_step_obj.prevStepTrigger)?
        if prevStepTrigger(@)
          @tm.prev()

  return

Template.tutorial.destroyed = ->
  # Take off the resize watcher
  $(window).off('resize', @resizer) if @resizer
  $(window).off('scroll', @resizer) if @resizer

  @resizer = null

Template.tutorial.helpers
  content: ->
    # Run load function, if any
    # Don't run it reactively in case it accesses reactive variables
    if (func = @currentLoadFunc())?
      Deps.nonreactive =>
        func(@)

    tutorialInstance = Template.instance()

    # Move things where they should go, after the template renders
    Tracker.autorun (c) =>
      # Run resizer in a reactive computation to allow
      # the spot option to be a reactive function
      Meteor.defer =>
        inner_c = Tracker.autorun () => tutorialInstance?.resizer?()
        c.onStop () => inner_c.stop()

    # Template will render with tutorial as the data context
    # This function is reactive; the above will run whenever the context changes
    return @currentTemplate()

Template.tutorial.events
  "click": (e) ->
    # Don't propogate click & mousedowns to avoid dropdowns hiding if the user
    # focus on the modal (the user likely to do that out of instinct
    # when reading the text)

    if $(e.target).closest(".tutorial-close-button").length > 0
      # Don't interfere with the X button
      return

    e.stopPropagation()

    return

  "mousedown": (e) ->
    # Don't propogate click & mousedowns to avoid dropdowns hiding if the user
    # focus on the modal (the user likely to do that out of instinct
    # when reading the text)

    e.stopPropagation()

    return

  "click .action-tutorial-finish": -> @finish()

Template._tutorial_buttons.events =
  "click .action-tutorial-back": -> @prev()
  "click .action-tutorial-next": -> @next()
  "click .action-tutorial-finish": -> @finish()
