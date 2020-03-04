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
    console.log "Plugin #{JustdoKanban.project_custom_feature_id} installed on project #{project_doc._id}"

    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    console.log "Plugin #{JustdoKanban.project_custom_feature_id} removed from project #{project_doc._id}"

    return


  createKanban: (task_id, user_id) ->
    kanban = @kanbans.findOne(task_id)

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

      @kanbans.insert kanban_config
    return

  addSubTask: (parent_task_id, options, user_id) ->
    new_task_id = APP.projects._grid_data_com.addChild(
      "/" + parent_task_id + "/",
      project_id: options.project_id
      title: options.title
      ,
      user_id
    )

    JD.collections.Tasks.update({_id: new_task_id}, {$set: {"#{options.state}": options.board}})
    return

  removeSubTask: (parent_task_id, subtask_id, user_id) ->
    try
      parentId = "parents." + subtask_id
      childTasks = APP.collections.Tasks.find({"#{parentId}": {$exists: true}}).fetch()

      if childTasks.length > 0
        throw new Error "Task has child tasks and can't be removed."

      APP.projects._grid_data_com.removeParent("/#{parent_task_id}/#{subtask_id}/", user_id)
    catch error
      return {error: error.message}
    return

  setMemberFilter: (task_id, active_member_id, user_id) ->
    @kanbans.update(task_id, {$set: {"#{user_id}.memberFilter": active_member_id}})
    return

  setSortBy: (task_id, sortBy, reverse, user_id) ->
    @kanbans.update(task_id, {$set: {"#{user_id}.sortBy.option": sortBy, "#{user_id}.sortBy.reverse": reverse}})
    return

  addState: (task_id, state_object, user_id) ->
    state_id = state_object.field_id
    kanban = @kanbans.findOne(task_id)

    new_state = {
      "field_id": state_object.field_id,
      "label": state_object.label,
      "field_options": state_object.field_options
    }

    for option in new_state.field_options.select_options
      option.visible = true
      option.limit = null

    if !kanban[user_id].states[state_id]?
      @kanbans.update(task_id, {$set: {"#{user_id}.states.#{state_id}": new_state}})
    return

  updateStateOption: (task_id, state_id, option_id, option_label, new_value, user_id) ->
    kanban = @kanbans.findOne(task_id)
    options = kanban[user_id].states[state_id].field_options.select_options

    for option in options
      if option.option_id == option_id
        option[option_label] = new_value

    @kanbans.update(task_id, {$set: {"#{user_id}.states.#{state_id}.field_options.select_options": options}})

    return
