share.getDateOffsetByDays = (offset_by_days) ->
  return moment(JustdoHelpers.getDateMsOffset offset_by_days * 24 * 60 * 60 * 1000).format "YYYY-MM-DD"

APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return
  
  APP.justdo_projects_templates?.registerCategory
    id: "getting-started"
    label_i18n: "project_templates_getting_started_label"
    order: 0

  return