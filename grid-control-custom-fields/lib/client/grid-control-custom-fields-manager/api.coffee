_.extend GridControlCustomFieldsManager.prototype,
  _immediateInit: ->
    @custom_fields_definitions = {}
    @custom_fields_definitions_dep = new Tracker.Dependency()

    @custom_fields_schema = {}
    @custom_fields_schema_dep = new Tracker.Dependency()

    @custom_fields_definitions_reactive_var_tracker = null
    if @options.custom_fields_definitions instanceof ReactiveVar
      @custom_fields_definitions_reactive_var_tracker = Tracker.autorun =>
        # Note, if @options.custom_fields_definitions is a ReactiveVar,
        # we init @custom_fields_definitions, @custom_fields_schema
        # as it much easier to update them this way (no need for any diff,
        # updates, etc.)
        @custom_fields_definitions = {}
        @custom_fields_schema = {}

        new_custom_fields_definitions =
          @options.custom_fields_definitions.get()

        @addCustomFields(new_custom_fields_definitions)

        if @options.custom_states_definitions instanceof ReactiveVar
          if (custom_states_definitions = @options.custom_states_definitions.get())? and _.isArray(custom_states_definitions)
            state_schema = _.extend {}, APP.collections.Tasks.simpleSchema()._schema.state
            state_schema.grid_removed_values = state_schema.grid_values # Make all the values available under removed values
            state_schema.grid_values = {}

            for state_def, index in custom_states_definitions
              # First, copy the original value
              state_schema.grid_values[state_def.state_id] = _.extend {}, state_schema.grid_removed_values[state_def.state_id]
              
              if not state_def.bg_color? or state_def.bg_color == "#00000000" # 8 0s means transparent (anything with last 2 zeros means)
                delete state_schema.grid_values[state_def.state_id].bg_color
              else
                state_schema.grid_values[state_def.state_id].bg_color = state_def.bg_color

              state_schema.grid_values[state_def.state_id].txt = state_def.txt
              state_schema.grid_values[state_def.state_id].order = index

            state_schema.grid_values["nil"] = _.extend {}, state_schema.grid_removed_values["nil"]
            state_schema.grid_values["nil"].order = 100 # To ensure it'll always be last

            @custom_fields_schema.state = state_schema
    else if @options.custom_fields_definitions?
      # If exists, it has to be an object, due to options init (see init.coffee)

      @addCustomFields(@options.custom_fields_definitions)

    return

  _deferredInit: ->
    return

  getCustomFieldsSchema: ->
    @custom_fields_schema_dep.depend()

    return @custom_fields_schema

  getCustomFieldsDefinitions: ->
    @custom_fields_definitions_dep.depend()

    return @custom_fields_definitions

  addCustomFields: (custom_fields_definitions) ->
    # Don't do the following optimization, though tempting, sometimes we want to pass
    # empty opbject to addCustomFields just to trigger the changed() for the Dependencies
    # See the case of the @custom_fields_definitions_reactive_var_tracker where we init
    # the custom_fields_definitions/_schema and rely on @addCustomFields() to trigger
    # reactivity.

    # if _.isEmpty custom_fields_definitions
    #   return

    {custom_fields_definitions, custom_fields_schema} =
      GridControlCustomFields.getCleanCustomFieldsDefinitionAndDerivedSchema(custom_fields_definitions)

    _.extend(@custom_fields_schema, custom_fields_schema)
    @custom_fields_schema_dep.changed()

    _.extend(@custom_fields_definitions, custom_fields_definitions)
    @custom_fields_definitions_dep.changed()

    @emit "custom-fields-updated"

    return

  removeCustomFields: (custom_fields_ids) ->
    if _.isString custom_fields_ids
      custom_fields_ids = [custom_fields_ids]

    if _.isEmpty(custom_fields_ids)
      return

    changed = false
    for custom_field_id in custom_fields_ids
      if custom_field_id of @custom_fields_definitions
        changed = true
        delete @custom_fields_definitions[custom_field_id]
        delete @custom_fields_schema[custom_field_id]

    if changed
      @custom_fields_definitions_dep.changed()
      @custom_fields_schema_dep.changed()

      @emit "custom-fields-updated"

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    if @custom_fields_definitions_reactive_var_tracker?
      @custom_fields_definitions_reactive_var_tracker.stop()

      @custom_fields_definitions_reactive_var_tracker = null

    @destroyed = true

    @logger.debug "Destroyed"

    return