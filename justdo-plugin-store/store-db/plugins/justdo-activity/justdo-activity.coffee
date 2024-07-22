share.store_db.plugins.push
  id: "justdo-activity"
  title: "plugin_store_activity_log_title"
  short_description: "plugin_store_activity_log_short_description"
  full_description: ["plugin_store_activity_log_full_description"]
  categories: [JustdoPluginStore.default_category, "misc", "management"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/justdo-activity/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "plugin_store_default_plugin_developer_name"
  developer_url: "https://justdo.com"

  package_name: "justdoinc:justdo-global-activity-log"
  package_project_custom_feature_id: "justdo_global_activity_log"
  isPluginEnabledForEnvironment: -> true

  slider: [
    {asset_type: "image", asset_url: "/layout/images/pricing/activity_log.jpg"}
  ]