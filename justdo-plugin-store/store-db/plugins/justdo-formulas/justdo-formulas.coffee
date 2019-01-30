share.store_db.plugins.push
  id: "justdo-formulas"
  title: "JustDo Formulas"
  short_description: "Calculated custom fields"
  full_description: """
    <p>With JustDo Formulas you can set Custom Fields that will be calculated according to other task fields.</p>

    <p>For example, if you have a column named: Budget in which you set the budget given for a task, and a field called Execution in which you maintain the amount already executed out of the budget, with this plugin, you can set a new field that will maintain: {Execution} / {Budget}.</p>

    <p>To get started, install this plugin, go to the JustDo configuration view, and add a new Custom Field of type: Formula.</p>
  """
  categories: ["featured", "misc", "management", "power-tools"]
  image_url: "/packages/justdoinc_justdo-plugin-store/store-db/plugins/justdo-formulas/media/store-list-icon.jpeg"
  price: "Free"
  version: "1.0"
  developer: "JustDo, Inc."
  developer_url: "justdo.today"

  package_name: "justdoinc:justdo-formula-fields"
  package_project_custom_feature_id: "justdo_formula_fields"
  isPluginEnabledForEnvironment: -> true

  slider: [
  ]
