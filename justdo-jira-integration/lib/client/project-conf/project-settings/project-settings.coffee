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
    custom_field_map = APP.justdo_jira_integration.getCustomFieldMapByJiraProjectId jira_doc_id, Template.instance().selected_jira_project_id_rv.get()
    # Without _id, re-rendering of justdo_jira_integration_field_map_option_pair template inside {{#each}}
    # will result in incorrect field pair being removed from the UI, while the server record remains correct.
    # According to https://www.blazejs.org/api/spacebars.html#Reactivity-Model-for-Each,
    # Blaze will determine which array element is removed by the element index,
    # which in our case it's always the last row that got deleted from the UI, regardless of which row is actually being removed.
    # Adding _id for each array element will help Blaze to determine which row is deleted and render accordingly.
    custom_field_map = _.map custom_field_map, (field_pair) ->
      field_pair._id = field_pair.id
      return field_pair
    @active_custom_field_map_rv.set custom_field_map
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

  # Stores field pair row views for deletion after user clicking apply.
  @manually_added_field_pair_views = []

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
      selected_justdo_field_id: @justdo_field_id
      selected_jira_field_id: @jira_field_id
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
    APP.justdo_jira_integration.refresh_token_updated = new Date()
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
        active_custom_field_map_length = tpl.active_custom_field_map_rv.get()
        JustdoSnackbar.show
          # Add the count of existing field map to display the actual row number to user
          text: "Field type mismatch at row #{active_custom_field_map_length+i+1}"
        return

      field_pairs.push {justdo_field_id, jira_field_id, id: Random.id()}

    try
      APP.justdo_jira_integration.checkCustomFieldPairMapping jira_doc_id, tpl.selected_jira_project_id_rv.get(), field_pairs
    catch e
      JustdoSnackbar.show
        text: e.reason

    APP.justdo_jira_integration.addCustomFieldPairs JD.activeJustdoId(), tpl.selected_jira_project_id_rv.get(), field_pairs, (err) =>
      if err?
        @logger.error err
        return

      for rendered_view in tpl.manually_added_field_pair_views
        Blaze.remove rendered_view

      JustdoSnackbar.show
        text: "Custom field mapping applied. Field values will be brought into JustDo shortly."
      return

    return

  "click .jira-field-map-add-row": (e, tpl) ->
    node_to_render = $(".jira-field-map-rows-wrapper")[0]
    rendered_view = Blaze.renderWithData Template.justdo_jira_integration_field_map_option_pair, tpl.templateDataForChildTemplate(), node_to_render
    tpl.manually_added_field_pair_views.push rendered_view
    return

Template.justdo_jira_integration_field_map_option_pair.onCreated ->
  _.extend @, @data
  @selected_field_type = new ReactiveVar ""
  @chosen_special_field_type = new ReactiveVar ""
  @is_select_picker_initialized = false
  @isFieldMappable = (field_id, field_type, field_def, field_origin) ->
    if field_origin is "justdo"
      is_field_already_mapped = @hardcoded_justdo_field_ids.has(field_id) or _.find(@active_custom_field_map_rv.get(), (field_pair) -> field_pair.justdo_field_id is field_id)?

      # Disallow if
      #   the field is a private field, or
      #   the field_type isn't supported, or
      #   the field has already been mapped
      if not field_type? or is_field_already_mapped or field_id.includes("priv:")
        return false

      # Allow if the field is editable
      if field_def.grid_editable_column or field_def.user_editable_column
        return true

      return false

    if field_origin is "jira"
      is_field_already_mapped = @hardcoded_jira_field_ids.has(field_id) or _.find(@active_custom_field_map_rv.get(), (field_pair) -> field_pair.jira_field_id is field_id)?

      # Disallow if
      #   the field_type isn't supported, or
      #   the field has already been mapped, or
      #   it's a non-editable field we create (e.g. jd_task_id)
      if not field_type? or (field_def.name.includes "jd_") or is_field_already_mapped
        return false

      return true
    return

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
    tpl = Template.instance()
    tpl.refreshSelectPicker()
    return tpl.chosen_special_field_type.get()

  fieldPairId: ->
    return Template.instance().field_pair_id

  fieldsAvaibleForUserMapping: ->
    tpl = Template.instance()
    grid_control = APP.modules.project_page.gridControl()
    ret =
      justdo_fields: []
      jira_fields: []

    # Allow only fields that are shown on grid, to prevent user mapping to fields that comes from a disabled plugin.
    # Change if in future we want to map more than fields on grid (e.g. task pane)
    field_ids_showable_on_grid = _.union(grid_control.fieldsMissingFromView(), _.map grid_control.getView(), (view) -> view.field)

    schema_extended_with_custom_fields = grid_control.getSchemaExtendedWithCustomFields()
    justdo_field_def = _.pick schema_extended_with_custom_fields, field_ids_showable_on_grid
    jira_field_def = Template.instance().jira_field_def_obj_rv.get()

    # Append JustDo fields
    for field_id, field_def of justdo_field_def
      # For fields like start_date and end_date,
      # the columns on grid is actually the formatter instead of the field itself
      # (e.g. jpu:basket_start_date_formatter and jpu:basket_end_date_formatter).
      # We want to map value to the underlying field instead of the formatter field.
      if (underlying_field_id = field_def.grid_column_formatter_options?.underlying_field_id)?
        field_id = underlying_field_id
        field_def = schema_extended_with_custom_fields[underlying_field_id]

      field_type = APP.justdo_jira_integration.translateJustdoFieldTypeToMappedFieldType field_def

      if not tpl.isFieldMappable field_id, field_type, field_def, "justdo"
        continue

      ret.justdo_fields.push {field_id: field_id, field_name: field_def.label, field_type: field_type}

    # Append Jira fields
    for field_id, field_def of jira_field_def
      field_type = APP.justdo_jira_integration.translateJiraFieldTypeToMappedFieldType field_def.schema?.type

      if not tpl.isFieldMappable field_id, field_type, field_def, "jira"
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

    parent_element = $(e.target).parents ".custom-jira-field-pair"
    custom_field_pair_id = parent_element.data "field_pair_id"

    jira_project_id = tpl.selected_jira_project_id_rv.get()

    APP.justdo_jira_integration.deleteCustomFieldPair JD.activeJustdoId(), jira_project_id, custom_field_pair_id
    return
