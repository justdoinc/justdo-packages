share.store_db.plugins.push
  id: "maildo"
  title: "plugin_store_maildo_title"
  metadata:
    title: "plugin_store_maildo_meta_title"
    description: "plugin_store_maildo_meta_description"
  short_description: "plugin_store_maildo_short_description"
  full_description: ["plugin_store_maildo_full_description"]
  categories: [JustdoPluginStore.default_category, "misc", "management", "power-tools"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/maildo/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "plugin_store_default_plugin_developer_name"
  developer_url: "https://justdo.com"

  package_name: "justdoinc:justdo-inbound-emails"
  package_project_custom_feature_id: "justdo_inbound_emails"
  isPluginEnabledForEnvironment: -> env.INBOUND_EMAILS_ENABLED is "true"

  slider: [
    {asset_type: "image", asset_url: "/layout/images/pricing/mail_do.jpg", asset_title: "plugin_store_maildo_asset_maildo_title", asset_subtitle: "plugin_store_maildo_asset_maildo_subtitle"}
  ]