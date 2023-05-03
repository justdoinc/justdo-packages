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
    "IT Firm":
      order: 101
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/dev.png"
      template:
        users: ["manager"]
        tasks: [
          title: "R&D"
          users: ["manager"]
          perform_as: "manager"
          tasks: [
            title: "Mobile App Development"
            user: ["manager"]
            owner: ["manager"]
            events: [
              action: "setState"
              args: "nil"
              perform_as: "manager"
            ]
            tasks: [
              title: "Sprints"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "v0.0.1 (POC)"
                user: ["manager"]
                owner: ["manager"]
                events: [
                  action: "setArchived"
                  args: ""
                  perform_as: "manager"
                ]
                tasks: [
                  title: "Task a"
                  user: ["manager"]
                  owner: ["manager"]
                ,
                  title: "Task b"
                  user: ["manager"]
                  owner: ["manager"]
                ]
              ,
                title: "v1.0.0"
                user: ["manager"]
                owner: ["manager"]
                events: [
                  action: "toggleIsProject"
                  args: ""
                  perform_as: "manager"
                ]
                tasks: [
                  title: "Implement new feature 1"
                  user: ["manager"]
                  owner: ["manager"]
                  tasks: [
                    title: "Design & UX/UI"
                    user: ["manager"]
                    owner: ["manager"]
                    events: [
                      action: "setState"
                      args: "nil"
                      perform_as: "manager"
                    ]
                    tasks: [
                      title: "Requirements Gathering"
                      user: ["manager"]
                      owner: ["manager"]
                    ,
                      title: "Wireframes"
                      user: ["manager"]
                      owner: ["manager"]
                      events: [
                        action: "setState"
                        args: "nil"
                        perform_as: "manager"
                      ]
                    ,
                      title: "User Interface Design"
                      user: ["manager"]
                      owner: ["manager"]
                      events: [
                        action: "setState"
                        args: "nil"
                        perform_as: "manager"
                      ]
                    ,
                      title: "User Experience Design"
                      user: ["manager"]
                      owner: ["manager"]
                      events: [
                        action: "setState"
                        args: "nil"
                        perform_as: "manager"
                      ]
                    ]
                  ,
                    title: "Backend Development"
                    user: ["manager"]
                    owner: ["manager"]
                    events: [
                      action: "setState"
                      args: "nil"
                      perform_as: "manager"
                    ]
                    tasks: [
                      title: "Feature B"
                      user: ["manager"]
                      owner: ["manager"]
                    ]
                  ,
                    title: "Frontend Development"
                    user: ["manager"]
                    owner: ["manager"]
                    events: [
                      action: "setState"
                      args: "nil"
                      perform_as: "manager"
                    ]
                    tasks: [
                      title: "Feature A"
                      user: ["manager"]
                      owner: ["manager"]
                    ]
                  ,
                    title: "QA"
                    user: ["manager"]
                    owner: ["manager"]
                    tasks: [
                      title: "Write auto-test 1"
                      user: ["manager"]
                      owner: ["manager"]
                    ,
                      title: "Write auto-test 2"
                      user: ["manager"]
                      owner: ["manager"]
                    ]
                  ]
                ]
              ,
                title: "v2.0.0"
                user: ["manager"]
                owner: ["manager"]
                events: [
                  action: "toggleIsProject"
                  args: ""
                  perform_as: "manager"
                ]
                tasks: [
                  title: "Implement new feature 2"
                  user: ["manager"]
                  owner: ["manager"]
                ]
              ]
            ,
              title: "Roadmap"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Roadmap feature 1"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Roadmap feature 2"
                user: ["manager"]
                owner: ["manager"]
                events: [
                  action: "setStatus"
                  args: "Requested by client XYZ"
                  perform_as: "manager"
                ]
              ,
                title: "Roadmap feature 3"
                user: ["manager"]
                owner: ["manager"]
                events: [
                  action: "setStatus"
                  args: "Requested by clients ABC, PMQ"
                  perform_as: "manager"
                ]
              ]
            ,
              title: "Mobile App QA"
              user: ["manager"]
              owner: ["manager"]
              events: [
                action: "setState"
                args: "nil"
                perform_as: "manager"
              ]
              tasks: [
                title: "Bug tracking"
                user: ["manager"]
                owner: ["manager"]
              ]
            ]
          ]
        ,
          title: "Finance"
          user: ["manager"]
          owner: ["manager"]
          tasks: [
            title: "Prepare FY report"
            user: ["manager"]
            owner: ["manager"]
            tasks: [
              title: "Contact auditor"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Prepare employer return"
              user: ["manager"]
              owner: ["manager"]
            ]
          ]
        ,
          title: "Customer service"
          user: ["manager"]
          owner: ["manager"]
          tasks: [
            title: "Client A"
            user: ["manager"]
            owner: ["manager"]
            tasks: [
              title: "Deployment v3.0.0 on Client A server"
              user: ["manager"]
              owner: ["manager"]
              events: [
                action: "setState"
                args: "nil"
                perform_as: "manager"
              ]
            ]
          ,
            title: "Client B"
            user: ["manager"]
            owner: ["manager"]
            tasks: [
              title: "Contact to reproduce reported issue"
              user: ["manager"]
              owner: ["manager"]
            ]
          ]
        ,
          title: "HR"
          user: ["manager"]
          owner: ["manager"]
          tasks: [
            title: "Recruit position for frontend"
            user: ["manager"]
            owner: ["manager"]
            tasks: [
              title: "Candidate A"
              user: ["manager"]
              owner: ["manager"]
              events: [
                action: "setStatus"
                args: "Coordinate zoom meeting"
                perform_as: "manager"
              ]
            ,
              title: "Candidate B"
              user: ["manager"]
              owner: ["manager"]
              events: [
                action: "setStatus"
                args: "CV is missing, contact by email"
                perform_as: "manager"
              ]
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
