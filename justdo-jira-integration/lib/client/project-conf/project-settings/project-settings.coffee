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

  @hardcoded_field_map = JustdoJiraIntegration.hardcoded_field_map
  @hardcoded_justdo_field_ids = new Set _.map @hardcoded_fields, (field_obj) -> field_obj.justdo_field_id
  @hardcoded_jira_field_ids = new Set _.map @hardcoded_fields, (field_obj) -> field_obj.jira_field_id

  @selected_jira_project_id_rv = new ReactiveVar ""
  @jira_field_def_obj_rv = new ReactiveVar {}
  @autorun =>
    if not _.isNumber(selected_jira_project_id = @selected_jira_project_id_rv.get())
      return
    APP.justdo_jira_integration.getJiraFieldDefByJiraProjectId selected_jira_project_id, (err, field_def) =>
      if err?
        console.error err
        return

      jira_field_def_obj = {}
      for field_id, field of field_def
        jira_field_def_obj[field_id] = field

      @jira_field_def_obj_rv.set jira_field_def_obj
    return

Template.justdo_jira_integration_project_setting.helpers
  oAuthLoginLink: -> Template.instance().oAuth_login_link_rv.get()

  serverInfo: ->
    return APP.justdo_jira_integration.getJiraServerInfoFromJustdoId JD.activeJustdoId()

  hardcodedFieldsMap: ->
    return Template.instance().hardcoded_field_map

  selectedJiraProjectId: -> Template.instance().selected_jira_project_id_rv.get()

  mountedJiraProjectsUnderActiveJustdo: ->
    query =
      project_id: JD.activeJustdoId()
      jira_mountpoint_type: "root"
      jira_project_id:
        $ne: null

    return APP.collections.Tasks.find(query, {fields: {jira_project_id: 1}}).map (task_doc) ->
      jira_project_id = task_doc.jira_project_id
      jira_project_key = APP.justdo_jira_integration.getJiraProjectKeyById jira_project_id
      return {jira_project_id, jira_project_key}

  customFieldsMap: ->
    return APP.justdo_jira_integration.getCustomFieldMapByJiraProjectId Template.instance().selected_jira_project_id_rv.get()

  templateDataForChildTemplate: ->
    {hardcoded_justdo_field_ids, hardcoded_jira_field_ids, jira_field_def_obj_rv} = Template.instance()
    return {hardcoded_justdo_field_ids, hardcoded_jira_field_ids, jira_field_def_obj_rv, selected_justdo_field: @justdo_field_id, selected_jira_field: @jira_field_id}

Template.justdo_jira_integration_project_setting.events
  "click .jira-login-link": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    target_link = $(e.target).closest(".jira-login-link").attr "href"
    window.open target_link, "_blank"
    return

  "click .configure-jira-project-field-mapping": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    jira_project_id = $(e.target).closest(".configure-jira-project-field-mapping").data "id"
    tpl.selected_jira_project_id_rv.set jira_project_id
    return

  "click .set-custom-field-pair": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    jira_doc_id = APP.justdo_jira_integration.getActiveJustdoJiraDocId()
    field_pairs = []

    # Transform the array into [[justdo_field_id, jira_field_id], [justdo_field_id, jira_field_id], ....]
    field_pairs_array = _.chunk _.map($(".custom-jira-field-pair select"), (select) -> $(select).val()), 2

    for field_pair, i in field_pairs_array
      # If either one isn't selected, ignore the pair.
      if not _.isString(field_pair[0]) or not _.isString(field_pair[1])
        continue

      [justdo_field_id, justdo_field_type] = field_pair[0].split "::"
      [jira_field_id, jira_field_type] = field_pair[1].split "::"

      # String field can hold numbers and date as well. Might just allow it.
      if (justdo_field_type isnt "string") and (jira_field_type isnt "string") and  (justdo_field_type isnt jira_field_type)
        JustdoSnackbar.show
          text: "Field type mismatch at row #{i+1}"
        return

      field_pairs.push {justdo_field_id, jira_field_id, id: Random.id()}

    APP.justdo_jira_integration.mapJustdoAndJiraFields jira_doc_id, tpl.selected_jira_project_id_rv.get(), field_pairs
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
      field_type = APP.justdo_jira_integration.translateJustdoFieldTypeToMappedFieldType field_def

      if not field_type? or (field_def.client_only) or (field_def.grid_column_substitue_field?) or (not field_def.grid_visible_column) or (not field_def.grid_editable_column) or (tpl.hardcoded_justdo_field_ids.has field_id)
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

      ret.justdo_fields.push {field_id: field_id, field_name: field_def.label, field_type: field_type, selected: selected}

    # Append Jira fields
    for field_id, field_def of Template.instance().jira_field_def_obj_rv.get()
      field_type = field_def.schema?.type

      if (field_def.name.includes "jd_") or (field_type not in ["number", "string", "date", "datetime"]) or (tpl.hardcoded_jira_field_ids.has field_id)
        continue

      if field_type is "datetime"
        field_type = "date"

      selected = false
      if field_id is tpl.selected_jira_field
        selected = true

      ret.jira_fields.push {field_id: field_id, field_name: field_def.name, field_type: field_type, selected: selected}

    ret.justdo_fields = JustdoHelpers.localeAwareSortCaseInsensitive ret.justdo_fields, (field) -> field.field_name
    ret.jira_fields = JustdoHelpers.localeAwareSortCaseInsensitive ret.jira_fields, (field) -> field.field_name

    return ret

  ucFirst: (string) -> JustdoHelpers.ucFirst string
