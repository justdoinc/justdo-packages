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

    if @isProjectsCollectionEnabled()
      tabs_definitions.push(
        {
          id: "jdp-projects-collection"
          options:
            grid_control_options: gcOpsGen(
              [
                {
                  id: "main"
                  section_manager: "QuerySection"
                  options:
                    permitted_depth: -1
                    expanded_on_init: true
                  section_manager_options:
                    query: ->
                      projects_collection_type_id = @getGlobalStateVar "projects-collection-type", ""
                      query = 
                        project_id: JD.activeJustdoId()
                        "projects_collection.projects_collection_type": projects_collection_type_id
                      
                      return APP.collections.Tasks.find(query, {sort: {seqId: 1}}).fetch()
                }
              ]
            )
            removable: true
            activate_on_init: false
            tabTitleGenerator: (tab_id) -> 
              sections_state = @getTabGridControlSectionsState(tab_id)
              projects_collection_type_id = sections_state.global["projects-collection-type"]
              projects_collection_type_def = APP.justdo_delivery_planner.getProjectsCollectionTypeById projects_collection_type_id

              return TAPi18n.__ projects_collection_type_def.type_label_plural_i18n
        }
      )
    return tabs_definitions
