APP.justdo_projects_templates?.registerTemplate
  id: "it-firm"
  label: "IT Firm"
  categories: ["getting-started"]
  order: 101
  demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/template-categories/getting-started/it-firm.png"
  template:
    users: ["performing_user"]
    tasks: [
      title: "R&D"
      users: ["performing_user"]
      perform_as: "performing_user"
      tasks: [
        title: "Mobile App Development"
        user: ["performing_user"]
        owner: ["performing_user"]
        state: "nil"
        tasks: [
          title: "Sprints"
          user: ["performing_user"]
          owner: ["performing_user"]
          tasks: [
            title: "v0.0.1 (POC)"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "setArchived"
              args: ""
              perform_as: "performing_user"
            ]
            tasks: [
              title: "Task a"
              user: ["performing_user"]
              owner: ["performing_user"]
            ,
              title: "Task b"
              user: ["performing_user"]
              owner: ["performing_user"]
            ]
          ,
            title: "v1.0.0"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "toggleIsProject"
              args: ""
              perform_as: "performing_user"
            ]
            tasks: [
              title: "Implement new feature 1"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Design & UX/UI"
                user: ["performing_user"]
                owner: ["performing_user"]
                state: "nil"
                tasks: [
                  title: "Requirements Gathering"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                ,
                  title: "Wireframes"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                  state: "nil"
                ,
                  title: "User Interface Design"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                  state: "nil"
                ,
                  title: "User Experience Design"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                  state: "nil"
                ]
              ,
                title: "Backend Development"
                user: ["performing_user"]
                owner: ["performing_user"]
                state: "nil"
                tasks: [
                  title: "Feature B"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                ]
              ,
                title: "Frontend Development"
                user: ["performing_user"]
                owner: ["performing_user"]
                state: "nil"
                tasks: [
                  title: "Feature A"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                ]
              ,
                title: "QA"
                user: ["performing_user"]
                owner: ["performing_user"]
                tasks: [
                  title: "Write auto-test 1"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                ,
                  title: "Write auto-test 2"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                ]
              ]
            ]
          ,
            title: "v2.0.0"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "toggleIsProject"
              args: ""
              perform_as: "performing_user"
            ]
            tasks: [
              title: "Implement new feature 2"
              user: ["performing_user"]
              owner: ["performing_user"]
            ]
          ]
        ,
          title: "Roadmap"
          user: ["performing_user"]
          owner: ["performing_user"]
          tasks: [
            title: "Roadmap feature 1"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Roadmap feature 2"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "setStatus"
              args: "Requested by client XYZ"
              perform_as: "performing_user"
            ]
          ,
            title: "Roadmap feature 3"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "setStatus"
              args: "Requested by clients ABC, PMQ"
              perform_as: "performing_user"
            ]
          ]
        ,
          title: "Mobile App QA"
          user: ["performing_user"]
          owner: ["performing_user"]
          state: "nil"
          tasks: [
            title: "Bug tracking"
            user: ["performing_user"]
            owner: ["performing_user"]
          ]
        ]
      ]
    ,
      title: "Finance"
      user: ["performing_user"]
      owner: ["performing_user"]
      tasks: [
        title: "Prepare FY report"
        user: ["performing_user"]
        owner: ["performing_user"]
        tasks: [
          title: "Contact auditor"
          user: ["performing_user"]
          owner: ["performing_user"]
        ,
          title: "Prepare employer return"
          user: ["performing_user"]
          owner: ["performing_user"]
        ]
      ]
    ,
      title: "Customer service"
      user: ["performing_user"]
      owner: ["performing_user"]
      tasks: [
        title: "Client A"
        user: ["performing_user"]
        owner: ["performing_user"]
        tasks: [
          title: "Deployment v3.0.0 on Client A server"
          user: ["performing_user"]
          owner: ["performing_user"]
          state: "nil"
        ]
      ,
        title: "Client B"
        user: ["performing_user"]
        owner: ["performing_user"]
        tasks: [
          title: "Contact to reproduce reported issue"
          user: ["performing_user"]
          owner: ["performing_user"]
        ]
      ]
    ,
      title: "HR"
      user: ["performing_user"]
      owner: ["performing_user"]
      tasks: [
        title: "Recruit position for frontend"
        user: ["performing_user"]
        owner: ["performing_user"]
        tasks: [
          title: "Candidate A"
          user: ["performing_user"]
          owner: ["performing_user"]
          events: [
            action: "setStatus"
            args: "Coordinate zoom meeting"
            perform_as: "performing_user"
          ]
        ,
          title: "Candidate B"
          user: ["performing_user"]
          owner: ["performing_user"]
          events: [
            action: "setStatus"
            args: "CV is missing, contact by email"
            perform_as: "performing_user"
          ]
        ]
      ]
    ]
