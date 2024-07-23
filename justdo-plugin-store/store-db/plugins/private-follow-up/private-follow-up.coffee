share.store_db.plugins.push
  id: "private-follow-up"
  title: "plugin_store_private_followup_title"
  metadata:
    title: "plugin_store_private_followup_meta_title"
    description: "plugin_store_private_followup_meta_description"
  short_description: "plugin_store_private_followup_short_description"
  full_description: ["plugin_store_private_followup_full_description"]
  categories: [JustdoPluginStore.default_category, "misc", "management"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/private-follow-up/media/store-list-icon.jpeg"
  price: "Free"
  version: "1.0"
  developer: "plugin_store_default_plugin_developer_name"
  developer_url: "https://justdo.com"

  package_name: "justdoinc:justdo-private-follow-up"
  package_project_custom_feature_id: "justdo_private_follow_up"
  isPluginEnabledForEnvironment: -> true

  slider: [
    {asset_type: "image", asset_url: "/layout/images/pricing/due_list.jpg", asset_title: "plugin_store_private_followup_asset_private_followup_title", asset_subtitle: "plugin_store_private_followup_asset_private_followup_subtitle"}
  ]
