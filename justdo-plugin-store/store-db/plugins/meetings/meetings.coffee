share.store_db.plugins.push
  id: "meetings"
  title: "plugin_store_meetings_title"
  metadata:
    title: "plugin_store_meetings_meta_title"
    description: "plugin_store_meetings_meta_description"
  short_description: "plugin_store_meetings_short_description"
  full_description: ["plugin_store_meetings_full_description"]
  categories: [JustdoPluginStore.default_category, "justdo-labs"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/meetings/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "plugin_store_default_plugin_developer_name"
  developer_url: "https://justdo.com"

  package_name: "justdoinc:meetings-manager"
  package_project_custom_feature_id: "meetings_module"
  isPluginEnabledForEnvironment: -> true

  slider: [
    {asset_type: "image", asset_url: "/layout/images/pricing/meetigns.jpg", asset_title: "plugin_store_meetings_asset_meetings_title", asset_subtitle: "plugin_store_meetings_asset_meetings_subtitle"}
  ]