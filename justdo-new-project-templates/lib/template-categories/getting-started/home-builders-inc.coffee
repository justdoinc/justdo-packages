APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return

  APP.justdo_projects_templates?.registerTemplate
    id: "home-builders-inc"
    label: "Home Builders Inc"
    order: 120
    categories: ["getting-started"]
    template:
      tasks: [
        title: "Sites"
        tasks: [
          title: "Meadowview Estates"
          events: [
            action: "toggleIsProject"
          ]
          tasks: [
            title: "Project Planning"
            expand: true
            tasks: [
              title: "Scope Definition"
            ,
              title: "Timeline & Budgeting"
            ,
              title: "Permitting & Compliance"
            ]
          ,
            title: "Design & Engineering"
            tasks: [
              title: "Architectural Design"
            ,
              title: "Structural Engineering"
            ,
              title: "Mechanical, Electrical & Plumbing (MEP)"
            ]
          ,
            title: "Site Preparation"
            tasks: [
              title: "Land Surveying"
            ,
              title: "Site Clearing"
            ,
              title: "Excavation & Grading"
            ]
          ,
            title: "Construction"
            tasks: [
              title: "Framing & Structural Work"
            ,
              title: "Interior & Exterior Finishing"
            ,
              title: "Landscaping"
            ]
          ,
            title: "Inspection & Quality Control"
            tasks: [
              title: "Code Compliance"
            ,
              title: "Safety Inspections"
            ,
              title: "Punch List"
            ]
          ,
            title: "Project Closeout"
            tasks: [
              title: "Final Documentation"
            ,
              title: "Warranty & Maintenance"
            ,
              title: "Client Handover"
            ]
          ]
        ,
          title: "Willow Creek Village"
          events: [
            action: "toggleIsProject"
          ]
          tasks: [
            title: "Project Planning"
            tasks: [
              title: "Scope Definition"
            ,
              title: "Timeline & Budgeting"
            ,
              title: "Permitting & Compliance"
            ]
          ,
            title: "Design & Engineering"
            tasks: [
              title: "Architectural Design"
            ,
              title: "Structural Engineering"
            ,
              title: "Mechanical, Electrical & Plumbing (MEP)"
            ]
          ,
            title: "Site Preparation"
            tasks: [
              title: "Land Surveying"
            ,
              title: "Site Clearing"
            ,
              title: "Excavation & Grading"
            ]
          ,
            title: "Construction"
            tasks: [
              title: "Framing & Structural Work"
            ,
              title: "Interior & Exterior Finishing"
            ,
              title: "Landscaping"
            ]
          ,
            title: "Inspection & Quality Control"
            tasks: [
              title: "Code Compliance"
            ,
              title: "Safety Inspections"
            ,
              title: "Punch List"
            ]
          ,
            title: "Project Closeout"
            tasks: [
              title: "Final Documentation"
            ,
              title: "Warranty & Maintenance"
            ,
              title: "Client Handover"
            ]
          ]
        ,
          title: "Oak Ridge Heights - completed"
          events: [
            action: "setArchived"
          ]
          tasks: [
            title: "Project Planning"
            tasks: [
              title: "Scope Definition"
            ,
              title: "Timeline & Budgeting"
            ,
              title: "Permitting & Compliance"
            ]
          ,
            title: "Design & Engineering"
            tasks: [
              title: "Architectural Design"
            ,
              title: "Structural Engineering"
            ,
              title: "Mechanical, Electrical & Plumbing (MEP)"
            ]
          ,
            title: "Site Preparation"
            tasks: [
              title: "Land Surveying"
            ,
              title: "Site Clearing"
            ,
              title: "Excavation & Grading"
            ]
          ,
            title: "Construction"
            tasks: [
              title: "Framing & Structural Work"
            ,
              title: "Interior & Exterior Finishing"
            ,
              title: "Landscaping"
            ]
          ,
            title: "Inspection & Quality Control"
            tasks: [
              title: "Code Compliance"
            ,
              title: "Safety Inspections"
            ,
              title: "Punch List"
            ]
          ,
            title: "Project Closeout"
            tasks: [
              title: "Final Documentation"
            ,
              title: "Warranty & Maintenance"
            ,
              title: "Client Handover"
            ]
          ]
        ,
          title: "Pinecrest Meadows - Completed"
          events: [
            action: "setArchived"
          ]
          tasks: [
            title: "Project Planning"
            tasks: [
              title: "Scope Definition"
            ,
              title: "Timeline & Budgeting"
            ,
              title: "Permitting & Compliance"
            ]
          ,
            title: "Design & Engineering"
            tasks: [
              title: "Architectural Design"
            ,
              title: "Structural Engineering"
            ,
              title: "Mechanical, Electrical & Plumbing (MEP)"
            ]
          ,
            title: "Site Preparation"
            tasks: [
              title: "Land Surveying"
            ,
              title: "Site Clearing"
            ,
              title: "Excavation & Grading"
            ]
          ,
            title: "Construction"
            tasks: [
              title: "Framing & Structural Work"
            ,
              title: "Interior & Exterior Finishing"
            ,
              title: "Landscaping"
            ]
          ,
            title: "Inspection & Quality Control"
            tasks: [
              title: "Code Compliance"
            ,
              title: "Safety Inspections"
            ,
              title: "Punch List"
            ]
          ,
            title: "Project Closeout"
            tasks: [
              title: "Final Documentation"
            ,
              title: "Warranty & Maintenance"
            ,
              title: "Client Handover"
            ]
          ]
        ]
      ,
        title: "Finance"
        tasks: [
          title: "Secure financing for Meadowview Estates"
          expand: true
          tasks: [
            title: "Determine Loan Requirements"
          ,
            title: "Create a Financial Model"
          ,
            title: "Identify Potential Lenders"
            tasks: [
              title: "Bank A"
              tasks: [
                title: "Obtain Preliminary Approvals"
              ]
            ,
              title: "Bank B"
              tasks: [
                title: "Prepare Business Plan"
              ]
            ]
          ]
        ,
          title: "Prepare FY report"
          tasks: [
            title: "Contact auditor"
          ,
            title: "Prepare employer return"
          ]
        ]
      ,
        title: "HR"
        expand: true
        tasks: [
          title: "Recruit an on-site engineer"
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
      { "level": 0, "expand_state": "minus", "task_id": "1", "title": "Sites", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 1, "expand_state": "minus", "task_id": "83", "title": "Meadowview Estates", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 2, "expand_state": "minus", "task_id": "89", "title": "Project Planning", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 3, "task_id": "90", "title": "Scope Definition", "state_class": "done", "state_title": "Done" },
      { "level": 3, "task_id": "91", "title": "Timeline & Budgeting", "state_class": "pending", "state_title": "Pending" },
      { "level": 3, "task_id": "92", "title": "Permitting & Compliance", "state_class": "cancelled", "state_title": "Cancelled" },
      { "level": 2, "expand_state": "plus", "task_id": "93", "title": "Design & Engineering", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 2, "expand_state": "plus", "task_id": "97", "title": "Site Preparation", "state_class": "pending", "state_title": "Pending" },
      { "level": 2, "expand_state": "plus", "task_id": "101", "title": "Construction", "state_class": "done", "state_title": "Done" },
      { "level": 2, "expand_state": "plus", "task_id": "105", "title": "Inspection & Quality Control", "state_class": "done", "state_title": "Done" },
      { "level": 2, "expand_state": "plus", "task_id": "109", "title": "Project Closeout", "state_class": "in-progress", "state_title": "In progress" },
      { "level": 1, "expand_state": "plus", "task_id": "113", "title": "Willow Creek Village", "state_class": "cancelled", "state_title": "Cancelled" },
      { "level": 1, "task_id": "138", "title": "Oak Ridge Heights", "state_class": "done", "state_title": "Done", "extra_padding": "extra-padding" },
      { "level": 1, "task_id": "145", "title": "Pinecrest Meadows", "state_class": "done", "state_title": "Done", "extra_padding": "extra-padding" },
      { "level": 0, "expand_state": "minus", "task_id": "43", "title": "Pinecrest Meadows", "state_class": "pending", "state_title": "Pending" },
      { "level": 1, "expand_state": "minus", "task_id": "152", "title": "Secure financing for Meadowview Estates", "state_class": "pending", "state_title": "Pending" },
      { "level": 2, "task_id": "154", "title": "Determine Loan Requirements", "state_class": "cancelled", "state_title": "Cancelled", "extra_padding": "extra-padding" },
      { "level": 2, "task_id": "155", "title": "Create a Financial Model", "state_class": "in-progress", "state_title": "In progress", "extra_padding": "extra-padding" },
      { "level": 2, "expand_state": "plus", "task_id": "156", "title": "Identify Potential Lenders", "state_class": "pending", "state_title": "Pending" },
      { "level": 1, "expand_state": "plus", "task_id": "49", "title": "Prepare FY report", "state_class": "on-hold", "state_title": "On hold" },
      { "level": 0, "expand_state": "minus", "task_id": "45", "title": "HR", "state_class": "pending", "state_title": "Pending" },
      { "level": 1, "expand_state": "plus", "task_id": "50", "title": "Recruit an on-site engineer", "state_class": "pending", "state_title": "Pending" }
    ]
  return