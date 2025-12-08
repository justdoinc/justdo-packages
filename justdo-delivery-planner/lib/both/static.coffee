_.extend JustdoDeliveryPlanner,
  project_custom_feature_id: "justdo_delivery_planner" # Use underscores

  task_is_project_field_name: "p:dp:is_project"

  task_is_archived_project_field_name: "p:dp:is_archived_project"

  task_project_members_availability_field_name: "p:dp:members_availability"

  task_base_project_workdays_field_name: "p:dp:base_project_workdays"

  task_baseline_projection_data_field_name: "p:dp:baseline_projection"

  task_is_committed_field_name: "p:dp:commited"

  set_unset_project_change_type: "set_unset_project"

  close_reopen_project_change_type: "close_reopen_project"

  set_unset_projects_collection_change_type: "set_unset_projects_collection"
  
  close_reopen_projects_collection_change_type: "close_reopen_projects_collection"

  default_time_zone: "America/New_York" # The timezone we will use for users we can't determine their timezone

  add_to_projects_collection_section_id_prefix: "add-to-projects-collection-"

  default_simple_member_daily_availability_seconds: 60 * 60 * 3

  default_base_project_workdays: [0, 1, 1, 1, 1, 1, 0]

  projects_collection_plugin_id: "projects_collection"
  projects_collection_plugin_name_i18n: "projects_collection_default_type_label"

  is_projects_collection_enabled_globally: false

  defaultOnGridProjectsCollectionClick: null

  defaultOnGridProjectClick: null

  projects_collections_types: [
    # {
    #   type_id: "projects_collection"

    #   type_label_i18n: "projects_collection_default_type_label"
    #   type_label_plural_i18n: "projects_collection_default_type_label_plural"

    #   set_as_i18n: "projects_collection_set_as_default_projects_collection"
    #   unset_as_i18n: "projects_collection_unset_as_default_projects_collection"
    #   close_i18n: "projects_collection_close_default_projects_collection"
    #   closed_label_i18n: "projects_collection_closed_default_projects_collection_label"
    #   reopen_i18n: "projects_collection_reopen_default_projects_collection"
    #   add_sub_item_i18n: "projects_collection_create_sub_projects_collection"

    #   type_icon: { # The type icon is used for the - set as Projects Collection, on-grid indicator, the tab switcher dropdown, and other places where we refer to the Project Collection type.
    #     type: "feather"
    #     val: "folder"
    #     class: ""
    #   },
    #   unset_op_icon: { # Will appear next to the context menu operation for unsetting a Project Collection.
    #     type: "feather"
    #     val: "jd-folder-unset"
    #     class: ""
    #   }
    #   close_op_icon: { # Will appear next to the context menu operation for closing. Note that the closed state is the closed_icon, this is for the action of closing
    #     type: "feather"
    #     val: "jd-folder-close"
    #     class: ""
    #   },
    #   closed_icon: { # Will appear in on-grid indicator. Note that the icon for close op is close_op_icon
    #     type: "feather"
    #     val: "folder"
    #     class: "closed-projects-collection"
    #   },
    #   reopen_op_icon: { # Will appear next to the context menu operation for reopening.
    #     type: "feather"
    #     val: "folder"
    #     class: ""
    #   }
    # },
    {
      type_id: "department"

      type_label_i18n: "projects_collection_department_label"
      type_label_plural_i18n: "projects_collection_department_label_plural"

      set_as_i18n: "projects_collection_set_as_department"
      unset_as_i18n: "projects_collection_unset_as_department"
      close_i18n: "projects_collection_close_department"
      closed_label_i18n: "projects_collection_closed_department_label"
      reopen_i18n: "projects_collection_reopen_department"
      add_sub_item_i18n: "projects_collection_create_sub_department"

      type_icon: { # The type icon is used for the - set as Projects Collection, on-grid indicator, the tab switcher dropdown, and other places where we refer to the Project Collection type.
        type: "feather"
        val: "folder"
        class: ""
      },
      unset_op_icon: { # Will appear next to the context menu operation for unsetting a Project Collection.
        type: "feather"
        val: "jd-folder-unset"
        class: ""
      },
      close_op_icon: { # Will appear next to the context menu operation for closing. Note that the closed state is the closed_icon, this is for the action of closing
        type: "feather"
        val: "jd-folder-close"
        class: ""
      },
      closed_icon: { # Will appear in on-grid indicator. Note that the icon for close op is close_op_icon
        type: "feather"
        val: "folder"
        class: "closed-projects-collection"
      },
      reopen_op_icon: { # Will appear next to the context menu operation for reopening.
        type: "feather"
        val: "folder"
        class: ""
      }
    }
  ]
  projects_without_pc_type_id: "projects_without_pc"
  projects_collection_default_fields_to_fetch:
    _id: 1
