share.store_db.plugins.push
  id: "maildo"
  title: "plugin_store_maildo_title"
  short_description: "plugin_store_maildo_short_description"
  full_description: "plugin_store_maildo_full_description"
  categories: ["featured", "misc", "management", "power-tools"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/maildo/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.com"

  package_name: "justdoinc:justdo-inbound-emails"
  package_project_custom_feature_id: "justdo_inbound_emails"
  isPluginEnabledForEnvironment: -> env.INBOUND_EMAILS_ENABLED is "true"

  slider: []