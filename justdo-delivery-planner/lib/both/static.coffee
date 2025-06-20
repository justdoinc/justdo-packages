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

  projects_collection_plugin_id: "projects_collection"
  projects_collection_plugin_name_i18n: "projects_collection_default_type_label"

  is_projects_collection_enabled_globally: false

  projects_collections_types: [
    {
      type_id: "projects_collection"

      type_label_i18n: "projects_collection_default_type_label"
      type_label_plural_i18n: "projects_collection_default_type_label_plural"

      set_as_i18n: "projects_collection_set_as_default_projects_collection"
      unset_as_i18n: "projects_collection_unset_as_default_projects_collection"
      close_i18n: "projects_collection_close_default_projects_collection"
      closed_label_i18n: "projects_collection_closed_default_projects_collection_label"
      reopen_i18n: "projects_collection_reopen_default_projects_collection"
      add_sub_item_i18n: "projects_collection_create_sub_projects_collection"

      type_icon: { # The type icon is used for the - set as Projects Collection, on-grid indicator, the tab switcher dropdown, and other places where we refer to the Project Collection type.
        type: "feather"
        val: "folder"
        class: ""
      },
      unset_op_icon: { # Will appear next to the context menu operation for unsetting a Project Collection.
        type: "feather"
        val: "jd-folder-unset"
        class: ""
      }
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
      },

      onGridClick: (e, event_item) -> # This will be called when the user clicks on the Projects Collection on-grid indicator
        console.log "onGridClick projects_collection"
        console.log {e, event_item}
        return

      onGridProjectClick: (e, event_item, event_parent_item) -> # This will be called when the user clicks on a project that is under this projects collection
        console.log "onGridProjectClick projects_collection"
        console.log {e, event_item, event_parent_item}
        return
    },
    # {
    #   type_id: "pseudo_department_type_for_testing"

    #   type_label_i18n: "projects_collection_department_label"
    #   type_label_plural_i18n: "projects_collection_department_label_plural"

    #   set_as_i18n: "projects_collection_set_as_department"
    #   unset_as_i18n: "projects_collection_unset_as_department"
    #   close_i18n: "projects_collection_close_department"
    #   closed_label_i18n: "projects_collection_closed_department_label"
    #   reopen_i18n: "projects_collection_reopen_department"

    #   type_icon: { # The type icon is used for the - set as Projects Collection, on-grid indicator, the tab switcher dropdown, and other places where we refer to the Project Collection type.
    #     type: "feather"
    #     val: "folder"
    #     class: ""
    #   },
    #   unset_op_icon: { # Will appear next to the context menu operation for unsetting a Project Collection.
    #     type: "feather"
    #     val: "jd-folder-unset"
    #     class: ""
    #   },
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
    #   },

    #   onGridClick: (e, event_item) -> # This will be called when the user clicks on the Projects Collection on-grid indicator
    #     console.log "onGridClick department"
    #     console.log {e, event_item}

    #     return

    #   onGridProjectClick: (e, event_item, event_parent_item) -> # This will be called when the user clicks on a project that is under this projects collection
    #     console.log "onGridProjectClick department"
    #     console.log {e, event_item, event_parent_item}

    #     return
    # }
  ]
  projects_collection_default_fields_to_fetch:
    _id: 1
