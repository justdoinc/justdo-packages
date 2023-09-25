APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return

  APP.justdo_projects_templates?.registerTemplate
    id: "movies-production"
    label_i18n: "project_templates_movies_production_label"
    categories: ["getting-started"]
    order: 130
    template:
      tasks: [
        title_i18n: "movies"
        tasks: [
          title_i18n: "demo_movie_name_1"
          events: [
            action: "setState"
            args: "in-progress"
          ]
          events: [
            action: "toggleIsProject"
          ]
          tasks: [
            title_i18n: "development"
            expand: true
            events: [
              action: "setState"
              args: "in-progress"
            ]            
            tasks: [
              title_i18n:"evaluate_and_acquire_idea"
              events: [
                action: "setState"
                args: "done"
              ]              
            ,
              title_i18n: "develop_story_conecpt_into_screenplay"
              events: [
                action: "setState"
                args: "in-progress"
              ]              
            ,
              title_i18n: "attaching_key_talent"
              expand: true
              tasks: [
                title_i18n: "potential_actors"
                events: [
                  action: "setState"
                  args: "in-progress"
                ]
              ,
                title_i18n: "directors"
                events: [
                  action: "setState"
                  args: "done"
                ]
              ]
            ]
          ,
            title_i18n: "pre_production"
            tasks: [
              title_i18n: "finalizing_script_revisions"
            ,
              title_i18n: "casting_actors_and_hiring_crew_members"
            ,
              title_i18n: "scouting_and_securing_locations"
            ,
              title_i18n: "developing_budgets_and_shoooting_schedules"
            ,
              title_i18n: "planning_costume_set_and_prop_designs"
            ]
          ,
            title_i18n: "post_production"
            events: [
              action: "setState"
              args: "on-hold"
            ]
            tasks: [
              title_i18n: "editing_the_flims_picture_and_sound"
            ,
              title_i18n: "overseeing_visual_effects_and_cgi_work"
            ,
              title_i18n: "collaborating_with_the_composer_on_the_flims_score"
            ,
              title_i18n: "managing_the_color_grading_process"
            ,
              title_i18n: "finalizing_the_flims_sound_mix_and_mastering"
            ]
          ,
            title_i18n: "marketing_and_distribution"
            tasks: [
              title_i18n: "developing_marketing_materials"
            ,
              title_i18n: "coordinating_film_festival_submission_and_screening"
            ,
              title_i18n: "securing_distribution_deals_and_arranging_theatrical_releases"
            ,
              title_i18n: "managing_public_relations_and_media_coverage"
            ]
          ]
        ,
          title_i18n: "demo_movie_name_2"
          events: [
            action: "toggleIsProject"
          ,
            action: "setState"
            args: "in-progress"
          ]
          tasks: [
            title_i18n: "development"
            events: [
              action: "setState"
              args: "done"
            ]
          ,
            title_i18n: "pre_production"
            events: [
              action: "setState"
              args: "done"
            ]          
          ,
            title_i18n: "post_production"
            events: [
              action: "setState"
              args: "done"
            ]          
          ,
            title_i18n: "marketing_and_distribution"
            events: [
              action: "setState"
              args: "in-progress"
            ]          
          ]
        ,
          title_i18n: (user) ->
            options = 
              task_name: APP.justdo_i18n.tr "demo_movie_name_3", {}, user
            return APP.justdo_i18n.tr "project_templates_task_title_completed_suffix", options, user
          events: [
            action: "setArchived"
            args: "nil"
          ,
            action: "setState"
            args: "done"
          ]
          tasks: [
            title_i18n: "development"
          ,
            title_i18n: "pre_production"
          ,
            title_i18n: "post_production"
          ,
            title_i18n: "marketing_and_distribution"
          ]
        ]
      ,
        title_i18n: "project_templates_task_title_finance"
        events: [
          action: "setState"
          args: "in-progress"
        ]        
        tasks: [
          title_i18n: "funding_identification_and_procurement"
          expand: true
          events: [
            action: "setState"
            args: "in-progress"
          ]          
          tasks: [
            title_i18n: (user) ->
              options =
                investor: "GateFlix"
                movie_name: APP.justdo_i18n.tr "demo_movie_name_1", {}, user
              return APP.justdo_i18n.tr "secure_funds_for_movie_from_investor", options, user
            tasks: [
              title_i18n: "negotiate_terms_and_conditions"
            ,
              title_i18n: "draft_legal_agreement"
              events: [
                action: "setStatus"
                args: "remember_to_exclude_exclusive_right_to_finance"
              ]
            ]
          ]
        ,
          title_i18n: "cash_flow_management"
          events: [
            action: "setState"
            args: "in-progress"
            ]          
        ,
          title_i18n: "contract_negotiation_and_management"
        ]
      ,
        title_i18n: "project_templates_task_title_human_resources"
        tasks: [
          title_i18n: "recruit_position_for_storyboard_artist"
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
        task_id: "42"
        title_i18n: "movies"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 1
        expand_state: "minus"
        task_id: "43"
        title_i18n: "demo_movie_name_1"
        state_class: "in-progress"
        state_title_i18n: "in-progress"
      }
      {
        level: 2
        expand_state: "minus"
        task_id: "47"
        title_i18n: "development"
        state_class: "in-progress"
        state_title_i18n: "in-progress"
      }
      {
        level: 3
        task_id: "52"
        title_i18n: "evaluate_and_acquire_idea"
        state_class: "done"
        state_title_i18n: "state_done"
        extra_padding: "extra-padding"
      }
      {
        level: 3
        task_id: "53"
        title_i18n: "develop_story_conecpt_into_screenplay"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
        extra_padding: "extra-padding"
      }
      {
        level: 3
        expand_state: "minus"
        task_id: "54"
        title_i18n: "attaching_key_talent"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 4
        task_id: "55"
        title_i18n: "potential_actors"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
        extra_padding: "extra-padding"
      }
      {
        level: 4
        task_id: "56"
        title_i18n: "directors"
        state_class: "done"
        state_title_i18n: "state_done"
        extra_padding: "extra-padding"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "48"
        title_i18n: "pre_production"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "49"
        title_i18n: "post_production"
        state_class: "on-hold"
        state_title_i18n: "state_on_hold"
      }
      {
        level: 2
        expand_state: "plus"
        task_id: "51"
        title_i18n: "marketing_and_distribution"
        state_class: "cancelled"
        state_title_i18n: "state_cancelled"
      }
      {
        level: 1
        expand_state: "plus"
        task_id: "79"
        title_i18n: "demo_movie_name_2"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 1
        task_id: "84"
        title_i18n: ->
          options = 
            task_name: TAPi18n.__ "demo_movie_name_3"
          return TAPi18n.__ "project_templates_task_title_completed_suffix", options
        state_class: "done"
        state_title_i18n: "state_done"
        extra_padding: "extra-padding"
      }
      {
        level: 1
        expand_state: "minus"
        task_id: "3"
        title_i18n: "project_templates_task_title_finance"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
      }
      {
        level: 2
        expand_state: "minus"
        task_id: "76"
        title_i18n: "funding_identification_and_procurement"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 3
        expand_state: "plus"
        task_id: "72"
        title_i18n: ->
          options = 
            investor: "GateFlix"
            movie_name: TAPi18n.__ "demo_movie_name_1"
          return TAPi18n.__ "secure_funds_for_movie_from_investor", options
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
      {
        level: 2
        task_id: "77"
        title_i18n: "cash_flow_management"
        state_class: "in-progress"
        state_title_i18n: "state_in_progress"
        extra_padding: "extra-padding"
      }
      {
        level: 2
        task_id: "78"
        title_i18n: "contract_negotiation_and_management"
        state_class: "pending"
        state_title_i18n: "state_pending"
        extra_padding: "extra-padding"
      }
      {
        level: 0
        expand_state: "plus"
        task_id: "72"
        title_i18n: "project_templates_task_title_human_resources"
        state_class: "pending"
        state_title_i18n: "state_pending"
      }
    ]
  return