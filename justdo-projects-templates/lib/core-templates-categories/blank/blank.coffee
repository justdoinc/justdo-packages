APP.justdo_projects_templates?.registerCategory
  id: "blank"
  label_i18n: "project_templates_blank_label"
  order: 0

APP.justdo_projects_templates?.registerTemplate
  id: "blank"
  label_i18n: "project_templates_blank_label"
  order: 0
  categories: ["blank"]
  template:
    users: ["performing_user"]
    tasks: [
      title_i18n: "project_templates_task_title_my_first_task"
      users: ["performing_user"]
      perform_as: "performing_user"
    ]
  demo_html_template: [
    { "level": 0, "task_id": "1", "title_i18n": "project_templates_task_title_my_first_task", "state_class": "pending", "state_title_i18n": "state_pending" }
  ]