_.extend PACK.modules.required_actions,
  initServer: ->
    @required_actions_col_name = @options.local_required_actions_collection_name

    @_setupPublication()

    @_setupIndices()

  _setupPublication: ->
    self = @

    Meteor.publish "requiredActions", (project_id) ->
      required_actions_trackers = {} # keys are required actions types id

      self.projectMembershipRequirementPubManager @, project_id,
        success: ->
          for type, def of PACK.required_actions_definitions
            do (type, def) =>
              type_custom_publication_this = Object.create(@)

              _.extend type_custom_publication_this,
                normalizedId: (id) ->
                  # Gets the arbitrary id provided by the required action tracker
                  # and returns a normalizedId
                  # Note: we add the project_id to the key to avoid collisions in
                  # case a certain task will be in more than one project and both
                  # publications will be on at once
                  return "#{project_id}::#{type}::#{id}"

                required_action_added: (id, required_action_date, data) ->
                  doc =
                    type: type
                    project_id: project_id
                    date: required_action_date
                    # data: data # OBSOLETE
                    #            # Since DDP replaces and doesn't perform merge
                    #            # of sub-documents when they update. Changes that
                    #            # doesn't involve all the fields will result
                    #            # in the client having only partial data upon
                    #            # change. A flow that led us to discontinue
                    #            # data as a separate value and instead having
                    #            # its fields in the top level

                  _.extend doc, data

                  @added self.required_actions_col_name, @normalizedId(id), doc


                required_action_changed: (id, required_action_date, data) ->
                  updates =
                    date: required_action_date
                    # data: data # OBSOLETE, read above why

                  _.extend updates, data

                  @changed self.required_actions_col_name, @normalizedId(id), updates

                required_action_removed: (id) ->
                  @removed self.required_actions_col_name, @normalizedId(id)

              required_actions_trackers[type] =
                def.tracker.call type_custom_publication_this, self, project_id

        stop: ->
          for required_actions_type, required_actions_tracker of required_actions_trackers
            required_actions_tracker.stop()

            delete required_actions_trackers[required_actions_type]

      return # undefined

  _setupIndices: ->
    for type, def of PACK.required_actions_definitions
      if def.setupMongoIndices?
        def.setupMongoIndices.call @
