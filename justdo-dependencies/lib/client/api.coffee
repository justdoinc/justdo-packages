_.extend JustdoDependencies.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  checkDependenciesFormatBeforeUpdate: (doc, field_names, modifier, options) ->
    if JustdoDependencies.dependencies_field_id not in field_names
      return true

    if not (new_value = modifier["$set"]?[JustdoDependencies.dependencies_field_id])?
      return true

    # todo: other checkes:
    # check that the user has access to all the tasks that he lists
    # check (server side) that there is no infinite loop
    # check that a single task is not listed more than once
    # check that the task doesn't list itself as dependant
    # check that the task is not dependent on any of its parents

    return true

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoDependencies.project_custom_feature_id,
        installer: =>
          APP.justdo_project_pane.registerTab
            tab_id: "justdo-dependencies"
            order: 102
            tab_template: "justdo_project_dependencies"
            tab_label: "Dependencies"

          APP.modules.project_page.setupPseudoCustomField JustdoDependencies.dependencies_field_id,
            label: JustdoDependencies.dependencies_field_label
            field_type: JustdoDependencies.dependencies_field_type
            grid_visible_column: true
            grid_editable_column: true
            default_width: 100

          @collection_hook = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options)=>
            return @checkDependenciesFormatBeforeUpdate doc, field_names, modifier, options

          return

        destroyer: =>
          APP.justdo_project_pane.unregisterTab "justdo-dependencies"

          APP.modules.project_page.removePseudoCustomFields JustdoDependencies.dependencies_field_id

          @collection_hook.remove()

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return
