_.extend JustdoProjectsDashboard.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoProjectsDashboard.project_custom_feature_id,
        installer: =>
          APP.justdo_project_pane.registerTab
            tab_id: "justdo-projects-dashboard"
            order: 1
            tab_template: "justdo_projects_dashboard"
            tab_label: "Dashboard"
          return

        destroyer: =>
          APP.justdo_project_pane.unregisterTab "justdo-projects-dashboard"
          return

    @onDestroy =>
      custom_feature_maintainer.stop()
      return
    return
  
  # use this to link the specific projects templates to the main one
  project_id_to_template_instance: {}
  
  # use this to list all the fields that we want to collect data for
  fields_of_interest_rv: new ReactiveVar {}
  
  main_part_interest: new ReactiveVar ""
  table_part_interest: new ReactiveVar ""
  
  # cache the labels
  field_ids_to_grid_values: new ReactiveVar {}
  
  
  
