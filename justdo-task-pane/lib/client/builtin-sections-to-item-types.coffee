# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  _.extend module.items_types_settings,
      "default": # default is the null type
        task_pane_sections:
          [
            {
              id: "item-details"
              type: "ItemDetails"
              options:
                title: "Details"
              section_options: {}
            }
            {
              id: "item-activity"
              type: "ItemChangeLog"
              options:
                title: "Activity"
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

      "fallback": # fallback will be used for unknown types
        task_pane_sections: []
