# Note static methods, not prototypical
_.extend JustdoTutorials,
  getRelevantTutorialsToState: ->
    # Returns an array of objects representing all the tutorials relevant for
    # the current state, ordered by the value returned by
    # their getRelevancyToState() - see tutorial-registrar.coffee
    # for more details.
    #
    # Array structure:
    #
    # [
    #   {
    #     tutorial_id
    #     tutorial
    #     
    #   },
    #   ...
    # ]

    non_sorted_non_filtered = _.map JustdoTutorials.tutorials, (tutorial, tutorial_id) ->
      relevancy_to_state = tutorial.getRelevancyToState()

      if not _.isNumber relevancy_to_state
        console.warn "getRelevantTutorialsToState: tutorial #{tutorial_id} getRelevancyToState() returned a non Number value, skipping"

        relevancy_to_state = -1

      # we want round numbers
      relevancy_to_state = Math.floor(relevancy_to_state)

      if relevancy_to_state < -1
        relevancy_to_state = -1

      if relevancy_to_state > 100
        relevancy_to_state = 100

      return {tutorial, tutorial_id: tutorial_id, relevancy_to_state: relevancy_to_state}

    non_sorted = _.filter non_sorted_non_filtered, (meta_tutorial_obj) -> meta_tutorial_obj.relevancy_to_state >= 0

    sorted = _.sortBy non_sorted, (meta_tutorial_obj) -> -1 * meta_tutorial_obj.relevancy_to_state

    return sorted