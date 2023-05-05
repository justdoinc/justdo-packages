APP.justdo_projects_templates?.registerTemplate
  id: "movies-production"
  label: "Movies Production"
  categories: ["getting-started"]
  order: 103
  demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/template-categories/getting-started/movies-production.png"
  template:
    users: ["performing_user"]
    tasks: [
      title: "Movies"
      users: ["performing_user"]
      perform_as: "performing_user"
      tasks: [
        title: "Sleeping beauty"
        user: ["performing_user"]
        owner: ["performing_user"]
        events: [
          action: "toggleIsProject"
          args: "nil"
          perform_as: "performing_user"
        ]
        tasks: [
          title: "Development"
          user: ["performing_user"]
          owner: ["performing_user"]
          tasks: [
            title: "Evaluating and acquiring scripts or story ideas"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Developing story concepts into full-fledged screenplays"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Attaching key talent"
            user: ["performing_user"]
            owner: ["performing_user"]
            tasks: [
              title: "Potential actors"
              user: ["performing_user"]
              owner: ["performing_user"]
            ,
              title: "Directors"
              user: ["performing_user"]
              owner: ["performing_user"]
            ]
          ]
        ,
          title: "Pre-Production"
          user: ["performing_user"]
          owner: ["performing_user"]
          tasks: [
            title: "Finalizing script revisions"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Casting actors and hiring crew members"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Scouting and securing locations"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Developing budgets and shooting schedules"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Planning costume, set, and prop designs"
            user: ["performing_user"]
            owner: ["performing_user"]
          ]
        ,
          title: "Post-Production"
          user: ["performing_user"]
          owner: ["performing_user"]
          tasks: [
            title: "Editing  the film's picture and sound"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Overseeing visual effects and CGI work"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Collaborating with the composer on the film's score"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Managing the color grading process"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Finalizing the film's sound mix and mastering"
            user: ["performing_user"]
            owner: ["performing_user"]
          ]
        ,
          title: "Marketing and Distribution"
          user: ["performing_user"]
          owner: ["performing_user"]
          tasks: [
            title: "Developing marketing materials, including posters, trailers, and promotional campaigns"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Coordinating film festival submissions and screenings"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Securing distribution deals and arranging theatrical releases"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Managing public relations and media coverage"
            user: ["performing_user"]
            owner: ["performing_user"]
          ]
        ]
      ,
        title: "Snow White"
        user: ["performing_user"]
        owner: ["performing_user"]
        events: [
          action: "toggleIsProject"
          args: "nil"
          perform_as: "performing_user"
        ]
        tasks: [
          title: "Development"
          user: ["performing_user"]
          owner: ["performing_user"]
        ,
          title: "Pre-Production"
          user: ["performing_user"]
          owner: ["performing_user"]
        ,
          title: "Post-Production"
          user: ["performing_user"]
          owner: ["performing_user"]
        ,
          title: "Marketing and Distribution"
          user: ["performing_user"]
          owner: ["performing_user"]
        ]
      ,
        title: "Robin hood - completed"
        user: ["performing_user"]
        owner: ["performing_user"]
        events: [
          action: "setArchived"
          args: "nil"
          perform_as: "performing_user"
        ]
        tasks: [
          title: "Development"
          user: ["performing_user"]
          owner: ["performing_user"]
        ,
          title: "Pre-Production"
          user: ["performing_user"]
          owner: ["performing_user"]
        ,
          title: "Post-Production"
          user: ["performing_user"]
          owner: ["performing_user"]
        ,
          title: "Marketing and Distribution"
          user: ["performing_user"]
          owner: ["performing_user"]
        ]

      ]
    ,
      title: "Finance"
      user: ["performing_user"]
      owner: ["performing_user"]
      tasks: [
        title: "Funding identification and procurement"
        user: ["performing_user"]
        owner: ["performing_user"]
        tasks: [
          title: "Secure funds for Sleeping Beauty from GateFlix"
          user: ["performing_user"]
          owner: ["performing_user"]
          tasks: [
            title: "Negotiate terms and conditions"
            user: ["performing_user"]
            owner: ["performing_user"]
          ,
            title: "Draft a legal agreement"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "setStatus"
              args: "(Remember to exclude exclusive right to finance)"
              perform_as: "performing_user"
            ]
          ]
        ]
      ,
        title: "Cash flow management"
        user: ["performing_user"]
        owner: ["performing_user"]
      ,
        title: "Contract negotiation and management"
        user: ["performing_user"]
        owner: ["performing_user"]
      ]
    ,
      title: "HR"
      user: ["performing_user"]
      owner: ["performing_user"]
      tasks: [
        title: "Recruit position for Storyboard Artist"
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
