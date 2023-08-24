APP.justdo_projects_templates?.registerCategory
  id: "blank"
  label: "Blank"
  order: 0

APP.justdo_projects_templates?.registerTemplate
  id: "blank"
  label: "Blank"
  order: 0
  demo_img_src: "/packages/justdoinc_justdo-projects-templates/lib/core-templates-categories/blank/blank.png"
  categories: ["blank"]
  template:
    users: ["performing_user"]
    tasks: [
      title: "My First Task"
      users: ["performing_user"]
      perform_as: "performing_user"
    ]
  demo_html_template: [
    { "level": 0, "task_id": "1", "title": "My First Task", "state_class": "pending", "state_title": "Pending" }
  ]