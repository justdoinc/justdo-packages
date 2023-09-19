# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  _.extend project_page_module.items_types_settings,
      "default": # default is the null type
        task_pane_sections:
          [
            {
              id: "item-details"
              type: "ItemDetails"
              options:
                title: "Details"
                title_i18n: "item_details_title"
              section_options: {}
            }
            {
              id: "item-activity"
              type: "ItemChangeLog"
              options:
                title: "Activity"
                title_i18n: "item_activity_title"
              section_options: {}
            }
            # {
            #   id: "item-settings"
            #   type: "ItemSettings"
            #   options:
            #     title: "Settings"
            #   section_options: {}
            # }
          ]

      "section-item":
        task_pane_sections: []

      "multi-select":
        task_pane_sections: []

      "fallback": # fallback will be used for unknown types
        task_pane_sections: []
