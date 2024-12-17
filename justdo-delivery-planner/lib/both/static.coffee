_.extend JustdoDeliveryPlanner,
  project_custom_feature_id: "justdo_delivery_planner" # Use underscores

  task_is_project_field_name: "p:dp:is_project"

  task_is_archived_project_field_name: "p:dp:is_archived_project"

  task_project_members_availability_field_name: "p:dp:members_availability"

  task_base_project_workdays_field_name: "p:dp:base_project_workdays"

  task_baseline_projection_data_field_name: "p:dp:baseline_projection"

  task_is_committed_field_name: "p:dp:commited"

  default_time_zone: "America/New_York" # The timezone we will use for users we can't determine their timezone

  default_simple_member_daily_availability_seconds: 60 * 60 * 3

  default_base_project_workdays: [0, 1, 1, 1, 1, 1, 0]

  is_projects_collection_enabled: true
  projects_collections_types: [
    {
      type_id: "projects_collection"

      type_label_i18n: "projects_collection_default_type_label"
      type_label_plural_i18n: "projects_collection_default_type_label_plural"

      set_as_i18n: "projects_collection_set_as_default_projects_collection"
      unset_as_i18n: "projects_collection_unset_as_default_projects_collection"
      close_i18n: "projects_collection_close_default_projects_collection"
      reopen_i18n: "projects_collection_reopen_default_projects_collection"

      type_icon: { # The type icon is used for the - set as Projects Collection, on-grid indicator, the tab switcher dropdown, and other places where we refer to the Project Collection type.
        type: "feather"
        val: "jd-ai"
        class: "ai-icon"
      },
      close_op_icon: { # Will appear next to the context menu operation for closing. Note that the closed state is the faded type_icon, this is for the action of closing
        type: "feather"
        val: "jd-ai"
        class: "ai-icon"
      },
      unset_op_icon: { # Will appear next to the context menu operation for unsetting a Project Collection.
        type: "feather"
        val: "jd-ai"
        class: "ai-icon"
      }
    },
    {
      type_id: "pseudo_department_type_for_testing"

      type_label_i18n: "projects_collection_department_label"
      type_label_plural_i18n: "projects_collection_department_label_plural"

      set_as_i18n: "projects_collection_set_as_department"
      unset_as_i18n: "projects_collection_unset_as_department"
      close_i18n: "projects_collection_close_department"
      reopen_i18n: "projects_collection_reopen_department"

      type_icon: { # The type icon is used for the - set as Projects Collection, on-grid indicator, the tab switcher dropdown, and other places where we refer to the Project Collection type.
        type: "feather"
        val: "jd-ai"
        class: "ai-icon"
      },
      close_op_icon: { # Will appear next to the context menu operation for closing. Note that the closed state is the faded type_icon, this is for the action of closing
        type: "feather"
        val: "jd-ai"
        class: "ai-icon"
      },
      unset_op_icon: { # Will appear next to the context menu operation for unsetting a Project Collection.
        type: "feather"
        val: "jd-ai"
        class: "ai-icon"
      }
    }
  ]
  projects_collection_default_fields_to_fetch: 
    _id: 1
  projects_collection_grid_view_section_title: "projects_collection_grid_view_section_title"
  projects_collection_tab_title_generator_title: "projects_collection_tab_title_generator_title"
