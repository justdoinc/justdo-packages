APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  module.project_config_ui.registerConfigSection "custom-fields",
    # Add to this section the configs that you want to show first,
    # without any specific title (usually very basic configurations)

    title: "Custom Fields" # null means no title
    priority: 10

  module.project_config_ui.registerConfigTemplate "custom-fields",
    section: "custom-fields"
    template: "custom_fields_conf"
    priority: 100

  Template.custom_fields_conf.onCreated ->
    @show_add_button = new ReactiveVar(false)

    @updateAddButtonState = =>
      if $(".new-field-label").val() == ""
        @show_add_button.set(false)
      else
        @show_add_button.set(true)

      return

    return

  Template.custom_fields_conf.onRendered ->
    @$(".custom-fields-conf").sortable
      containment: "parent"
      handle: ".sort-handle"
      items: ".custom-field-row"
      axis: "y"
      helper: "clone"
      start: (event, ui) ->
        ui.helper.hide()
        ui.placeholder.html(ui.item.html()).css("visibility", "visible").find()

        $("input", ui.placeholder).val($("input", ui.item).val())

        return

      stop: (event, ui) ->
        project = module.curProj()

        custom_fields = project.getProjectCustomFields()

        new_fields_order = $(".custom-field-row").map (x) ->
          return $(@).attr("field-id")

        new_custom_fields = []
        for field_id in new_fields_order
          new_custom_fields.push _.find custom_fields, (field) -> field.field_id == field_id

        # We cancel to avoid Blaze issues, we need the DOM to be updated only by Blaze
        # otherwise, after the update will come back from the server, Blaze will mess the
        # view
        $(".custom-fields-conf").sortable("cancel")

        project.setProjectCustomFields new_custom_fields, (err) ->
          if err?
            alert(err)

            return

          return

        return

    return

  Template.custom_fields_conf.helpers
    getFieldTypes: -> GridControlCustomFields.getAvailableCustomFieldsTypes()
    showAddButton: ->
      tpl = Template.instance()

      return tpl.show_add_button.get()
    customFields: ->
      project_custom_fields = module.curProj()?.getProjectCustomFields()

      return project_custom_fields

  addCustomField = ->
    project = module.curProj()

    custom_fields = project.getProjectCustomFields()

    if not custom_fields?
      custom_fields = []

    field_label = $(".new-field-label").val()

    if _.isEmpty field_label
      return

    custom_field_type_def =
      GridControlCustomFields.findCustomFieldTypeDefinitionByCustomFieldTypeId($(".new-field-type").val())

    custom_field_definition =
      field_id: Random.id()
      custom_field_type_id: custom_field_type_def.custom_field_type_id
      field_type: custom_field_type_def.type_id
      grid_editable_column: true
      grid_visible_column: true
      label: field_label
      default_width: 120

    if (custom_field_options = custom_field_type_def.custom_field_options)?
      _.extend custom_field_definition, custom_field_options

    # XXX Show better error notices
    #
    # try
    #   {cleaned_val} =
    #     JustdoHelpers.simpleSchemaCleanAndValidate(
    #       GridControlCustomFields.custom_field_definition_schema,
    #       custom_field_definition,
    #       {throw_on_error: true}
    #     )
    # catch e
    #   console.log e

    custom_fields.push custom_field_definition

    project.setProjectCustomFields custom_fields, (err) ->
      if err?
        alert(err)

        return

      $(".new-field-label").val("").keyup() # keyup to update add button state
      $(".new-field-type").prop("selectedIndex", 0)

      return

    return

  Template.custom_fields_conf.events
    "keyup .new-field-label": (e, tpl) ->
      tpl.updateAddButtonState()

      if e.which == 13
        addCustomField()

        return

      return

    "click .add": ->
      addCustomField()

      return

    "click .remove": (e) ->
      project = module.curProj()

      $tr = $(e.target).closest("tr")
      field_id = $tr.attr("field-id")
      field_label = $tr.find(".field-label").val()

      bootbox.confirm "Are you sure you want to remove field <i>#{field_label}</i>?", (result) ->
        if result
          custom_fields = project.getProjectCustomFields()

          custom_fields = _.filter custom_fields, (custom_field) ->
            if custom_field.field_id == field_id
              return false

            return true

          project.setProjectCustomFields custom_fields, -> return

        return

      return

    "change .field-label": (e) ->
      project = module.curProj()

      $tr = $(e.target).closest("tr")
      field_id = $tr.attr("field-id")
      field_label = $tr.find(".field-label").val()

      custom_fields = project.getProjectCustomFields()

      for custom_field_definition in custom_fields
        if custom_field_definition.field_id == field_id
          custom_field_definition.label = field_label

      project.setProjectCustomFields custom_fields, (err) ->
        if err?
          alert(err)

          return

      return

  customFieldObjectToCustomFieldTypeDef = (custom_field_def) ->
    if custom_field_def.custom_field_type_id?
      custom_field_type_def = GridControlCustomFields.findCustomFieldTypeDefinitionByCustomFieldTypeId(custom_field_def.custom_field_type_id)
    else
      # Backward compatibility, for the time we didn't save the custom_field_def.custom_field_type_def,
      # search by the type_id
      custom_field_type_def = _.find GridControlCustomFields.getAvailableCustomFieldsTypes(), (_field_type_def) =>
        return _field_type_def.type_id == custom_field_def.field_type

    return custom_field_type_def

  Template.custom_field_conf.helpers
    settingsButtonTemplate: ->
      if @disabled
        # Not supported for disabled custom fields.
        return

      return customFieldObjectToCustomFieldTypeDef(@)?.settings_button_template

    fieldTypeToFieldLabel: ->
      if @disabled
        return "Disabled field"

      return customFieldObjectToCustomFieldTypeDef(@)?.label or "Unknown type"
