Template.justdo_jira_integration_project_setting.onCreated ->
  @oAuth_login_link_rv = new ReactiveVar ""
  if APP.justdo_jira_integration.getAuthTypeIfJiraInstanceIsOnPerm() is "oauth1"
    link_getter = "getOAuth1LoginLink"
  else
    link_getter = "getOAuth2LoginLink"
  APP.justdo_jira_integration[link_getter] JD.activeJustdoId(), (err, link) =>
    if err?
      console.error err
      return
    @oAuth_login_link_rv.set link
    return

  @justdo_field_ids_to_exclude = new Set()
  @jira_field_ids_to_exclude = new Set()
  @hardcoded_field_map_rv = new ReactiveVar []
  @jira_field_def_obj = new ReactiveVar {}
  if (active_jira_doc_id = APP.collections.Projects.findOne(JD.activeJustdoId(), {fields: {"conf.justdo_jira:id": 1}})?.conf?["justdo_jira:id"])?
    # Assuming we have grid control ready if we get activeJustdoId()
    grid_control = APP.modules.project_page.gridControl()

    # First get Jira field def, so we could translate field id to readable name
    APP.justdo_jira_integration.getJiraFieldDef active_jira_doc_id, (err, field_def) =>
      if err?
        console.error err
        return

      jira_field_def_obj = {}
      for field in field_def
        jira_field_def_obj[field.id] = field

      APP.justdo_jira_integration.getHardcodedJustdoFieldToJiraFieldMap (err, field_map) =>
        if err?
          console.error err
          return

        # Translate field id to readable name
        for field_pair in field_map
          {justdo_field, jira_field} = field_pair

          @justdo_field_ids_to_exclude.add justdo_field
          @jira_field_ids_to_exclude.add jira_field

          field_pair.justdo_field = grid_control.getFieldDef(justdo_field).label
          field_pair.jira_field = jira_field_def_obj[jira_field].name

        @hardcoded_field_map_rv.set field_map
        # jira_field_def_obj is set inside this scope so that justdo_field_ids_to_exclude and jira_field_ids_to_exclude is up to date
        # by the time fieldsAvaibleForUserMapping() is re-ran.
        @jira_field_def_obj.set jira_field_def_obj
        return

      return

Template.justdo_jira_integration_project_setting.helpers
  oAuthLoginLink: -> Template.instance().oAuth_login_link_rv.get()

  serverInfo: ->
    return APP.justdo_jira_integration.getJiraServerInfoFromJustdoId JD.activeJustdoId()

  hardcodedFieldsMap: ->
    return Template.instance().hardcoded_field_map_rv.get()

  customFieldsMap: ->
    return APP.justdo_jira_integration.getCustomFieldMapByJiraProjectId 10001

  templateDataForChildTemplate: ->
    {justdo_field_ids_to_exclude, jira_field_ids_to_exclude, hardcoded_field_map_rv, jira_field_def_obj} = Template.instance()
    return {justdo_field_ids_to_exclude, jira_field_ids_to_exclude, hardcoded_field_map_rv, jira_field_def_obj, selected_justdo_field: @justdo_field_id, selected_jira_field: @jira_field_id}

Template.justdo_jira_integration_project_setting.events
  "click .jira-login-link": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    target_link = $(e.target).closest(".jira-login-link").attr "href"
    window.open target_link, "_blank"
    return

Template.justdo_jira_integration_field_map_option_pair.onCreated ->
  _.extend @, @data
  @selected_field_type = new ReactiveVar ""
  return

Template.justdo_jira_integration_field_map_option_pair.helpers
  fieldsAvaibleForUserMapping: ->
    tpl = Template.instance()
    grid_control = APP.modules.project_page.gridControl()
    ret =
      justdo_fields: []
      jira_fields: []

    # Append JustDo fields
    for field_id, field_def of grid_control.getSchemaExtendedWithCustomFields()
      field_type = field_def.type

      if (field_def.client_only) or (field_def.grid_column_substitue_field?) or (not field_def.grid_visible_column) or (not field_def.grid_editable_column) or (field_type in [Object, Date]) or (tpl.justdo_field_ids_to_exclude.has field_id)
        continue

      selected = false
      if field_id is tpl.selected_justdo_field
        selected = true

      if field_type is String and field_def.grid_column_editor is "UnicodeDateEditor"
        field_type = "date"
      if field_type is String
        field_type = "string"
      if field_type is Number
        field_type = "number"

      # if not (_.isEmpty(selected_field_type = tpl.selected_field_type.get())) and (field_type isnt selected_field_type)
      #   continue

      ret.justdo_fields.push {field_id: field_id, field_name: field_def.label, field_type: field_type, selected: selected}

    # Append Jira fields
    for field_id, field_def of Template.instance().jira_field_def_obj.get()
      field_type = field_def.schema?.type

      if (field_def.name.includes "jd_") or (field_type not in ["number", "string", "date", "datetime"]) or (tpl.jira_field_ids_to_exclude.has field_id)
        continue

      if field_type is "datetime"
        field_type = "date"

      selected = false
      if field_id is tpl.selected_jira_field
        selected = true

      ret.jira_fields.push {field_id: field_id, field_name: field_def.name, field_type: field_type, selected: selected}

    return ret
