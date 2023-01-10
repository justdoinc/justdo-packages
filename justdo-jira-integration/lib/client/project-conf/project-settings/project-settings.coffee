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
  @hardcoded_justdo_field_ids = new Set _.map @hardcoded_field_map, (field_obj) -> field_obj.justdo_field_id
  @hardcoded_jira_field_ids = new Set _.map @hardcoded_field_map, (field_obj) -> field_obj.jira_field_id

  @selected_jira_project_id_rv = new ReactiveVar ""
  @active_custom_field_map_rv = new ReactiveVar []
  @autorun =>
    if not _.isNumber (selected_jira_project_id = @selected_jira_project_id_rv.get())
      @active_custom_field_map_rv.set []

    jira_doc_id = APP.justdo_jira_integration.getJiraDocIdFromJustdoId JD.activeJustdoId()
    @active_custom_field_map_rv.set APP.justdo_jira_integration.getCustomFieldMapByJiraProjectId jira_doc_id, Template.instance().selected_jira_project_id_rv.get()
    return

  @jira_field_def_obj_rv = new ReactiveVar {}
  @autorun =>
    if not _.isNumber(selected_jira_project_id = @selected_jira_project_id_rv.get())
      return
    @jira_field_def_obj_rv.set {}
    jira_doc_id = APP.justdo_jira_integration.getJiraDocIdFromJustdoId JD.activeJustdoId()

    APP.justdo_jira_integration.getJiraFieldDefByJiraProjectId jira_doc_id, selected_jira_project_id, (err, field_def) =>
      if err?
        console.error err
        return

      jira_field_def_obj = {}
      for field_id, field of field_def
        jira_field_def_obj[field_id] = field

      @jira_field_def_obj_rv.set jira_field_def_obj
    return

  @templateDataForChildTemplate = ->
    ret =
      hardcoded_justdo_field_ids: @hardcoded_justdo_field_ids
      hardcoded_jira_field_ids: @hardcoded_jira_field_ids
      jira_field_def_obj_rv: @jira_field_def_obj_rv
      selected_jira_project_id_rv: @selected_jira_project_id_rv
      active_custom_field_map_rv: @active_custom_field_map_rv
    return ret

Template.justdo_jira_integration_project_setting.onRendered ->
  tpl = @

  $(".jira-field-map-project-select")
    .selectpicker
      dropupAuto: true,
      liveSearch: true,
      size: 6,
      width: "100%"
    .on "changed.bs.select", (e) ->
      selected_jira_project_id = $(e.target).closest(".jira-field-map-project-select").val()
      tpl.selected_jira_project_id_rv.set parseInt selected_jira_project_id

    .on "show.bs.select", (e) ->
      setTimeout ->
        $(e.target).focus()
      , 0

  $(".jira-field-map-project-select .filter-option-inner-inner")
    .removeClass("text-body")
    .addClass("text-primary")

  return

Template.justdo_jira_integration_project_setting.helpers
  oAuthLoginLink: -> Template.instance().oAuth_login_link_rv.get()

  serverInfo: ->
    return APP.justdo_jira_integration.getJiraServerInfoFromJustdoId JD.activeJustdoId()

  hardcodedFieldsMap: ->
    return Template.instance().hardcoded_field_map

  selectedJiraProjectId: -> Template.instance().selected_jira_project_id_rv.get()

  mountedJiraProjectsUnderActiveJustdo: ->
    jira_doc_id = APP.justdo_jira_integration.getJiraDocIdFromJustdoId JD.activeJustdoId()

    query =
      project_id: JD.activeJustdoId()
      jira_mountpoint_type: "root"
      jira_project_id:
        $ne: null

    return APP.collections.Tasks.find(query, {fields: {jira_project_id: 1}}).map (task_doc) ->
      jira_project_id = task_doc.jira_project_id
      jira_project_key = APP.justdo_jira_integration.getJiraProjectKeyById jira_doc_id, jira_project_id
      return {jira_project_id, jira_project_key}

  customFieldsMap: -> Template.instance().active_custom_field_map_rv.get()

  templateDataForChildTemplate: ->
    ret = _.extend Template.instance().templateDataForChildTemplate(),
      selected_justdo_field: @justdo_field_id
      selected_jira_field: @jira_field_id
      field_pair_id: @id

    return ret

  projectSelected: ->
    return Template.instance().selected_jira_project_id_rv.get()

Template.justdo_jira_integration_project_setting.events
  "click .jira-login-link": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    target_link = $(e.target).closest(".jira-login-link").attr "href"
    window.open target_link, "_blank"
    return

  "click .set-custom-field-pair": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    jira_doc_id = APP.justdo_jira_integration.getActiveJustdoJiraDocId()
    field_pairs = []

    field_pairs_array = []

    for field_pair in $(".custom-jira-field-pair").not("[data-field_pair_id]")
      [$justdo_field, $jira_field] = $(field_pair).find("select option:selected")
      if _.isEmpty($justdo_field) or _.isEmpty($jira_field)
        continue

      $justdo_field = $($justdo_field)
      $jira_field = $($jira_field)

      if $justdo_field.val() is "empty" or $jira_field.val() is "empty"
        continue

      ret =
        justdo_field_id: $justdo_field.val()
        justdo_field_type: $justdo_field.data "field_type"
        jira_field_id: $jira_field.val()
        jira_field_type: $jira_field.data "field_type"
      field_pairs_array.push ret

    for field_pair, i in field_pairs_array
      {justdo_field_id, justdo_field_type, jira_field_id, jira_field_type} = field_pair

      # String field can hold numbers and date as well. Might just allow it.
      # Checking for option fields aren't implemented here,
      # as the client doesn't allow choosing other fields when Jira option field is selected.
      # Also the server-side logic will handle the option field differently than other fields.
      if (justdo_field_type isnt "string") and (jira_field_type isnt "string") and (justdo_field_type isnt jira_field_type)
        JustdoSnackbar.show
          text: "Field type mismatch at row #{i+1}"
        return

      field_pairs.push {justdo_field_id, jira_field_id, id: Random.id()}

    try
      APP.justdo_jira_integration.checkCustomFieldPairMapping jira_doc_id, tpl.selected_jira_project_id_rv.get(), field_pairs
    catch e
      JustdoSnackbar.show
        text: e.reason

    APP.justdo_jira_integration.addCustomFieldPairs JD.activeJustdoId(), tpl.selected_jira_project_id_rv.get(), field_pairs
    return

  "click .jira-field-map-add-row": (e, tpl) ->
    node_to_render = $(".jira-field-map-rows-wrapper")[0]
    Blaze.renderWithData Template.justdo_jira_integration_field_map_option_pair, tpl.templateDataForChildTemplate(), node_to_render
    return

Template.justdo_jira_integration_field_map_option_pair.onCreated ->
  _.extend @, @data
  @selected_field_type = new ReactiveVar ""
  @chosen_special_field_type = new ReactiveVar ""
  @is_select_picker_initialized = false

  @initSelectPicker = ->
    $(".pair-field-select")
      .selectpicker
        container: ".jira-field-map-container"
        dropupAuto: true,
        liveSearch: true,
        size: 6,
        width: "100%"
      .on "changed.bs.select", (e) ->
        # Autosave changes

      .on "show.bs.select", (e) ->
        setTimeout ->
          $(e.target).focus()
        , 0
    @is_select_picker_initialized = true
    return
  @refreshSelectPicker = ->
    if @is_select_picker_initialized
      Meteor.defer => $(".pair-field-select").selectpicker "refresh"
    return

  return

Template.justdo_jira_integration_field_map_option_pair.onRendered ->
  @initSelectPicker()
  return

Template.justdo_jira_integration_field_map_option_pair.helpers
  isFieldPairIdExist: ->
    tpl = Template.instance()

    if tpl.field_pair_id?
      return "disabled"
    return

  getSelectedJustdoFieldDef: ->
    tpl = Template.instance()
    grid_control = APP.modules.project_page.gridControl()

    ret =
      field_id: tpl.selected_justdo_field_id

    if (field_def = grid_control.getFieldDef(tpl.selected_justdo_field_id))?
      ret.field_name = field_def.label
      return ret

    ret.field_name = "[Removed Field]"
    return ret

  getSelectedJiraFieldDef: ->
    tpl = Template.instance()

    ret =
      field_id: tpl.selected_jira_field_id

    if (field_def = Template.instance().jira_field_def_obj_rv.get()?[tpl.selected_jira_field_id])?
      ret.field_name = field_def.name
      tpl.refreshSelectPicker()
      return ret

    ret.field_name = "Loading..."
    return ret

  isSelectOptionChosen: ->
    if not _.isEmpty Template.instance().chosen_special_field_type.get()
      return "disabled"
    return

  getChosenSpecialFieldType: ->
    return Template.instance().chosen_special_field_type.get()

  fieldPairId: ->
    return Template.instance().field_pair_id

  fieldsAvaibleForUserMapping: ->
    tpl = Template.instance()
    grid_control = APP.modules.project_page.gridControl()
    ret =
      justdo_fields: []
      jira_fields: []

    justdo_field_def = grid_control.getSchemaExtendedWithCustomFields()
    jira_field_def = Template.instance().jira_field_def_obj_rv.get()

    # Append JustDo fields
    for field_id, field_def of justdo_field_def
      field_type = APP.justdo_jira_integration.translateJustdoFieldTypeToMappedFieldType field_def

      if not field_type? or (field_def.client_only) or (field_def.grid_column_substitue_field?) or (not field_def.grid_visible_column) or (not field_def.grid_editable_column) or (tpl.hardcoded_justdo_field_ids.has field_id)
        continue

      ret.justdo_fields.push {field_id: field_id, field_name: field_def.label, field_type: field_type}

    # Append Jira fields
    for field_id, field_def of jira_field_def
      field_type = APP.justdo_jira_integration.translateJiraFieldTypeToMappedFieldType field_def.schema?.type

      if not field_type? or (field_def.name.includes "jd_") or (tpl.hardcoded_jira_field_ids.has field_id)
        continue

      ret.jira_fields.push {field_id: field_id, field_name: field_def.name, field_type: field_type}

    ret.justdo_fields = JustdoHelpers.localeAwareSortCaseInsensitive ret.justdo_fields, (field) -> field.field_name
    ret.jira_fields = JustdoHelpers.localeAwareSortCaseInsensitive ret.jira_fields, (field) -> field.field_name

    tpl.refreshSelectPicker()

    return ret

  getHumanReadableFieldType: (field_type) ->
    if (tokens = field_type.split "_").length is 1
      return field_type

    field_type = JustdoHelpers.ucFirst tokens.shift()
    while (token = tokens.shift())
      field_type = "#{field_type} #{JustdoHelpers.ucFirst token}"

    return field_type

Template.justdo_jira_integration_field_map_option_pair.events
  "change .jira-field-select": (e, tpl) ->
    selected_field_type = $(e.target).closest(".jira-field-select").children("option:selected").data("field_type")
    if selected_field_type is "select" or selected_field_type is "multi_select"
      tpl.chosen_special_field_type.set selected_field_type
      return

    tpl.chosen_special_field_type.set ""
    return

  "click .remove-custom-field-pair": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    custom_field_pair_id = $(e.target).closest(".custom-jira-field-pair").data "field_pair_id"
    jira_project_id = tpl.selected_jira_project_id_rv.get()

    APP.justdo_jira_integration.deleteCustomFieldPair JD.activeJustdoId(), jira_project_id, custom_field_pair_id
    return
