APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return

  APP.justdo_projects_templates?.registerTemplate
    id: "movies-production"
    label: "Movies Production"
    categories: ["getting-started"]
    order: 130
    template:
      tasks: [
        title: "Movies"
        tasks: [
          title: "Sleeping beauty"
          events: [
            action: "toggleIsProject"
          ]
          tasks: [
            title: "Development"
            expand: true
            tasks: [
              title: "Evaluating and acquiring scripts or story ideas"
            ,
              title: "Developing story concepts into full-fledged screenplays"
            ,
              title: "Attaching key talent"
              expand: true
              tasks: [
                title: "Potential actors"
              ,
                title: "Directors"
              ]
            ]
          ,
            title: "Pre-Production"
            tasks: [
              title: "Finalizing script revisions"
            ,
              title: "Casting actors and hiring crew members"
            ,
              title: "Scouting and securing locations"
            ,
              title: "Developing budgets and shooting schedules"
            ,
              title: "Planning costume, set, and prop designs"
            ]
          ,
            title: "Post-Production"
            tasks: [
              title: "Editing  the film's picture and sound"
            ,
              title: "Overseeing visual effects and CGI work"
            ,
              title: "Collaborating with the composer on the film's score"
            ,
              title: "Managing the color grading process"
            ,
              title: "Finalizing the film's sound mix and mastering"
            ]
          ,
            title: "Marketing and Distribution"
            tasks: [
              title: "Developing marketing materials, including posters, trailers, and promotional campaigns"
            ,
              title: "Coordinating film festival submissions and screenings"
            ,
              title: "Securing distribution deals and arranging theatrical releases"
            ,
              title: "Managing public relations and media coverage"
            ]
          ]
        ,
          title: "Snow White"
          events: [
            action: "toggleIsProject"
          ]
          tasks: [
            title: "Development"
          ,
            title: "Pre-Production"
          ,
            title: "Post-Production"
          ,
            title: "Marketing and Distribution"
          ]
        ,
          title: "Robin hood - completed"
          events: [
            action: "setArchived"
            args: "nil"
          ]
          tasks: [
            title: "Development"
          ,
            title: "Pre-Production"
          ,
            title: "Post-Production"
          ,
            title: "Marketing and Distribution"
          ]
        ]
      ,
        title: "Finance"
        tasks: [
          title: "Funding identification and procurement"
          expand: true
          tasks: [
            title: "Secure funds for Sleeping Beauty from GateFlix"
            tasks: [
              title: "Negotiate terms and conditions"
            ,
              title: "Draft a legal agreement"
              events: [
                action: "setStatus"
                args: "(Remember to exclude exclusive right to finance)"
              ]
            ]
          ]
        ,
          title: "Cash flow management"
        ,
          title: "Contract negotiation and management"
        ]
      ,
        title: "HR"
        tasks: [
          title: "Recruit position for Storyboard Artist"
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
      { "level": 0, "expand_state": "minus", "task_id": "42", "title": "Movies", "state_class": "pending", "state_title": "Pending" },
      { "level": 1, "expand_state": "minus", "task_id": "43", "title": "Sleeping beauty", "state_class": "in-progress", "state_title": "in-progress" },
      { "level": 2, "expand_state": "minus", "task_id": "47", "title": "Development", "state_class": "in-progress", "state_title": "in-progress" },
      { "level": 3, "task_id": "52", "title": "Evaluating and acquiring scripts or story ideas", "state_class": "pending", "state_title": "Pending", "extra_padding": "extra-padding" },
      { "level": 3, "task_id": "53", "title": "Developing story concepts", "state_class": "in-progress", "state_title": "in-progress", "extra_padding": "extra-padding" },
      { "level": 3, "expand_state": "minus", "task_id": "54", "title": "Attaching key talent", "state_class": "pending", "state_title": "Pending" },
      { "level": 4, "task_id": "55", "title": "Potential actors", "state_class": "cancelled", "state_title": "Cancelled", "extra_padding": "extra-padding" },
      { "level": 4, "task_id": "56", "title": "Directors", "state_class": "done", "state_title": "Done", "extra_padding": "extra-padding" },
      { "level": 2, "expand_state": "plus", "task_id": "48", "title": "Pre-Production", "state_class": "pending", "state_title": "Pending" },
      { "level": 2, "expand_state": "plus", "task_id": "49", "title": "Post-Production", "state_class": "on-hold", "state_title": "On hold" },
      { "level": 2, "expand_state": "plus", "task_id": "51", "title": "Marketing and Distribution", "state_class": "cancelled", "state_title": "Cancelled" },
      { "level": 1, "expand_state": "plus", "task_id": "79", "title": "Snow white", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 1, "task_id": "84", "title": "Robin hood - completed", "state_class": "done", "state_title": "Done", "extra_padding": "extra-padding" },
      { "level": 1, "expand_state": "minus", "task_id": "3", "title": "Finance", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 2, "expand_state": "minus", "task_id": "76", "title": "Funding identification and procurement", "state_class": "pending", "state_title": "Pending" },
      { "level": 3, "expand_state": "plus", "task_id": "72", "title": "Secure funds for Sleeping Beauty from GateFlix", "state_class": "pending", "state_title": "Pending" },
      { "level": 2, "task_id": "77", "title": "Cash flow management", "state_class": "in-progress", "state_title": "In progress", "extra_padding": "extra-padding" },
      { "level": 2, "task_id": "78", "title": "Contract negotiation and management", "state_class": "pending", "state_title": "Pending", "extra_padding": "extra-padding" },
      { "level": 0, "expand_state": "plus", "task_id": "72", "title": "HR", "state_class": "pending", "state_title": "Pending" }
    ]
  return