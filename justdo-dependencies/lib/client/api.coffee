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
    if JustdoDependencies.pseudo_field_id not in field_names
      return true
    if not (new_value = modifier["$set"]?[JustdoDependencies.pseudo_field_id])
      return true

    #check for right format (comma separated)
    re = /^(\d+(\s*,\s*\d+)*)\s*?$/g
    if not re.test new_value
      JustdoSnackbar.show
        text: "Please enter comma-separated tasks sequence numbers."
      #todo: check with Daniel who to invalidate the Task/line in order to present the previous value
      return false

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

          if JustdoDependencies.add_pseudo_field
            APP.modules.project_page.setupPseudoCustomField JustdoDependencies.pseudo_field_id,
              label: JustdoDependencies.pseudo_field_label
              field_type: JustdoDependencies.pseudo_field_type
              grid_visible_column: true
              grid_editable_column: true
              default_width: 100


          @collection_hook = APP.collections.Tasks.before.update (user_id, doc, field_names, modifier, options)=>
            return @checkDependenciesFormatBeforeUpdate doc, field_names, modifier, options
          return

        destroyer: =>
          APP.justdo_project_pane.unregisterTab "justdo-dependencies"
          if JustdoDependencies.add_pseudo_field
            APP.modules.project_page.removePseudoCustomFields JustdoDependencies.pseudo_field_id

          @collection_hook.remove()

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  # providing this function as an API for other modules to check if there are dependencies
  pseudoFiledId: -> return JustdoDependencies.pseudo_field_id
