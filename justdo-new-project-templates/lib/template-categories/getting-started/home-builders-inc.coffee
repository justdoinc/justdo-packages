APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return

  APP.justdo_projects_templates?.registerTemplate
    id: "home-builders-inc"
    label_i18n: "project_templates_home_builders_inc_label"
    order: 120
    categories: ["getting-started"]
    postCreationCallback: ->
      if Meteor.isClient
        cur_proj = -> APP.modules.project_page.curProj()
        grid_view = JustDoProjectsTemplates.template_grid_views.gantt

        cur_proj().enableCustomFeatures JustdoPlanningUtilities.project_custom_feature_id, ->
          Meteor.defer ->
            APP.modules.project_page.gridControl().setView grid_view
            return
          return
      return
    template:
      tasks: [
        title_i18n: "project_templates_task_title_sites"
        tasks: [
          title_i18n: "project_templates_task_title_demo_site_name_1"
          events: [
            action: "toggleIsProject"
          ,
            action: "setState"
            args: "in-progress"
          ]
          tasks: [
            title_i18n: "project_templates_task_title_project_planning"
            key: "s1_planning"
            expand: true
            events: [
              action: "setState"
              args: "in-progress"
            ]
            tasks: [
              title_i18n: "project_templates_task_title_scope_definition"
              key: "s1_scoping"
              start_date: share.getDateOffsetByDays(-365 * 3)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 4)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 4)
              events: [
                action: "setState"
                args: "done"
              ]
            ,
              title_i18n: "project_templates_task_title_timeline_and_budgeting"
              key: "s1_timeline"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 4 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 6)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 6)
              events: [
                action: "setState"
                args: "pending"
              ,
                action: "addGanttDependency"
                args: ["s1_scoping"]
              ]
            ,
              title_i18n: "project_templates_task_title_permitting_and_compliance"
              key: "s1_permitting"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 4 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 6)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 6)
              events: [
                action: "setState"
                args: "will-not-do"
              ,
                action: "addGanttDependency"
                args: ["s1_scoping"]                
              ]
            ]
          ,
            title_i18n: "project_templates_task_title_design_and_engineering"
            key: "s1_design"
            events: [
              action: "setState"
              args: "in-progress"
            ,
              action: "addGanttDependency"
              args: ["s1_planning"]
            ]
            tasks: [
              title_i18n: "project_templates_task_title_architectural_design"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 6 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 12)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 12)
              events: [
                action: "addGanttDependency"
                args: ["s1_timeline"]
              ]
            ,
              title_i18n: "project_templates_task_title_structural_engineering"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 6 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 12)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 12)
              events: [
                action: "addGanttDependency"
                args: ["s1_timeline", "s1_permitting"]
              ]
            ,
              title_i18n: "project_templates_task_title_mechanical_electrical_and_plumbing"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 6 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 12)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 12)
              events: [
                action: "addGanttDependency"
                args: ["s1_timeline", "s1_permitting"]
              ]              
            ]
          ,
            title_i18n: "project_templates_task_title_site_preparation"
            key: "s1_site_prep"
            events: [
              action: "setState"
              args: "pending"
            ,
              action: "addGanttDependency"
              args: ["s1_design"]
            ]            
            tasks: [
              title_i18n: "project_templates_task_title_land_surveying"
              key: "s1_surveying"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 12 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 14)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 14)
            ,
              title_i18n: "project_templates_task_title_site_clearing"
              key: "s1_site_clearing"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 14 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 18)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 18)
              events: [
                action: "addGanttDependency"
                args: ["s1_surveying"]
              ]
            ,
              title_i18n: "project_templates_task_title_excavation_and_grading"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 18 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 24)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 24)
              events: [
                action: "addGanttDependency"
                args: ["s1_site_clearing"]
              ]              
            ]
          ,
            title_i18n: "project_templates_task_title_construction"
            key: "s1_construction"
            events: [
              action: "setState"
              args: "done"
            ,
              action: "addGanttDependency"
              args: ["s1_site_prep"]
            ]
            tasks: [
              title_i18n: "project_templates_task_title_framing_and_structural_work"
              key: "s1_structural"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 24 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 30)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 30)
              events: [
                action: "setState"
                args: "done"
              ]
            ,
              title_i18n: "project_templates_task_title_interior_and_exterior_finishing"
              key: "s1_finishing"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 30 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 36)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 36)
              events: [
                action: "setState"
                args: "done"
              ,
                action: "addGanttDependency"
                args: ["s1_structural"]
              ]            
            ,
              title_i18n: "project_templates_task_title_landscaping"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 36 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 38)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 38)
              events: [
                action: "setState"
                args: "done"
              ,
                action: "addGanttDependency"
                args: ["s1_finishing"]
              ]
            ]
          ,
            title_i18n: "project_templates_task_title_inspection_and_quality_control"
            events: [
              action: "setState"
              args: "done"
            ,
                action: "addGanttDependency"
                args: ["s1_construction"]
            ]
            tasks: [
              title_i18n: "project_templates_task_title_code_compliance"
              key: "s1_compliance"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 38 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 41)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 41)
              events: [
                action: "setState"
                args: "done"
              ]              
            ,
              title_i18n: "project_templates_task_title_safety_inspections"
              key: "s1_inspections"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 38 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 41)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 41)
              events: [
                action: "setState"
                args: "done"
              ]            
            ,
              title_i18n: "project_templates_task_title_punch_list"
              start_date: share.getDateOffsetByDays(-365 * 3 + 30 * 41 + 1)
              end_date: share.getDateOffsetByDays(-365 * 3 + 30 * 43)
              due_date: share.getDateOffsetByDays(-365 * 3 + 30 * 43)
              events: [
                action: "setState"
                args: "done"
              ,
                action: "addGanttDependency"
                args: ["s1_compliance", "s1_inspections"]
              ]            
            ]
          ,
            title_i18n: "project_templates_task_title_project_closeout"
            events: [
              action: "setState"
              args: "in-progress"
            ]            
            tasks: [
              title_i18n: "project_templates_task_title_final_documentation"
            ,
              title_i18n: "project_templates_task_title_warranty_and_maintenance"
            ,
              title_i18n: "project_templates_task_title_client_handover"
            ]
          ]
        ,
          title_i18n: "project_templates_task_title_demo_site_name_2"
          events: [
            action: "setState"
            args: "will-not-do"
          ]          
          events: [
            action: "toggleIsProject"
          ]
          tasks: [
            title_i18n: "project_templates_task_title_project_planning"
            tasks: [
              title_i18n: "project_templates_task_title_scope_definition"
            ,
              title_i18n: "project_templates_task_title_timeline_and_budgeting"
            ,
              title_i18n: "project_templates_task_title_permitting_and_compliance"
            ]
          ,
            title_i18n: "project_templates_task_title_design_and_engineering"
            tasks: [
              title_i18n: "project_templates_task_title_architectural_design"
            ,
              title_i18n: "project_templates_task_title_structural_engineering"
            ,
              title_i18n: "project_templates_task_title_mechanical_electrical_and_plumbing"
            ]
          ,
            title_i18n: "project_templates_task_title_site_preparation"
            tasks: [
              title_i18n: "project_templates_task_title_land_surveying"
            ,
              title_i18n: "project_templates_task_title_site_clearing"
            ,
              title_i18n: "project_templates_task_title_excavation_and_grading"
            ]
          ,
            title_i18n: "project_templates_task_title_construction"
            tasks: [
              title_i18n: "project_templates_task_title_framing_and_structural_work"
            ,
              title_i18n: "project_templates_task_title_interior_and_exterior_finishing"
            ,
              title_i18n: "project_templates_task_title_landscaping"
            ]
          ,
            title_i18n: "project_templates_task_title_inspection_and_quality_control"
            tasks: [
              title_i18n: "project_templates_task_title_code_compliance"
            ,
              title_i18n: "project_templates_task_title_safety_inspections"
            ,
              title_i18n: "project_templates_task_title_punch_list"
            ]
          ,
            title_i18n: "project_templates_task_title_project_closeout"
            tasks: [
              title_i18n: "project_templates_task_title_final_documentation"
            ,
              title_i18n: "project_templates_task_title_warranty_and_maintenance"
            ,
              title_i18n: "project_templates_task_title_client_handover"
            ]
          ]
        ,
          title_i18n: (user) -> 
            options = 
              task_name: APP.justdo_i18n.tr "project_templates_task_title_demo_site_name_3", {}, user
            APP.justdo_i18n.tr "project_templates_task_title_completed_suffix", options, user
          events: [
            action: "setArchived"
          ,
            action: "setState"
            args: "done"
          ]
          tasks: [
            title_i18n: "project_templates_task_title_project_planning"
            events: [
              action: "setState"
              args: "done"
            ]            
            tasks: [
              title_i18n: "project_templates_task_title_scope_definition"
              events: [
                action: "setState"
                args: "done"
              ]              
            ,
              title_i18n: "project_templates_task_title_timeline_and_budgeting"
              events: [
                action: "setState"
                args: "done"
              ]            
            ,
              title_i18n: "project_templates_task_title_permitting_and_compliance"
              events: [
                action: "setState"
                args: "done"
              ]            
            ]
          ,
            title_i18n: "project_templates_task_title_design_and_engineering"
            tasks: [
              title_i18n: "project_templates_task_title_architectural_design"
            ,
              title_i18n: "project_templates_task_title_structural_engineering"
            ,
              title_i18n: "project_templates_task_title_mechanical_electrical_and_plumbing"
            ]
          ,
            title_i18n: "project_templates_task_title_site_preparation"
            tasks: [
              title_i18n: "project_templates_task_title_land_surveying"
            ,
              title_i18n: "project_templates_task_title_site_clearing"
            ,
              title_i18n: "project_templates_task_title_excavation_and_grading"
            ]
          ,
            title_i18n: "project_templates_task_title_construction"
            tasks: [
              title_i18n: "project_templates_task_title_framing_and_structural_work"
            ,
              title_i18n: "project_templates_task_title_interior_and_exterior_finishing"
            ,
              title_i18n: "project_templates_task_title_landscaping"
            ]
          ,
            title_i18n: "project_templates_task_title_inspection_and_quality_control"
            tasks: [
              title_i18n: "project_templates_task_title_code_compliance"
            ,
              title_i18n: "project_templates_task_title_safety_inspections"
            ,
              title_i18n: "project_templates_task_title_punch_list"
            ]
          ,
            title_i18n: "project_templates_task_title_project_closeout"
            tasks: [
              title_i18n: "project_templates_task_title_final_documentation"
            ,
              title_i18n: "project_templates_task_title_warranty_and_maintenance"
            ,
              title_i18n: "project_templates_task_title_client_handover"
            ]
          ]
        ,
          title_i18n: (user) -> 
            options = 
              task_name: APP.justdo_i18n.tr "project_templates_task_title_demo_site_name_4", {}, user
            APP.justdo_i18n.tr "project_templates_task_title_completed_suffix", options, user
          events: [
            action: "setArchived"
          ,
            action: "setState"
            args: "done"
          ]
          tasks: [
            title_i18n: "project_templates_task_title_project_planning"
            events: [
              action: "setState"
              args: "done"
            ]
            tasks: [
              title_i18n: "project_templates_task_title_scope_definition"
              events: [
                action: "setState"
                args: "done"
              ]              
            ,
              title_i18n: "project_templates_task_title_timeline_and_budgeting"
              events: [
                action: "setState"
                args: "done"
              ]            
            ,
              title_i18n: "project_templates_task_title_permitting_and_compliance"
              events: [
                action: "setState"
                args: "done"
              ]            
            ]
          ,
            title_i18n: "project_templates_task_title_design_and_engineering"
            tasks: [
              title_i18n: "project_templates_task_title_architectural_design"
            ,
              title_i18n: "project_templates_task_title_structural_engineering"
            ,
              title_i18n: "project_templates_task_title_mechanical_electrical_and_plumbing"
            ]
          ,
            title_i18n: "project_templates_task_title_site_preparation"
            tasks: [
              title_i18n: "project_templates_task_title_land_surveying"
            ,
              title_i18n: "project_templates_task_title_site_clearing"
            ,
              title_i18n: "project_templates_task_title_excavation_and_grading"
            ]
          ,
            title_i18n: "project_templates_task_title_construction"
            tasks: [
              title_i18n: "project_templates_task_title_framing_and_structural_work"
            ,
              title_i18n: "project_templates_task_title_interior_and_exterior_finishing"
            ,
              title_i18n: "project_templates_task_title_landscaping"
            ]
          ,
            title_i18n: "project_templates_task_title_inspection_and_quality_control"
            tasks: [
              title_i18n: "project_templates_task_title_code_compliance"
            ,
              title_i18n: "project_templates_task_title_safety_inspections"
            ,
              title_i18n: "project_templates_task_title_punch_list"
            ]
          ,
            title_i18n: "project_templates_task_title_project_closeout"
            tasks: [
              title_i18n: "project_templates_task_title_final_documentation"
            ,
              title_i18n: "project_templates_task_title_warranty_and_maintenance"
            ,
              title_i18n: "project_templates_task_title_client_handover"
            ]
          ]
        ]
      ,
        title_i18n: "project_templates_task_title_finance"
        events: [
          action: "setState"
          args: "nil"
        ]
        tasks: [
          title_i18n: (user) ->
            options = 
              site_name: APP.justdo_i18n.tr "project_templates_task_title_demo_site_name_1", {}, user
            return APP.justdo_i18n.tr "project_templates_task_title_secure_financing_for_custom_name", options, user
          expand: true
          events: [
            action: "setState"
            args: "pending"
          ]
          tasks: [
            title_i18n: "project_templates_task_title_determine_load_requirements"
            events: [
              action: "setState"
              args: "will-not-do"
            ]                 
          ,
            title_i18n: "project_templates_task_title_create_a_financial_model"
            events: [
              action: "setState"
              args: "in-progress"
            ]     
          ,
            title_i18n: "project_templates_task_title_identify_potential_lenders"
            events: [
              action: "setState"
              args: "pending"
            ]                 
            tasks: [
              title_i18n: 
                key: "project_templates_task_title_bank_with_custom_name"
                options: 
                  bank_name: "A"
              tasks: [
                title_i18n: "project_templates_task_title_obtain_preliminary_approvals"
              ]
            ,
              title_i18n: 
                key: "project_templates_task_title_bank_with_custom_name"
                options: 
                  bank_name: "B"
              tasks: [
                title_i18n: "project_templates_task_title_prepare_business_plan"
              ]
            ]
          ]
        ,
          title_i18n: "project_templates_task_title_prepare_fy_report"
          events: [
            action: "setState"
            args: "on-hold"
          ]
          tasks: [
            title_i18n: "project_templates_task_title_contact_auditor"
          ,
            title_i18n: "project_templates_task_title_prepare_employer_return"
          ]
        ]
      ,
        title_i18n: "project_templates_task_title_human_resources"
        events: [
          action: "setState"
          args: "nil"
        ]        
        expand: true
        tasks: [
          title_i18n: "project_templates_task_title_recruit_on_site_engineer"
          events: [
            action: "setState"
            args: "in-progress"
          ]          
          tasks: [
            title_i18n: 
              key: "project_templates_task_title_candidate_with_custom_name"
              options: 
                candidate_name: "A"
            events: [
              action: "setStatus"
              args: "project_templates_task_title_coordinate_zoom_meeting"
            ,
              action: "setState"
              args: "done"
            ]
          ,
            title_i18n: 
              key: "project_templates_task_title_candidate_with_custom_name"
              options: 
                candidate_name: "B"
            events: [
              action: "setStatus"
              args: "project_templates_task_title_cv_is_missing_contact_by_email"
            ]
          ]
        ]
      ]
    demo_html_template: [
      {
        level: 0
        expand_state: "minus"
        task_id: "1"
        title_i18n: "project_templates_task_title_sites"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 1
        expand_state: "minus"
        task_id: "83"
        title_i18n: "project_templates_task_title_demo_site_name_1"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 2
        expand_state: "minus"
        task_id: "89"
        title_i18n: "project_templates_task_title_project_planning"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 3
        task_id: "90"
        title_i18n: "project_templates_task_title_scope_definition"
        state_class: "done"
        state_title_i18n: "state_done"
      }
      {
        level: 3
        task_id: "91"
        title_i18n: "project_templates_task_title_timeline_and_budgeting"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 3
        task_id: "92"
        title_i18n: "project_templates_task_title_permitting_and_compliance"
        state_class: "will-not-do"
        state_title_i18n: "state_cancelled"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "93"
        title_i18n: "project_templates_task_title_design_and_engineering"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "97"
        title_i18n: "project_templates_task_title_site_preparation"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "101"
        title_i18n: "project_templates_task_title_construction"
        state_class: "done"
        state_title_i18n: "state_done"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "105"
        title_i18n: "project_templates_task_title_inspection_and_quality_control"
        state_class: "done"
        state_title_i18n: "state_done"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "109"
        title_i18n: "project_templates_task_title_project_closeout"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 1
        expand_state: "plus"
        task_id: "113"
        title_i18n: "project_templates_task_title_demo_site_name_2"
        state_class: "will-not-do"
        state_title_i18n: "state_cancelled"
      }
      {
        level: 1
        task_id: "138"
        title_i18n: "project_templates_task_title_demo_site_name_3"
        state_class: "done"
        state_title_i18n: "state_done"
        extra_padding: "extra-padding"
      }
      {
        level: 1
        task_id: "145"
        title_i18n: "project_templates_task_title_demo_site_name_4"
        state_class: "done"
        state_title_i18n: "state_done"
        extra_padding: "extra-padding"
      }
      {
        level: 0
        expand_state: "minus"
        task_id: "43"
        title_i18n: "project_templates_task_title_finance"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 1
        expand_state: "minus"
        task_id: "152"
        title_i18n: ->
          options = 
            site_name: TAPi18n.__ "project_templates_task_title_demo_site_name_1"
          return TAPi18n.__ "project_templates_task_title_secure_financing_for_custom_name", options
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 2
        task_id: "154"
        title_i18n: "project_templates_task_title_determine_load_requirements"
        state_class: "will-not-do"
        state_title_i18n: "state_cancelled"
        extra_padding: "extra-padding"
      }
      {
        level: 2
        task_id: "155"
        title_i18n: "project_templates_task_title_create_a_financial_model"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
        extra_padding: "extra-padding"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "156"
        title_i18n: "project_templates_task_title_identify_potential_lenders"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 1
        expand_state: "plus"
        task_id: "49"
        title_i18n: "project_templates_task_title_prepare_fy_report"
        state_class: "on-hold"
        state_title_i18n: "state_on_hold"
      }
      {
        level: 0
        expand_state: "minus"
        task_id: "45"
        title_i18n: "project_templates_task_title_human_resources"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 1
        expand_state: "plus"
        task_id: "50"
        title_i18n: "project_templates_task_title_recruit_on_site_engineer"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
    ]
  return