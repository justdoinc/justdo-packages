share.store_db.plugins.push
  id: "justdo-time-tracker"
  title: "plugin_store_time_tracker_title"
  metadata:
    title: "plugin_store_time_tracker_meta_title"
    description: "plugin_store_time_tracker_meta_description"
  short_description: "plugin_store_time_tracker_short_description"
  full_description: ["plugin_store_time_tracker_full_description"]
  categories: [JustdoPluginStore.default_category, "misc", "management", "power-tools"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/justdo-time-tracker/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "plugin_store_default_plugin_developer_name"
  developer_url: "https://justdo.com"

  package_name: "justdoinc:justdo-time-tracker"
  package_project_custom_feature_id: "justdo_time_tracker"
  isPluginEnabledForEnvironment: -> true

  slider: [
    {asset_type: "image", asset_url: "/layout/images/pricing/time_tracker.jpg", asset_title: "plugin_store_time_tracker_asset_time_tracker_title", asset_subtitle: "plugin_store_time_tracker_asset_time_tracker_subtitle"}
  ]
