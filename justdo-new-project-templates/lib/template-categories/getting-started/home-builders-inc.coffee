APP.justdo_projects_templates?.registerTemplate
  id: "home-builders-inc"
  label: "Home Builders Inc"
  order: 102
  demo_img_src: "/packages/justdoinc_justdo-new-project-templates/lib/template-categories/getting-started/home-builders-inc.png"
  categories: ["getting-started"]
  template:
    users: ["performing_user"]
    tasks: [
      title: "Sites"
      tasks: [
        title: "Meadowview Estates"
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
