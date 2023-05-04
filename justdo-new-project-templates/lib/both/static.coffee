_.extend JustdoNewProjectTemplates,
  plugin_human_readable_name: "justdo-new-project-templates"

  new_project_templates:
    "it-firm":
      name: "IT Firm"
      category: "getting-started"
      order: 101
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/it-firm.png"
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
            events: [
              action: "setState"
              args: "nil"
              perform_as: "performing_user"
            ]
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
                    events: [
                      action: "setState"
                      args: "nil"
                      perform_as: "performing_user"
                    ]
                    tasks: [
                      title: "Requirements Gathering"
                      user: ["performing_user"]
                      owner: ["performing_user"]
                    ,
                      title: "Wireframes"
                      user: ["performing_user"]
                      owner: ["performing_user"]
                      events: [
                        action: "setState"
                        args: "nil"
                        perform_as: "performing_user"
                      ]
                    ,
                      title: "User Interface Design"
                      user: ["performing_user"]
                      owner: ["performing_user"]
                      events: [
                        action: "setState"
                        args: "nil"
                        perform_as: "performing_user"
                      ]
                    ,
                      title: "User Experience Design"
                      user: ["performing_user"]
                      owner: ["performing_user"]
                      events: [
                        action: "setState"
                        args: "nil"
                        perform_as: "performing_user"
                      ]
                    ]
                  ,
                    title: "Backend Development"
                    user: ["performing_user"]
                    owner: ["performing_user"]
                    events: [
                      action: "setState"
                      args: "nil"
                      perform_as: "performing_user"
                    ]
                    tasks: [
                      title: "Feature B"
                      user: ["performing_user"]
                      owner: ["performing_user"]
                    ]
                  ,
                    title: "Frontend Development"
                    user: ["performing_user"]
                    owner: ["performing_user"]
                    events: [
                      action: "setState"
                      args: "nil"
                      perform_as: "performing_user"
                    ]
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
              events: [
                action: "setState"
                args: "nil"
                perform_as: "performing_user"
              ]
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
              events: [
                action: "setState"
                args: "nil"
                perform_as: "performing_user"
              ]
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
    "home-builders-inc":
      name: "Home Builders Inc"
      category: "getting-started"
      order: 102
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/home-builders-inc.png"
      template:
        users: ["performing_user"]
        tasks: [
          title: "Sites"
          users: ["performing_user"]
          perform_as: "performing_user"
          tasks: [
            title: "Meadowview Estates"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "toggleIsProject"
              args: ""
              perform_as: "performing_user"
            ]
            tasks: [
              title: "Project Planning"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Scope Definition"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Timeline & Budgeting"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Permitting & Compliance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Design & Engineering"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Architectural Design"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Structural Engineering"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Mechanical, Electrical & Plumbing (MEP)"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Site Preparation"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Land Surveying"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Site Clearing"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Excavation & Grading"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Construction"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Framing & Structural Work"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Interior & Exterior Finishing"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Landscaping"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Inspection & Quality Control"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Code Compliance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Safety Inspections"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Punch List"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Project Closeout"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Final Documentation"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Warranty & Maintenance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Client Handover"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ]
          ,
            title: "Willow Creek Village"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "toggleIsProject"
              args: ""
              perform_as: "performing_user"
            ]
            tasks: [
              title: "Project Planning"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Scope Definition"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Timeline & Budgeting"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Permitting & Compliance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Design & Engineering"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Architectural Design"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Structural Engineering"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Mechanical, Electrical & Plumbing (MEP)"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Site Preparation"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Land Surveying"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Site Clearing"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Excavation & Grading"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Construction"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Framing & Structural Work"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Interior & Exterior Finishing"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Landscaping"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Inspection & Quality Control"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Code Compliance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Safety Inspections"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Punch List"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Project Closeout"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Final Documentation"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Warranty & Maintenance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Client Handover"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ]
          ,
            title: "Oak Ridge Heights - completed"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "setArchived"
              args: ""
              perform_as: "performing_user"
            ]
            tasks: [
              title: "Project Planning"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Scope Definition"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Timeline & Budgeting"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Permitting & Compliance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Design & Engineering"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Architectural Design"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Structural Engineering"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Mechanical, Electrical & Plumbing (MEP)"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Site Preparation"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Land Surveying"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Site Clearing"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Excavation & Grading"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Construction"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Framing & Structural Work"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Interior & Exterior Finishing"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Landscaping"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Inspection & Quality Control"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Code Compliance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Safety Inspections"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Punch List"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Project Closeout"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Final Documentation"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Warranty & Maintenance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Client Handover"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ]
          ,
            title: "Pinecrest Meadows - Completed"
            user: ["performing_user"]
            owner: ["performing_user"]
            events: [
              action: "setArchived"
              args: ""
              perform_as: "performing_user"
            ]
            tasks: [
              title: "Project Planning"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Scope Definition"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Timeline & Budgeting"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Permitting & Compliance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Design & Engineering"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Architectural Design"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Structural Engineering"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Mechanical, Electrical & Plumbing (MEP)"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Site Preparation"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Land Surveying"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Site Clearing"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Excavation & Grading"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Construction"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Framing & Structural Work"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Interior & Exterior Finishing"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Landscaping"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Inspection & Quality Control"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Code Compliance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Safety Inspections"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Punch List"
                user: ["performing_user"]
                owner: ["performing_user"]
              ]
            ,
              title: "Project Closeout"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Final Documentation"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Warranty & Maintenance"
                user: ["performing_user"]
                owner: ["performing_user"]
              ,
                title: "Client Handover"
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
            title: "Secure financing for Meadowview Estates"
            user: ["performing_user"]
            owner: ["performing_user"]
            tasks: [
              title: "Determine Loan Requirements"
              user: ["performing_user"]
              owner: ["performing_user"]
            ,
              title: "Create a Financial Model"
              user: ["performing_user"]
              owner: ["performing_user"]
            ,
              title: "Identify Potential Lenders"
              user: ["performing_user"]
              owner: ["performing_user"]
              tasks: [
                title: "Bank A"
                user: ["performing_user"]
                owner: ["performing_user"]
                tasks: [
                  title: "Obtain Preliminary Approvals"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                ]
              ,
                title: "Bank B"
                user: ["performing_user"]
                owner: ["performing_user"]
                tasks: [
                  title: "Prepare Business Plan"
                  user: ["performing_user"]
                  owner: ["performing_user"]
                ]
              ]

            ]
          ,
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
          title: "HR"
          user: ["performing_user"]
          owner: ["performing_user"]
          tasks: [
            title: "Recruit an on-site engineer"
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
    "movies-production":
      name: "Movies Production"
      category: "getting-started"
      order: 103
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/movies-production.png"
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
