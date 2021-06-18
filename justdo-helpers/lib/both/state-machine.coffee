StateMachine = (conf) ->
  EventEmitter.call @

  @logger = Logger.get("justdo-state-machine")

  @state_id = null
  @state_attributes = {}
  @map = conf.states_map

  @events = conf.events

  init_state_found = false
  for state_id, state of @map
    if state.init_state is true
      @setState(state_id)

      init_state_found = true

      break

  if not init_state_found
    throw @_error("invalid-argument", "Map had no state configured as the init_state")

  return

Util.inherits StateMachine, EventEmitter

_.extend StateMachine.prototype,
  _error: JustdoHelpers.constructor_error

  _errors_types:
    _.extend {}, JustdoHelpers.common_errors_types,
      "state-flow-forbidden": "State change rejected"
      "state-exiting-validator-failed": "State exiting validation failed"
      "state-entering-validator-failed": "State entering validation failed"

  trigger: (event_name, ...args) -> @events[event_name].apply(@, args)

  getState: -> @state_id

  getStateAttr: -> @state_attributes

  replaceStateAttr: (new_state_attr) ->
    @state_attributes = _.extend {}, new_state_attr

    return

  clearStateAttr: ->
    @replaceStateAttr({})

    return

  extendStateAttr: (state_attr) ->
    _.extend(@state_attributes, state_attr)

    return

  setState: (target_state_id, state_options) ->
    if not (target_state_def = @map[target_state_id])?
      throw @_error("state-flow-forbidden", "Unknown state #{target_state_id}")

    if target_state_def.stateEnteringValidator?
      # Ensure that we can switch to the next state
      if (failed_message = target_state_def.stateEnteringValidator.call(@, state_options)) and _.isString(failed_message)
        throw @_error("state-entering-validator-failed", failed_message)

    if @state_id? # @state_id will be null only during init
      current_state_def = @map[@state_id]

      if not (next_state_conf = current_state_def.allowed_next_states[target_state_id])?
        throw @_error("state-flow-forbidden", "Switching from state '#{@state_id}' to state '#{target_state_id}' is not allowed")

      if current_state_def.stateExitingValidator?
        # Ensure that we can exit the current state
        if (failed_message = current_state_def.stateExitingValidator.call(@)) and _.isString(failed_message)
          throw @_error("state-exiting-validator-failed", failed_message)

      if next_state_conf.beforeStateDestroyer?
        next_state_conf.beforeStateDestroyer.call(@)

      # Call the current state destoryer
      current_state_def.stateDestroyer?.call(@)

    # Enter the target state
    @state_id = target_state_id
    target_state_def.stateSetter.call(@, state_options)

    return

JustdoHelpers.StateMachine = StateMachine