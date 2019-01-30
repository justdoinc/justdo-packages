_.extend JustdoTutorials.prototype,
  getTutorialContext: (id) ->
    # Returns an object with the following properties
    #
    # tutorial_manager_options:
    #
    #   The tutorial manager options for tutorial id.
    #
    #   Read more about these options in meteor-tutorials/README.md
    #   note that our fork changed these options slightly search for
    #   "JustDo fork" to find the differences from the original
    #   meteor-tutorials

    if not (tutorial = JustdoTutorials.tutorials[id])?
      throw @_error "unknown-tutorial-id", "Unknown tutorial id: #{id}"

    {
      steps,
      breakCondition
    } = tutorial

    tutorial_context = {}

    steps = _.map steps, (step, step_id) ->
      {
        title,
        content,
        prefix_title_with_step_count,
        spot,
        only_one_spot,
        show_next_button,
        show_back_button,
        prevStepTrigger,
        nextStepTrigger,
        onLoad
      } = step

      step_obj = {
        spot: spot,
        show_next_button: show_next_button,
        show_back_button: show_back_button,
        only_one_spot: only_one_spot
      }

      template = null
      if title?
        titleFormatter = ->
          """
          <h4>
            #{if prefix_title_with_step_count then "Step #{step_id + 1}: " else ""}
            #{if _.isFunction title then title() else title}
          </h4>
          """
      if not titleFormatter?
        # If title isn't set, content must be set
        template = JustdoHelpers.getBlazeTemplateForHtml(content)
      else if not content?
        # If title isn't set, title must be set
        template = JustdoHelpers.getBlazeTemplateForHtml(titleFormatter)
      else # both exists! - combine the two into one template
        compound = ->
          titleFormatter() + (if _.isFunction content then content() else content)
        template = JustdoHelpers.getBlazeTemplateForHtml(compound)
      step_obj.template = template

      if prevStepTrigger?
        _.extend step_obj,
          prevStepTrigger: (tutorial_manager) -> prevStepTrigger(tutorial_context, tutorial_manager)

      if nextStepTrigger?
        _.extend step_obj,
          nextStepTrigger: (tutorial_manager) -> nextStepTrigger(tutorial_context, tutorial_manager)

      if onLoad?
        _.extend step_obj,
          onLoad: (tutorial_manager) -> onLoad(tutorial_context, tutorial_manager)

      return step_obj

    tutorial_manager_options = {
      steps: steps
      onFinish: =>
        @exitActiveTutorial()

        return
    }

    _.extend tutorial_context, {
      id: id,
      tutorial_view: null, # will be set to the blaze view upon init
      tutorial_manager_options: tutorial_manager_options,
      onFinish: tutorial.onFinish
      storage: new ReactiveDict()
    }

    if breakCondition?
      tutorial_context.breakCondition = breakCondition

    return tutorial_context

  renderTutorial: (id) ->
    tutorial_context = @getTutorialContext(id)
    {tutorial_manager_options, breakCondition} = tutorial_context

    if @current_tutorial?
      @exitActiveTutorial()

    tutorial_context.tutorial_view =
      Blaze.renderWithData Template.tutorial, tutorial_manager_options, $('body')[0]

    @current_tutorial = tutorial_context

    if breakCondition?
      Tracker.nonreactive =>
        # Isolated reactive context
        @breakConditionComputation = Tracker.autorun =>
          if breakCondition(tutorial_context)
            @logger.debug "tutorial #{id} breakCondition triggered"

            @exitActiveTutorial()

          return

    return

  exitActiveTutorial: ->
    if (tutorial_context = @current_tutorial)?
      JustdoHelpers.callCb tutorial_context.onFinish # calls only if exists and is function

      Blaze.remove tutorial_context.tutorial_view

      @current_tutorial = null

      @stopBreakConditionComputation()

    return

  stopBreakConditionComputation: ->
    if @breakConditionComputation?
      @breakConditionComputation.stop()
      @breakConditionComputation = null

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @exitActiveTutorial()

    @stopBreakConditionComputation()

    @destroyed = true

    @logger.debug "Destroyed"

    return

# Add more resize triggering events, unique to justdo, to meteor-tutorials
Template.tutorial.onRendered ->
  # meteor-tutorials set @resizer to null in their original
  # onDestroyed that is called before our, we therefore need
  # to keep a reference to it
  @justdo_resizer_copy = @resizer
  $(".app-wrapper").on "scroll", @justdo_resizer_copy
  $(".slick-viewport").on "scroll", @justdo_resizer_copy

Template.tutorial.onDestroyed ->
  $(".app-wrapper").off("scroll", @justdo_resizer_copy) if @justdo_resizer_copy
  $(".slick-viewport").off("scroll", @justdo_resizer_copy) if @justdo_resizer_copy

  @justdo_resizer_copy = null