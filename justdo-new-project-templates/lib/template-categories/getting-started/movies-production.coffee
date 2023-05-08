APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return

  APP.justdo_projects_templates?.registerTemplate
    id: "movies-production"
    label: "Movies Production"
    categories: ["getting-started"]
    order: 130
    demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/template-categories/getting-started/movies-production.png"
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

  return