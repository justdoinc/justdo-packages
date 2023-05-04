_.extend JustDoProjectsTemplates,
  default_project_templates:
    default:
      name: "Default"
      category: "blank"
      order: 999
      demo_img_src: "/packages/justdoinc_justdo-projects-templates/lib/client/assets/blank.jpg"
      template:
        users: ["performing_user"]
        tasks: [
          title: "Untitled Task"
          users: ["performing_user"]
          perform_as: "performing_user"
        ]
