StepsSchema = new SimpleSchema
  title:
    # Can be either html string or a function that returns html string
    # if function is provided, will run in a reactive context (provided
    # by the blaze template in which it runs)
    label: "Step title"

    optional: true

    type: "skip-type-check" # Might be more than one type, so we can't use simple schema to validate

  prefix_title_with_step_count:
    # If set to true, only if title is set, we will prefix the title with
    # 'Step x: '
    defaultValue: true

    type: Boolean

  content:
    # Can be either html string or a function that returns html string
    # if function is provided, will run in a reactive context (provided
    # by the blaze template in which it runs)
    label: "Step content"

    optional: true

    type: "skip-type-check" # Might be more than one type, so we can't use simple schema to validate

  spot:
    # A jQuery Selector String, or a function that returns a jQuery Selector String
    # that selects the the elements to highlight - can be more than one
    # element.
    #
    # Read more about the spot option in meteor-tutorials/README.md
    # note that our fork changed meteor-tutorials options slightly search for
    # "JustDo fork" to find the differences from the original
    # meteor-tutorials

    label: "Spot"

    optional: true

    type: "skip-type-check" # Might be more than one type, so we can't use simple schema to validate

  prevStepTrigger:
    # A reactive function, we'll move to the previous step automatically
    # once this function will return true.
    #
    # Important! if this function returns true on step init - the previous step
    # will show immediately without the user noticing it (it will seem as if the
    # step didn't change).
    #
    # Ignored when set on first step
    #
    # Gets as its first parameter the tutorial context. To keep
    # information between computation invalidations you can make
    # use of the tutorial_context.storage reactive dictionary.
    #
    # Gets as its second parameter the tutorial manager object.

    label: "Preivous Step Trigger"

    optional: true

    type: Function

  nextStepTrigger:
    # A reactive function, we'll move to the next step automatically
    # once this function will return true.
    #
    # Important! if this function returns true on step init - the step
    # will be skipped without the user noticing it.
    #
    # Gets as its first parameter the tutorial context. To keep
    # information between computation invalidations you can make
    # use of the tutorial_context.storage reactive dictionary.
    #
    # Gets as its second parameter the tutorial manager object.

    label: "Next Step Trigger"

    optional: true

    type: Function

  onLoad:
    # A function to run on step load
    #
    # Helpful if you need to make sure your interface is in a certain state before displaying the tutorial contents.
    #
    # non-reactive
    #
    # Important! if this function returns true on step init - the step
    # will be skipped without the user noticing it.
    #
    # Gets as its first parameter the tutorial context. To keep
    # information between computation invalidations you can make
    # use of the tutorial_context.storage reactive dictionary.
    #
    # Gets as its second parameter the tutorial manager object.

    label: "onLoad"

    optional: true

    type: Function

  show_next_button:
    # Control both next & finish buttons
    type: Boolean

    defaultValue: false

  show_back_button:
    type: Boolean

    defaultValue: false

  only_one_spot:
    # Ignored if spot isn't set.
    #
    # Limit the highlighted spots to the first element returned by the jQuery
    # selector.
    #
    # Read more about the only_one_spot option in meteor-tutorials/README.md
    # note that our fork changed meteor-tutorials options slightly search for
    # "JustDo fork" to find the differences from the original
    # meteor-tutorials

    label: "Only one spot"

    type: Boolean

    defaultValue: false

TutorialsSchema = new SimpleSchema
  readable_name:
    label: "Tutorial Name"

    type: String

  breakCondition:
    # A reactive function, in any moment, if returns true the tutorial
    # will stop immediately.
    #
    # Gets as its first parameter the tutorial context. To keep
    # information between computation invalidations you can make
    # use of the tutorial_context.storage reactive dictionary.

    label: "Break Condition"

    optional: true

    type: Function

  getRelevancyToState:
    # A function that should return a number in the range [-1, 100]
    #
    # The returned value will be used by components such as the help
    # dropdown to determine whether the tutorial is relevant for the
    # current app state. Example a tutorial that teach the user how
    # to remove project members is irrelevant if the project doesn't
    # have members.
    #
    # A returned value of -1 means the tutorial is completely irrelevant
    # for the current app state and shouldn't (or even can't) run on it.
    #
    # Returned values in the range [0, 100] will be regarded as the
    # priority of the tutorial - 100 is the most important.
    #
    # Components should present relevant tutorials in their order of
    # importance.
    #
    # Can be Reactive Resource - but it is up to the using component
    # to decide whether or not to run in a Computation - so don't
    # assume Computation exists.
    type: Function

    defaultValue: -> -1

  steps:
    label: "Tutorials steps"

    type: [StepsSchema]

  onFinish:
    # If set, will be called when the tutorial is completed
    type: Function

    optional: true

JustdoTutorials.tutorials = {}

# Note static method, not prototypical
JustdoTutorials.registerTutorial = (id, tutorial_object) ->
  if id of JustdoTutorials.tutorials
    console.warn "Tutorial with id #{id} already exists, replacing"

  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      TutorialsSchema,
      tutorial_object,
      {self: self, throw_on_error: true}
    )
  tutorial_object = cleaned_val

  # For properties that can be of multiple types, we have to validate ourself
  if (steps = tutorial_object.steps)?
    _.each steps, (step) ->
      {title, content, spot} = step

      if title?
        if not _.isString(title) and not _.isFunction(title)
          throw new Meteor.Error "invalid-options", "Step property content must be a string or a function"

      if content?
        if not _.isString(content) and not _.isFunction(content)
          throw new Meteor.Error "invalid-options", "Step property content must be a string or a function"

      if not title? and not content?
        throw new Meteor.Error "invalid-options", "Step must have at least one of the following properties: title, content"

      if spot?
        # Spot is optional, but if provided, must be a string or a function
        if not _.isString(spot) and not _.isFunction(spot)
          throw new Meteor.Error "invalid-options", "Step property spot must be a string or a function"
 
      return

  JustdoTutorials.tutorials[id] = tutorial_object 

  return