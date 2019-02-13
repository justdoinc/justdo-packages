share.store_db.plugins.push
  id: "justdo-time-tracker"
  title: "JustDo Time Tracker"
  short_description: "Track time spent on tasks"
  full_description: """
<p>This plugin introduces a time-tracking capabilities into JustDo.</p>

<p>The way it works:</p>
<ul>
	<li>Once enabled, a user can start tracking the time spent on each task with a single click.</li>
	<li>The information collected can be used to generate billing reports, conduct performance analysis, etc.</li>
	<li>Time spent is recorded on the task level, and reported up the tasks' tree within the Resource Management plugin.</li>
	<li>Integrated with the Projects plugin, time reported is now part of the calculated delivery dates and risk calculations.</li>
</ul>
<p>Studies show that time tracking increases teams' productivity by 15%-20%. Turn on JustDo's time tracking and increase your productivity now.</p>
  """
  categories: ["featured", "misc", "management", "power-tools"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/justdo-time-tracker/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.today"

  package_name: "justdoinc:justdo-time-tracker"
  package_project_custom_feature_id: "justdo_time_tracker"
  isPluginEnabledForEnvironment: -> true

  slider: [
  ]
