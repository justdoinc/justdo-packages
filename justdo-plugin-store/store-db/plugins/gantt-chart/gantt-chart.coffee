share.store_db.plugins.push
  id: "gantt-chart"
  title: "plugin_store_gantt_chart_title"
  metadata:
    title: "plugin_store_gantt_chart_meta_title"
    description: "plugin_store_gantt_chart_meta_description"
  short_description: "plugin_store_gantt_chart_short_description"
  full_description: ["plugin_store_gantt_chart_full_description"]
  categories: [JustdoPluginStore.default_category, "misc", "management"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/gantt-chart/media/store-list-icon.png"
  price: "Free"
  version: "1.0"
  developer: "plugin_store_default_plugin_developer_name"
  developer_url: "https://justdo.com"

  package_name: "justdoinc:justdo-planning-utilities"
  package_project_custom_feature_id: "justdo_planning_utilities"
  isPluginEnabledForEnvironment: -> true

  slider: [
    { asset_type: "image", asset_url: "/layout/images/pricing/gantt.jpg", asset_title: "plugin_store_gantt_chart_asset_gantt_chart_title", asset_subtitle: "plugin_store_gantt_chart_asset_gantt_chart_subtitle"},
    { asset_type: "image", asset_url: "/layout/images/pricing/milestones.jpg", asset_title: "plugin_store_gantt_chart_asset_milestones_title", asset_subtitle: "plugin_store_gantt_chart_asset_milestones_subtitle"},
    { asset_type: "image", asset_url: "/layout/images/pricing/key_tasks.jpg", asset_title: "plugin_store_gantt_chart_asset_key_tasks_title", asset_subtitle: "plugin_store_gantt_chart_asset_key_tasks_subtitle"},
    { asset_type: "image", asset_url: "/layout/images/pricing/baselines.jpg", asset_title: "plugin_store_gantt_chart_asset_baselines_title", asset_subtitle: "plugin_store_gantt_chart_asset_baselines_subtitle"},
    { asset_type: "image", asset_url: "/layout/images/pricing/slack_time.jpg", asset_title: "plugin_store_gantt_chart_asset_slack_time_title", asset_subtitle: "plugin_store_gantt_chart_asset_slack_time_subtitle"},
    { asset_type: "image", asset_url: "/layout/images/pricing/buffers.jpg", asset_title: "plugin_store_gantt_chart_asset_buffers_title", asset_subtitle: "plugin_store_gantt_chart_asset_buffers_subtitle"}
  ]
