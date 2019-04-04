share.store_db.plugins.push
  id: "calculated-due-dates"
  title: "Calculated Due Dates"
  short_description: "Create auto-updating dependencies for due dates"
  full_description: """
    The Calculated Due Dates plugin allows you to associate and set dependencies of different tasks’ due-dates. With this plugin you will be able to automatically set a due date of a certain task:<br><br>
    <ul>
      <li>As the highest due date of its direct child-tasks.</li>
      <li>As the highest due date of all of its child-tasks.</li>
      <li>As the highest of specific list of other tasks.</li>
      <li>As an offset from some other task (e.g. Task #7 Due date is 3 days after Task #6 due date).</li>
    </ul><br>
    Hence with a task with multiple child tasks, and stages of work, you could set the calculated due date based upon the highest due date of all the parent’s task’s, child tasks. This in turn would mean that if one task is running behind, the parent’s task due date would automatically be updated to reflect this new reality.
  """
  categories: ["justdo-labs"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/calculated-due-dates/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.com"

  package_name: "justdoinc:justdo-backend-calculated-fields"
  package_project_custom_feature_id: "backend-calculated-fields"
  isPluginEnabledForEnvironment: -> true

  slider: []