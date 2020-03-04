_.extend JustdoKanban.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoKanban.project_custom_feature_id,
        installer: =>
          if JustdoKanban.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoKanban.pseudo_field_id,
              label: JustdoKanban.pseudo_field_label
              field_type: JustdoKanban.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 200

          @setupProjectPaneTab()

          return

        destroyer: =>
          if JustdoKanban.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoKanban.pseudo_field_id

          @destroyProjectPaneTab()

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return


  setupProjectPaneTab: ->
    APP.justdo_project_pane.registerTab
      tab_id: "kanban"
      order: 100
      tab_template: "project_pane_kanban"
      tab_label: "Kanban"

    return

  destroyProjectPaneTab: ->
    APP.justdo_project_pane.unregisterTab "kanban"

    return

  subscribeToKanbans: (task_id) ->
    Meteor.subscribe "kanbans", task_id

  addSubTask: (parent_task_id, options) ->
    Meteor.call "kanban_addSubTask", parent_task_id, options

  removeSubTask: (parent_task_id, subtask_id, callback) ->
    Meteor.call "kanban_removeSubTask", parent_task_id, subtask_id, callback

  createKanban: (task_id) ->
    Meteor.call "kanban_createKanban", task_id

  setMemberFilter: (task_id, active_member_id) ->
    Meteor.call "kanban_setMemberFilter", task_id, active_member_id

  setSortBy: (task_id, sortBy, reverse) ->
    Meteor.call "kanban_setSortBy", task_id, sortBy, reverse

  addState: (task_id, state_object) ->
    Meteor.call "kanban_addState", task_id, state_object

  updateStateOption: (task_id, state_id, option_id, option_label, new_value) ->
    Meteor.call "kanban_updateStateOption", task_id, state_id, option_id, option_label, new_value
