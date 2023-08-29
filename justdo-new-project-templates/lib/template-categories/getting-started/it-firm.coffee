APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return
  APP.justdo_projects_templates?.registerTemplate
    id: "it-firm"
    label_i18n: "project_templates_it_firm_label"
    categories: ["getting-started"]
    order: 110
    template:
      tasks: [
        title_i18n: "project_templates_task_title_research_and_development"
        tasks: [
          title_i18n: "project_templates_task_title_mobile_app_development"
          tasks: [
            title_i18n: "project_templates_task_title_sprints"
            tasks: [
              title_i18n: "v0.0.1 (POC)"
              events: [
                action: "setArchived"
              ]
              tasks: [
                title_i18n: 
                  key: "project_templates_task_title_task_with_custom_name",
                  options: 
                    task_name: "A"
              ,
                title_i18n: 
                  key: "project_templates_task_title_task_with_custom_name",
                  options: 
                    task_name: "B"
              ]
            ,
              title_i18n: "v1.0.0"
              events: [
                action: "toggleIsProject"
              ]
              tasks: [
                title_i18n: 
                  key: "project_templates_task_title_implement_new_feature_with_custom_name",
                  options: 
                    feature_name: "1"
                tasks: [
                  title_i18n: "project_templates_task_title_design_and_ui_ux"
                  expand: true
                  tasks: [
                    title_i18n: "project_templates_task_title_requirements_gathering"
                  ,
                    title_i18n: "project_templates_task_title_wireframes"
                  ,
                    title_i18n: "project_templates_task_title_user_interface_design"
                  ,
                    title_i18n: "project_templates_task_title_user_experience_design"
                  ]
                ,
                  title_i18n: "project_templates_task_title_backend_development"
                  expand: true
                  tasks: [
                    title_i18n: 
                      key: "project_templates_task_title_feature_with_custom_name",
                      options: 
                        feature_name: "B"
                  ]
                ,
                  title_i18n: "project_templates_task_title_frontend_development"
                  expand: true
                  tasks: [
                    title_i18n: 
                      key: "project_templates_task_title_feature_with_custom_name",
                      options: 
                        feature_name: "A"
                  ]
                ,
                  title_i18n: "project_templates_task_title_quality_assurance"
                  expand: true
                  tasks: [
                    title_i18n: 
                      key: "project_templates_task_title_write_auto_test_with_custom_name",
                      options: 
                        test_name: "1"
                  ,
                    title_i18n: 
                      key: "project_templates_task_title_write_auto_test_with_custom_name",
                      options: 
                        test_name: "2"
                  ]
                ]
              ]
            ,
              title_i18n: "v2.0.0"
              events: [
                action: "toggleIsProject"
              ]
              tasks: [
                title_i18n: 
                  key: "project_templates_task_title_implement_new_feature_with_custom_name",
                  options: 
                    feature_name: "2"
              ]
            ]
          ,
            title_i18n: "project_templates_task_title_roadmap"
            tasks: [
              title_i18n: 
                key: "project_templates_task_title_roadmap_feature_with_custom_name",
                options: 
                  feature_name: "1"
            ,
              title_i18n: 
                key: "project_templates_task_title_roadmap_feature_with_custom_name",
                options: 
                  feature_name: "2"
              events: [
                action: "setStatus"
                args: 
                  key: "project_templates_task_title_requested_by_client_with_custom_name"
                  options: 
                    client_name: "XYZ"
              ]
            ,
              title_i18n: 
                key: "project_templates_task_title_roadmap_feature_with_custom_name",
                options: 
                  feature_name: "3"
              events: [
                action: "setStatus"
                args: 
                  key: "project_templates_task_title_requested_by_client_with_custom_name"
                  options: 
                    client_name: "ABC"
              ]
            ]
          ,
            title_i18n: "project_templates_task_title_mobile_app_qa"
            tasks: [
              title_i18n: "project_templates_task_title_bug_tracking"
            ]
          ]
        ]
      ,
        title_i18n: "project_templates_task_title_finance"
        tasks: [
          title_i18n: "project_templates_task_title_prepare_fy_report"
          tasks: [
            title_i18n: "project_templates_task_title_contact_auditor"
          ,
            title_i18n: "project_templates_task_title_prepare_employer_return"
          ]
        ]
      ,
        title_i18n: "project_templates_task_title_customer_service"
        tasks: [
          title_i18n: 
            key: "project_templates_task_title_client_with_custom_name",
            options: 
              client_name: "A"
          tasks: [
            title_i18n: 
              key: "project_templates_task_title_deployment_version_on_client_server"
              options:
                version: "v3.0.0"
                client: "A"
          ]
        ,
          title_i18n: 
            key: "project_templates_task_title_client_with_custom_name",
            options: 
              client_name: "B"
          tasks: [
            title_i18n: "project_templates_task_title_contact_to_reproduce_reported_issue"
          ]
        ]
      ,
        title_i18n: "project_templates_task_title_human_resources"
        tasks: [
          title_i18n: "project_templates_task_title_recruit_position_for_frontend"
          tasks: [
            title_i18n:
              key: "project_templates_task_title_candidate_with_custom_name"
              options: 
                candidate_name: "A"
            events: [
              action: "setStatus"
              args: "project_templates_task_title_coordinate_zoom_meeting"
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
        title_i18n: "project_templates_task_title_research_and_development"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 1
        expand_state: "minus"
        task_id: "25"
        title_i18n: "project_templates_task_title_mobile_app_development"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 2
        expand_state: "minus"
        task_id: "45"
        title_i18n: "project_templates_task_title_sprints"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 3
        task_id: "47"
        title: "v0.0.1 (POC)"
        state_class: "done"
        state_title_i18n: "state_done"
        extra_padding: "extra-padding"
      }
      {
        level: 3
        expand_state: "minus"
        task_id: "63"
        title: "v1.0.0"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 4
        expand_state: "minus"
        task_id: "53"
        title_i18n: ->
          options = 
            feature_name: "1"
          return TAPi18n.__ "project_templates_task_title_implement_new_feature_with_custom_name", options
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 5
        expand_state: "minus"
        task_id: "8"
        title_i18n: "project_templates_task_title_design_and_ui_ux"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 6
        task_id: "54"
        title_i18n: "project_templates_task_title_requirements_gathering"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
        extra_padding: "extra-padding"
      }
      {
        level: 6
        task_id: "9"
        title_i18n: "project_templates_task_title_wireframes"
        state_class: "done"
        state_title_i18n: "state_done"
        extra_padding: "extra-padding"
      }
      {
        level: 6
        task_id: "10"
        title_i18n: "project_templates_task_title_user_interface_design"
        state_class: "done"
        state_title_i18n: "state_done"
        extra_padding: "extra-padding"
      }
      {
        level: 6
        task_id: "11"
        title_i18n: "project_templates_task_title_user_experience_design"
        state_class: "cancelled"
        state_title_i18n: "state_cancelled"
        extra_padding: "extra-padding"
      }
      {
        level: 5
        expand_state: "minus"
        task_id: "14"
        title_i18n: "project_templates_task_title_backend_development"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 6
        task_id: "35"
        title_i18n: ->
          options = 
            feature_name: "B"
          return TAPi18n.__ "project_templates_task_title_feature_with_custom_name", options
        state_class: "pending"
        state_title_i18n: "state_pending"
        extra_padding: "extra-padding"
      }
      {
        level: 5
        expand_state: "minus"
        task_id: "13"
        title_i18n: "project_templates_task_title_frontend_development"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 6
        task_id: "34"
        title_i18n: ->
          options = 
            feature_name: "A"
          return TAPi18n.__ "project_templates_task_title_feature_with_custom_name", options
        state_class: "on-hold"
        state_title_i18n: "state_on_hold"
        extra_padding: "extra-padding"
      }
      {
        level: 5
        expand_state: "minus"
        task_id: "60"
        title_i18n: "project_templates_task_title_quality_assurance"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 6
        task_id: "61"
        title_i18n: ->
          options = 
            test_name: "1"
          return TAPi18n.__ "project_templates_task_title_write_auto_test_with_custom_name", options
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
        extra_padding: "extra-padding"
      }
      {
        level: 6
        task_id: "62"
        title_i18n: ->
          options = 
            test_name: "2"
          return TAPi18n.__ "project_templates_task_title_write_auto_test_with_custom_name", options
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
        extra_padding: "extra-padding"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "71"
        title: "v2.0.0"
        state_class: "done"
        state_title_i18n: "state_done"
      }
      {
        level: 1
        expand_state: "plus"
        task_id: "46"
        title_i18n: "project_templates_task_title_roadmap"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 1
        expand_state: "plus"
        task_id: "16"
        title_i18n: "project_templates_task_title_mobile_app_qa"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 0
        expand_state: "plus"
        task_id: "43"
        title_i18n: "project_templates_task_title_finance"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 0
        expand_state: "plus"
        task_id: "55"
        title_i18n: "project_templates_task_title_customer_service"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 0
        expand_state: "plus"
        task_id: "41"
        title_i18n: "project_templates_task_title_human_resources"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
    ]
  return