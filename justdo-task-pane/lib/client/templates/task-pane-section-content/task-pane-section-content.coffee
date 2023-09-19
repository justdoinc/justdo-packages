# Do not use this package as example for how packages in
# JustDo should look like, refer to README.md to read more

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  Template.task_pane_section_content.helpers project_page_module.template_helpers