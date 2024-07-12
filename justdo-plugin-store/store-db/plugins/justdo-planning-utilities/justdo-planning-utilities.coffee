share.store_db.plugins.push
  id: "justdo-planning-utilities"
  title: "Gantt Chart Project Planner"
  short_description: "Visualize and manage project timelines with interactive Gantt charts."
  full_description: """
    <p>The Gantt chart is a powerful project management tool in JustDo that visually represents your project timeline, dependencies, and progress.  It empowers project managers to efficiently plan, coordinate, and track projects, ensuring on-time delivery.</p>

    <p>Key Features of JustDo's Gantt Chart:</p>

    <ul>
      <li><b>Interactive Timeline:</b> Visualize tasks, milestones, and dependencies with draggable start and end dates.</li>
      <li><b>Milestone Tracking:</b> Mark significant events and deadlines for clear project checkpoints.</li>
      <li><b>Dependency Management:</b> Establish relationships between tasks with multiple dependency types (FS, SF, FF, SS) to accurately model your workflow.</li>
      <li><b>Baseline Comparisons:</b> Save project schedule snapshots and compare them to track deviations and maintain control. </li>
      <li><b>Slack Time Visualization:</b> Identify task flexibility and potential schedule buffers for proactive risk management.</li>
      <li><b>Key Task Highlighting:</b>  Focus on critical tasks essential for project success.</li>
      <li><b>Cross-Project Dependency Management:</b> Coordinate tasks across multiple projects for a holistic view of your workload. </li>
    </ul>

    <p>Benefits:</p>

    <ul>
      <li>Improved project planning and scheduling accuracy.</li>
      <li>Enhanced resource allocation and utilization.</li>
      <li>Real-time progress monitoring and risk identification.</li>
      <li>Increased team collaboration and communication.</li>
      <li>Successful project delivery within time and budget constraints.</li>
    </ul> 
  """
  categories: ["featured", "misc", "management"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/justdo-planning-utilities/media/delivery-planner-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.com"

  package_name: "justdoinc:justdo-planning-utilities"
  package_project_custom_feature_id: "justdo_planning_utilities"
  isPluginEnabledForEnvironment: -> true

  slider: [
    """<img src="/layout/images/pricing/gantt.jpg" style="margin: 0 auto;" class="d-block w-100" />""",
    """<img src="/layout/images/pricing/milestones.jpg" style="margin: 0 auto;" class="d-block w-100" />""",
    """<img src="/layout/images/pricing/key_tasks.jpg" style="margin: 0 auto;" class="d-block w-100" />""",
    """<img src="/layout/images/pricing/baselines.jpg" style="margin: 0 auto;" class="d-block w-100" />""",
    """<img src="/layout/images/pricing/slack_time.jpg" style="margin: 0 auto;" class="d-block w-100" />""",

  ]
