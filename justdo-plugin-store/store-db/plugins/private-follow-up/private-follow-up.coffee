share.store_db.plugins.push
  id: "private-follow-up"
  title: "Private follow up"
  short_description: "Set private follow up dates to tasks"
  full_description: """
    <p>With this plugin, project members will be able to set private follow up dates to tasks. In contrary to the general follow up date that is seen by all of the task's members, this follow up date is seen only by the member who has set it. </p>

    <p>Tasks with a private follow up date will appear in your 'my due list' view when appropriate.</p>

    <p>Some of the cases in which you MIGHT want to use a private followup dates are:</p>

    <ul>
      <li>When delegating a task (transferring ownership) to a another member and you want to followup on that task, but you are afraid to forget about it altogether.</li>
      <li>For tasks that you want to keep an eye on and check their progress frequently.</li>
      <li>For tasks that you want to follow up on, yet want to avoid sharing this date with other members of the task.</li>
    </ul>
  """
  categories: ["featured", "misc", "management"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/private-follow-up/media/store-list-icon.jpeg"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.com"

  package_name: "justdoinc:justdo-private-follow-up"
  package_project_custom_feature_id: "justdo_private_follow_up"
  isPluginEnabledForEnvironment: -> true

  slider: [
  ]
