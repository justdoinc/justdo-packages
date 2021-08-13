share.store_db.plugins.push
  id: "justdo-checklist"
  title: "Checklists"
  short_description: "Add a checklist functionality and statistics to tasks"
  full_description: """
    Checklists is the ultimate solution for complicated and nested checklists management.<br>
    When this plugin is installed, you can turn any subtree into a checklist. Information about
    'checked' tasks is collected up the tree hierarchy, and provides a real-time view about how
    many of the tasks have been checked.
  """
  categories: ["featured", "misc"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/justdo-checklist/media/checklist-icon.jpg"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.com"

  package_name: "justdoinc:custom-justdo-cumulative-select"
  package_project_custom_feature_id: "justdo_checklist_fields"
  isPluginEnabledForEnvironment: -> true

  slider: []

share.store_db.plugins.push
  id: "justdo-checklist-obsolete"
  title: "JustDo Tree Checklist"
  short_description: "Adds checklist functionality to the Subject field"
  full_description: """
    Checklists is the ultimate solution for complicated and nested checklists management.<br>
    When this plugin is installed, you can turn any subtree into a checklist. Information about
    'checked' tasks is collected up the tree hierarchy, and provides a real-time view about how
    many of the tasks have been checked.
  """
  categories: ["justdo-labs"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/justdo-checklist/media/checklist-icon.jpg"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.com"

  package_name: "justdoinc:justdo-checklist"
  package_project_custom_feature_id: "justdo_checklist"
  isPluginEnabledForEnvironment: -> true

  slider: []