share.store_db.plugins.push
  id: "justdo-activity"
  title: "JustDo Activity"
  short_description: "Real time updates about members activities"
  full_description: """
    Enable this plugin to see in real time what people are doing within JustDo. You will be able to choose between monitoring all updates to JustDo or filter for status changes only. Use this plugin to stay on top of things on a day by day basis, or catch up and see what has been done after being away from the system. Think of it as a systems monitoring tool, but for our human colleagues rather than systems and servers.
  """
  categories: ["featured", "misc", "management"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/justdo-activity/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.today"

  package_name: "justdoinc:justdo-global-activity-log"
  package_project_custom_feature_id: "justdo_global_activity_log"
  isPluginEnabledForEnvironment: -> true

  slider: []