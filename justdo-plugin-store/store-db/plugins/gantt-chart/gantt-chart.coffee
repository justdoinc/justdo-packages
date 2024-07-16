share.store_db.plugins.push
  id: "gantt-chart"
  title: "plugin_store_gantt_chart_title"
  short_description: "plugin_store_gantt_chart_short_description"
  full_description: "plugin_store_gantt_chart_full_description"
  categories: ["featured", "misc", "management"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/gantt-chart/media/delivery-planner-icon.png"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.com"

  package_name: "justdoinc:justdo-planning-utilities"
  package_project_custom_feature_id: "justdo_planning_utilities"
  isPluginEnabledForEnvironment: -> true

  slider: [
    { asset_type: "image", asset_url: "/layout/images/pricing/gantt.jpg"},
    { asset_type: "image", asset_url: "/layout/images/pricing/milestones.jpg"},
    { asset_type: "image", asset_url: "/layout/images/pricing/key_tasks.jpg"},
    { asset_type: "image", asset_url: "/layout/images/pricing/baselines.jpg"},
    { asset_type: "image", asset_url: "/layout/images/pricing/slack_time.jpg"}
  ]
