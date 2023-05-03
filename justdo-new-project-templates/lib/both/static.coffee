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
    "Home Builders Inc":
      order: 102
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/sales.png"
      template:
        users: ["manager"]
        tasks: [
          title: "Sites"
          users: ["manager"]
          perform_as: "manager"
          tasks: [
            title: "Meadowview Estates"
            user: ["manager"]
            owner: ["manager"]
            events: [
              action: "toggleIsProject"
              args: ""
              perform_as: "manager"
            ]
            tasks: [
              title: "Project Planning"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Scope Definition"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Timeline & Budgeting"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Permitting & Compliance"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Design & Engineering"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Architectural Design"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Structural Engineering"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Mechanical, Electrical & Plumbing (MEP)"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Site Preparation"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Land Surveying"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Site Clearing"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Excavation & Grading"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Construction"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Framing & Structural Work"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Interior & Exterior Finishing"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Landscaping"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Inspection & Quality Control"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Code Compliance"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Safety Inspections"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Punch List"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Project Closeout"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Final Documentation"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Warranty & Maintenance"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Client Handover"
                user: ["manager"]
                owner: ["manager"]
              ]
            ]
          ,
            title: "Willow Creek Village"
            user: ["manager"]
            owner: ["manager"]
            events: [
              action: "toggleIsProject"
              args: ""
              perform_as: "manager"
            ]
            tasks: [
              title: "Project Planning"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Scope Definition"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Timeline & Budgeting"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Permitting & Compliance"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Design & Engineering"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Architectural Design"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Structural Engineering"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Mechanical, Electrical & Plumbing (MEP)"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Site Preparation"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Land Surveying"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Site Clearing"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Excavation & Grading"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Construction"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Framing & Structural Work"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Interior & Exterior Finishing"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Landscaping"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Inspection & Quality Control"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Code Compliance"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Safety Inspections"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Punch List"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Project Closeout"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Final Documentation"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Warranty & Maintenance"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Client Handover"
                user: ["manager"]
                owner: ["manager"]
              ]
            ]
          ,
            title: "Oak Ridge Heights - completed"
            user: ["manager"]
            owner: ["manager"]
            events: [
              action: "setArchived"
              args: ""
              perform_as: "manager"
            ]
            tasks: [
              title: "Project Planning"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Scope Definition"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Timeline & Budgeting"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Permitting & Compliance"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Design & Engineering"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Architectural Design"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Structural Engineering"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Mechanical, Electrical & Plumbing (MEP)"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Site Preparation"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Land Surveying"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Site Clearing"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Excavation & Grading"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Construction"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Framing & Structural Work"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Interior & Exterior Finishing"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Landscaping"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Inspection & Quality Control"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Code Compliance"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Safety Inspections"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Punch List"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Project Closeout"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Final Documentation"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Warranty & Maintenance"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Client Handover"
                user: ["manager"]
                owner: ["manager"]
              ]
            ]
          ,
            title: "Pinecrest Meadows - Completed"
            user: ["manager"]
            owner: ["manager"]
            events: [
              action: "setArchived"
              args: ""
              perform_as: "manager"
            ]
            tasks: [
              title: "Project Planning"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Scope Definition"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Timeline & Budgeting"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Permitting & Compliance"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Design & Engineering"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Architectural Design"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Structural Engineering"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Mechanical, Electrical & Plumbing (MEP)"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Site Preparation"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Land Surveying"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Site Clearing"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Excavation & Grading"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Construction"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Framing & Structural Work"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Interior & Exterior Finishing"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Landscaping"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Inspection & Quality Control"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Code Compliance"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Safety Inspections"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Punch List"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Project Closeout"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Final Documentation"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Warranty & Maintenance"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Client Handover"
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
            title: "Secure financing for Meadowview Estates"
            user: ["manager"]
            owner: ["manager"]
            tasks: [
              title: "Determine Loan Requirements"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Create a Financial Model"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Identify Potential Lenders"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Bank A"
                user: ["manager"]
                owner: ["manager"]
                tasks: [
                  title: "Obtain Preliminary Approvals"
                  user: ["manager"]
                  owner: ["manager"]
                ]
              ,
                title: "Bank B"
                user: ["manager"]
                owner: ["manager"]
                tasks: [
                  title: "Prepare Business Plan"
                  user: ["manager"]
                  owner: ["manager"]
                ]
              ]

            ]
          ,
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
          title: "HR"
          user: ["manager"]
          owner: ["manager"]
          tasks: [
            title: "Recruit an on-site engineer"
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
    "Movies Production":
      order: 103
      demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/client/assets/empty.jpg"
      template:
        users: ["manager"]
        tasks: [
          title: "Movies"
          users: ["manager"]
          perform_as: "manager"
          tasks: [
            title: "Sleeping beauty"
            user: ["manager"]
            owner: ["manager"]
            events: [
              action: "toggleIsProject"
              args: "nil"
              perform_as: "manager"
            ]
            tasks: [
              title: "Development"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Evaluating and acquiring scripts or story ideas"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Developing story concepts into full-fledged screenplays"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Attaching key talent"
                user: ["manager"]
                owner: ["manager"]
                tasks: [
                  title: "Potential actors"
                  user: ["manager"]
                  owner: ["manager"]
                ,
                  title: "Directors"
                  user: ["manager"]
                  owner: ["manager"]
                ]
              ]
            ,
              title: "Pre-Production"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Finalizing script revisions"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Casting actors and hiring crew members"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Scouting and securing locations"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Developing budgets and shooting schedules"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Planning costume, set, and prop designs"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Post-Production"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Editing  the film's picture and sound"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Overseeing visual effects and CGI work"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Collaborating with the composer on the film's score"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Managing the color grading process"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Finalizing the film's sound mix and mastering"
                user: ["manager"]
                owner: ["manager"]
              ]
            ,
              title: "Marketing and Distribution"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Developing marketing materials, including posters, trailers, and promotional campaigns"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Coordinating film festival submissions and screenings"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Securing distribution deals and arranging theatrical releases"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Managing public relations and media coverage"
                user: ["manager"]
                owner: ["manager"]
              ]
            ]
          ,
            title: "Snow White"
            user: ["manager"]
            owner: ["manager"]
            events: [
              action: "toggleIsProject"
              args: "nil"
              perform_as: "manager"
            ]
            tasks: [
              title: "Development"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Pre-Production"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Post-Production"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Marketing and Distribution"
              user: ["manager"]
              owner: ["manager"]
            ]
          ,
            title: "Robin hood - completed"
            user: ["manager"]
            owner: ["manager"]
            events: [
              action: "setArchived"
              args: "nil"
              perform_as: "manager"
            ]
            tasks: [
              title: "Development"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Pre-Production"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Post-Production"
              user: ["manager"]
              owner: ["manager"]
            ,
              title: "Marketing and Distribution"
              user: ["manager"]
              owner: ["manager"]
            ]

          ]
        ,
          title: "Finance"
          user: ["manager"]
          owner: ["manager"]
          tasks: [
            title: "Funding identification and procurement"
            user: ["manager"]
            owner: ["manager"]
            tasks: [
              title: "Secure funds for Sleeping Beauty from GateFlix"
              user: ["manager"]
              owner: ["manager"]
              tasks: [
                title: "Negotiate terms and conditions"
                user: ["manager"]
                owner: ["manager"]
              ,
                title: "Draft a legal agreement"
                user: ["manager"]
                owner: ["manager"]
                events: [
                  action: "setStatus"
                  args: "(Remember to exclude exclusive right to finance)"
                  perform_as: "manager"
                ]
              ]
            ]
          ,
            title: "Cash flow management"
            user: ["manager"]
            owner: ["manager"]
          ,
            title: "Contract negotiation and management"
            user: ["manager"]
            owner: ["manager"]
          ]
        ,
          title: "HR"
          user: ["manager"]
          owner: ["manager"]
          tasks: [
            title: "Recruit position for Storyboard Artist"
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
