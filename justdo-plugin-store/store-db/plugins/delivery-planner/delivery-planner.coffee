share.store_db.plugins.push
  id: "delivery-planner"
  title: "Resource Progress Tracking"
  short_description: "Calculate delivery dates based on resources availability"
  full_description: """
    <p>The Resource Progress Tracking plugin lets you associate one or more sets of tasks into a project. Then, based on the resources needed to accomplish it and their availability, project the delivery date.</p>

    <p>With this plugin you will be able to:</p>

    <ul>
      <li>Group together tasks into a single Project</li>
      <li>Set users availability (workdays, vacation days, working hours per day, etc.) to each of the resources associated with the project</li>
      <li>Based on the amount of resources needed to accomplish this Project create a burn-down projection chart</li>
      <li>Capture a baseline projection for future reference</li>
      <li>Compare actual progress within the project to the baseline plan and see if you are on-schedule for delivery on time</li>
    </ul>

    <p><u>Plugin dependencies:</u></p>

    <ul>
      <li>Resource Management by JustDo</li>
    </ul>
  """
  categories: ["featured", "misc", "management"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/delivery-planner/media/delivery-planner-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.com"

  package_name: "justdoinc:justdo-delivery-planner"
  package_project_custom_feature_id: "justdo_delivery_planner"
  isPluginEnabledForEnvironment: -> true

  slider: [
    """
      <img src="/packages/justdoinc_justdo-plugin-store/store-db/plugins/delivery-planner/media/delivery-planner-screenshot.png" style="margin: 0 auto;" />
    """
  ]
