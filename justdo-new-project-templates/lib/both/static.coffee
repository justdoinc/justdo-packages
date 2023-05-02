_.extend JustdoNewProjectTemplates,
  plugin_human_readable_name: "justdo-new-project-templates"

  default_project_templates:
    default:
      order: 100
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/empty.jpg"
      template:
        users: ["manager"]
        tasks: [
          title: "Untitled Task"
          users: ["manager"]
          perform_as: "manager"
        ]
    dev:
      order: 101
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/dev.png"
      template:
        users: ["manager"]
        tasks: [
          title: "Sprints"
          users: ["manager"]
          perform_as: "manager"
          tasks: [
            title: "Archived sprints"
            user: ["manager"]
            owner: ["manager"]
          ,
            title: "v3.132.x - LTS (Long Term Support)"
            user: ["manager"]
            owner: ["manager"]
            tasks: [
              title: "Demo task 1"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Demo task 2"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Demo task 3"
              user: ["manager"]
              owner: ["manager"]
            ]
          ,
            title: "v3.136.x - stable"
            user: ["manager"]
            owner: ["manager"]
            tasks: [
              title: "Demo task 1"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Demo task 2"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Demo task 3"
              user: ["manager"]
              owner: ["manager"]
            ]
          ,
            title: "v3.137.x - experimental"
            user: ["manager"]
            owner: ["manager"]
            tasks: [
              title: "Demo task 1"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Demo task 2"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Demo task 3"
              user: ["manager"]
              owner: ["manager"]
            ]
          ]
        ]
    sales:
      order: 102
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/sales.png"
      template:
        users: ["manager"]
        tasks: [
          title: "Research & Development"
          users: ["manager"]
          perform_as: "manager"
          tasks: [
            title: "Customer Care"
            users: ["manager"]
            owner: "manager"
          ,
            title: "Lamp"
            users: ["manager"]
            owner: "manager"
            events: [
              action: "setPendingOwner"
              args: "manager"
            ,
              action: "setDueDate"
              args: "2017-05-19"
            ,
              action: "update"
              args:
                $set:
                  description: "<p>Do X</p>"
            ,
              action: "setOwner"
              args: "manager"
              perform_as: "manager"
            ,
              action: "setStatus"
              args: "Test status message"
              perform_as: "manager"
            ,
              action: "setState"
              args: "in-progress"
              perform_as: "manager"
            ,
              action: "setFollowUp"
              args: "2017-05-08"
              perform_as: "manager"
            ]
          ,
            title: "Hardware"
            users: ["manager"]
            owner: "manager"
            key: "hardware"
          ,
            title: "Packaging"
            users: ["manager"]
            owner: "manager"
          ,
            title: "QA"
            users: ["manager"]
            owner: "manager"
          ,
            title: "Updates on Lamp Research & Development"
            users: ["manager"]
            owner: "manager"
          ,
            title: "Lighting the Way"
            users: ["manager"]
            owner: "manager"
          ]
        ,
          title: "R&D"
          users: ["manager"]
          owner: "manager"
          perform_as: "manager"
          events: [
            action: "addParents"
            args: ["hardware"]
            perform_as: "manager"
          ]
        ]
    wiki:
      order: 103
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/empty.jpg"
      template:
        users: ["manager"]
        tasks: [
          title: "Untitled Task"
          users: ["manager"]
          perform_as: "manager"
        ]
