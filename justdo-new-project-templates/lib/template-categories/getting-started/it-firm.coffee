APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return
  APP.justdo_projects_templates?.registerTemplate
    id: "it-firm"
    label: "IT Firm"
    categories: ["getting-started"]
    order: 110
    template:
      tasks: [
        title: "R&D"
        tasks: [
          title: "Mobile App Development"
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
                  expand: true
                  tasks: [
                    title: "Requirements Gathering"
                  ,
                    title: "Wireframes"
                  ,
                    title: "User Interface Design"
                  ,
                    title: "User Experience Design"
                  ]
                ,
                  title: "Backend Development"
                  expand: true
                  tasks: [
                    title: "Feature B"
                  ]
                ,
                  title: "Frontend Development"
                  expand: true
                  tasks: [
                    title: "Feature A"
                  ]
                ,
                  title: "QA"
                  expand: true
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
    demo_html_template: [
      { "level": 0, "expand_state": "minus", "task_id": "1", "title": "R&D", "state_class": "pending", "state_title": "Pending" },
      { "level": 1, "expand_state": "minus", "task_id": "25", "title": "Mobile App Development", "state_class": "pending", "state_title": "Pending" },
      { "level": 2, "expand_state": "minus", "task_id": "45", "title": "Sprints", "state_class": "pending", "state_title": "Pending" },
      { "level": 3, "task_id": "47", "title": "v0.0.1 (POC)", "state_class": "done", "state_title": "Done", "extra_padding": "extra-padding" },
      { "level": 3, "expand_state": "minus", "task_id": "63", "title": "v1.0.0", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 4, "expand_state": "minus", "task_id": "53", "title": "Implement new feature 1", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 5, "expand_state": "minus", "task_id": "8", "title": "Design & UX/UI", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 6, "task_id": "54", "title": "Requirements Gathering", "state_class": "in-progress", "state_title": "In progress", "extra_padding": "extra-padding" },
      { "level": 6, "task_id": "9", "title": "Wireframes", "state_class": "done", "state_title": "Done", "extra_padding": "extra-padding" },
      { "level": 6, "task_id": "10", "title": "User Interface Design", "state_class": "done", "state_title": "Done", "extra_padding": "extra-padding" },
      { "level": 6, "task_id": "11", "title": "User Experience Design", "state_class": "cancelled", "state_title": "Cancelled", "extra_padding": "extra-padding" },
      { "level": 5, "expand_state": "minus", "task_id": "14", "title": "Backend Development", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 6, "task_id": "35", "title": "Feature B", "state_class": "pending", "state_title": "Pending", "extra_padding": "extra-padding" },
      { "level": 5, "expand_state": "minus", "task_id": "13", "title": "Frontend Development", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 6, "task_id": "34", "title": "Feature A", "state_class": "on-hold", "state_title": "On hold", "extra_padding": "extra-padding" },
      { "level": 5, "expand_state": "minus", "task_id": "60", "title": "QA", "state_class": "pending", "state_title": "Pending" },
      { "level": 6, "task_id": "61", "title": "Write auto-test 1", "state_class": "in-progress", "state_title": "In progress", "extra_padding": "extra-padding" },
      { "level": 6, "task_id": "62", "title": "Write auto-test 2", "state_class": "in-progress", "state_title": "In progress", "extra_padding": "extra-padding" },
      { "level": 2, "expand_state": "plus", "task_id": "71", "title": "v200", "state_class": "done", "state_title": "Done" },
      { "level": 1, "expand_state": "plus", "task_id": "46", "title": "Roadmap", "state_class": "pending", "state_title": "Pending" },
      { "level": 1, "expand_state": "plus", "task_id": "16", "title": "Mobile App QA", "state_class": "pending", "state_title": "Pending" },
      { "level": 0, "expand_state": "plus", "task_id": "43", "title": "Finance", "state_class": "pending", "state_title": "Pending" },
      { "level": 0, "expand_state": "plus", "task_id": "55", "title": "Customer service", "state_class": "pending", "state_title": "Pending" },
      { "level": 0, "expand_state": "plus", "task_id": "41", "title": "HR", "state_class": "pending", "state_title": "Pending" },
    ]
  return