_.extend JustdoKanban.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  performInstallProcedures: (project_doc, user_id) ->
    # Called when plugin installed for project project_doc._id
    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    return

  createKanban: (task_id, user_id) ->
    kanban = @kanbans_collection.findOne(task_id)

    if !kanban?
      kanban_config = {
        "_id": task_id
        "#{user_id}": {
          "memberFilter": null,
          "sortBy": { "option": "priority", "reverse": true},
          "states": {
            "state": {
              "field_id": "state",
              "label": "State"
              "field_options": {
                select_options: [
                  {"option_id": "pending", "label": "Pending", "visible": true, "limit": null},
                  {"option_id": "in-progress", "label": "In progress", "visible": true, "limit": null},
                  {"option_id": "done", "label": "Done", "visible": true, "limit": null},
                  {"option_id": "will-not-do", "label": "Cancelled", "visible": false, "limit": null},
                  {"option_id": "on-hold", "label": "On hold", "visible": false, "limit": null},
                  {"option_id": "duplicate", "label": "Duplicate", "visible": false, "limit": null},
                  {"option_id": "nil", "label": "No State", "visible": false, "limit": null},
                ]
              }
            }
          }
        }
      }

      @kanbans_collection.insert kanban_config
    return

  setMemberFilter: (task_id, active_member_id, user_id) ->
    @kanbans_collection.update(task_id, {$set: {"#{user_id}.memberFilter": active_member_id}})
    return

  setSortBy: (task_id, sortBy, reverse, user_id) ->
    @kanbans_collection.update(task_id, {$set: {"#{user_id}.sortBy.option": sortBy, "#{user_id}.sortBy.reverse": reverse}})
    return

  addState: (task_id, state_object, user_id) ->
    state_id = state_object.field_id
    kanban = @kanbans_collection.findOne(task_id)

    new_state = {
      "field_id": state_object.field_id,
      "label": state_object.label,
      "field_options": state_object.field_options
    }

    for option in new_state.field_options.select_options
      option.visible = true
      option.limit = null

    if not kanban[user_id].states[state_id]?
      @kanbans_collection.update(task_id, {$set: {"#{user_id}.states.#{state_id}": new_state}})
    return

  updateStateOption: (task_id, state_id, option_id, option_label, new_value, user_id) ->
    kanban = @kanbans_collection.findOne(task_id)
    options = kanban[user_id].states[state_id].field_options.select_options

    for option in options
      if option.option_id == option_id
        option[option_label] = new_value

    @kanbans_collection.update(task_id, {$set: {"#{user_id}.states.#{state_id}.field_options.select_options": options}})

    return
