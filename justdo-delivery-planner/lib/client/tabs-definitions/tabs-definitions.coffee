_.extend JustdoDeliveryPlanner.prototype,
  getTabsDefinitions: ->
    gcOpsGen = APP.modules.project_page.generateGridControlOptionsForSections

    tabs_definitions =
      [
        {
          id: "jdp-all-projects"
          options:
            grid_control_options: gcOpsGen(
              [
                {
                  id: "active-projects"

                  section_manager: "QuerySection"

                  options:
                    permitted_depth: 1
                    section_item_title: "Active Project"
                    expanded_on_init: true
                    show_if_empty: true

                  section_manager_options:
                    query: ->
                      query =
                        "#{JustdoDeliveryPlanner.task_is_archived_project_field_name}": {$ne: true}
                        "#{JustdoDeliveryPlanner.task_is_project_field_name}": true

                      if (project_id = APP.modules?.project_page?.curProj()?.id)?
                        query.project_id = project_id

                      return APP.collections.Tasks.find(
                        query,
                        {sort: {seqId: 1}}
                      ).fetch()
                }
                {
                  id: "archived-projects"

                  section_manager: "QuerySection"

                  options:
                    permitted_depth: 1
                    section_item_title: "Closed Project"
                    expanded_on_init: false
                    show_if_empty: false

                  section_manager_options:
                    query: ->
                      query =
                        "#{JustdoDeliveryPlanner.task_is_archived_project_field_name}": true
                        "#{JustdoDeliveryPlanner.task_is_project_field_name}": true

                      if (project_id = APP.modules?.project_page?.curProj()?.id)?
                        query.project_id = project_id

                      return APP.collections.Tasks.find(
                        query,
                        {sort: {seqId: 1}}
                      ).fetch()
                }
              ]
            )
            removable: true
            activate_on_init: false
            tabTitleGenerator: "Resource Tracking"
        }
      ] 

    return tabs_definitions
