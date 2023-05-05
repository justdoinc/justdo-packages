APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return
  APP.justdo_projects_templates?.registerTemplate
    id: "it-firm"
    label: "IT Firm"
    categories: ["getting-started"]
    order: 110
    demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/template-categories/getting-started/it-firm.png"
    template:
      users: ["performing_user"]
      tasks: [
        title: "R&D"
        tasks: [
          title: "Mobile App Development"
          state: "nil"
          tasks: [
            title: "Sprints"
            tasks: [
              title: "v0.0.1 (POC)"
              events: [
                action: "setArchived"
              ]
              tasks: [
                title: "Task a"
              ,
                title: "Task b"
              ]
            ,
              title: "v1.0.0"
              events: [
                action: "toggleIsProject"
              ]
              tasks: [
                title: "Implement new feature 1"
                tasks: [
                  title: "Design & UX/UI"
                  state: "nil"
                  tasks: [
                    title: "Requirements Gathering"
                  ,
                    title: "Wireframes"

                    state: "nil"
                  ,
                    title: "User Interface Design"

                    state: "nil"
                  ,
                    title: "User Experience Design"
                    state: "nil"
                  ]
                ,
                  title: "Backend Development"
                  state: "nil"
                  tasks: [
                    title: "Feature B"
                  ]
                ,
                  title: "Frontend Development"
                  state: "nil"
                  tasks: [
                    title: "Feature A"
                  ]
                ,
                  title: "QA"
                  tasks: [
                    title: "Write auto-test 1"
                  ,
                    title: "Write auto-test 2"
                  ]
                ]
              ]
            ,
              title: "v2.0.0"
              events: [
                action: "toggleIsProject"
              ]
              tasks: [
                title: "Implement new feature 2"
              ]
            ]
          ,
            title: "Roadmap"
            tasks: [
              title: "Roadmap feature 1"
            ,
              title: "Roadmap feature 2"
              events: [
                action: "setStatus"
                args: "Requested by client XYZ"
              ]
            ,
              title: "Roadmap feature 3"
              events: [
                action: "setStatus"
                args: "Requested by clients ABC, PMQ"
              ]
            ]
          ,
            title: "Mobile App QA"
            state: "nil"
            tasks: [
              title: "Bug tracking"
            ]
          ]
        ]
      ,
        title: "Finance"
        tasks: [
          title: "Prepare FY report"
          tasks: [
            title: "Contact auditor"
          ,
            title: "Prepare employer return"
          ]
        ]
      ,
        title: "Customer service"
        tasks: [
          title: "Client A"
          tasks: [
            title: "Deployment v3.0.0 on Client A server"
            state: "nil"
          ]
        ,
          title: "Client B"
          tasks: [
            title: "Contact to reproduce reported issue"
          ]
        ]
      ,
        title: "HR"
        tasks: [
          title: "Recruit position for frontend"
          tasks: [
            title: "Candidate A"
            events: [
              action: "setStatus"
              args: "Coordinate zoom meeting"
            ]
          ,
            title: "Candidate B"
            events: [
              action: "setStatus"
              args: "CV is missing, contact by email"
            ]
          ]
        ]
      ]

  return