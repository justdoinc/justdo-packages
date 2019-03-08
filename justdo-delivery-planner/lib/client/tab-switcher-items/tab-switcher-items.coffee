APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.delivery_planner_tab_switcher_items.helpers
    showItems: ->
      cur_project = module.curProj()

      if not cur_project?
        return

      return cur_project.isCustomFeatureEnabled(JustdoDeliveryPlanner.project_custom_feature_id)