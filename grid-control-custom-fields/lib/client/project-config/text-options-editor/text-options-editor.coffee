APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  project_page_module.CustomFieldTextOptionsEditor = JustdoHelpers.generateNewTemplateDropdown "custom-field-text-options-editor", "custom_field_conf_text_options_editor",
    custom_dropdown_class: "dropdown-menu shadow-lg border-0 py-3"
    custom_bound_element_options:
      close_button_html: null

      keep_open_while_bootbox_active: false

      container: ".modal-content"

      openedHandler: ->
        # The bootbox's modal is set with tabindex=-1 attr, that prevents the inputs on the bound
        # element from being focusable. We therefore remove here the tabindex attribute.

        $('[tabindex="-1"]').removeAttr("tabindex")

        @controller_template_scroll_handler = =>
          @$dropdown.data("updatePosition")()

          return
        $(".controller-template").on "scroll", @controller_template_scroll_handler

        @project_configuration_dialog_scroll_handler = =>
          @$dropdown.data("updatePosition")()

          return
        $(".project-configuration-dialog").on "scroll", @project_configuration_dialog_scroll_handler

        return

      closedHandler: ->
        $(".controller-template").off "scroll", @controller_template_scroll_handler
        $(".project-configuration-dialog").off "scroll", @project_configuration_dialog_scroll_handler

        return

    updateDropdownPosition: ($connected_element) ->
      @$dropdown
        .position
          of: $connected_element
          my: "left top"
          at: "left bottom"
          collision: "fit fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element

            element.element.css
              top: new_position.top + 2
              left: new_position.left - 3

  #
  # Text options editor opener
  #
  Template.custom_field_conf_text_options_editor_opener.onCreated ->
    @options_editor = null

    return

  # XXX Not the perfect way to pass data, but quick workaround to the level of complexity
  # the bound element mechanisems reached, Daniel C.
  current_rendering_field_id = null
  Template.custom_field_conf_text_options_editor_opener.onRendered ->
    $(@firstNode).click =>
      current_rendering_field_id = @data.field_id

    @options_editor = new project_page_module.CustomFieldTextOptionsEditor(@firstNode)

    return

  Template.custom_field_conf_text_options_editor_opener.onDestroyed ->
    if @options_editor?
      @options_editor.destroy()
      @options_editor = null

    return

  Template.custom_field_conf_text_options_editor.onCreated ->
    @getProjectCustomFields = ->
      return project_page_module.curProj()?.getProjectCustomFields()

    @getCustomFieldDef = ->
      field_id = current_rendering_field_id

      project_custom_fields = @getProjectCustomFields()
      field_def = _.find project_custom_fields, (field_def) => field_def.field_id is field_id
      return field_def
    
    @isColumnFilterEnabled = ->
      field_def = @getCustomFieldDef()
      return field_def?.filter_type is "whitelist"
    
    @enableColumnFilter = ->
      project_custom_fields = @getProjectCustomFields()
      field_def = _.find project_custom_fields, (field_def) => field_def.field_id is current_rendering_field_id
      field_def.filter_type = "whitelist"

      project_page_module.curProj().setProjectCustomFields(project_custom_fields, -> return)
    
    @disableColumnFilter = ->
      project_custom_fields = @getProjectCustomFields()
      field_def = _.find project_custom_fields, (field_def) => field_def.field_id is current_rendering_field_id
      # We're editing `field_def` by reference, so we need to delete the property directly instead of using `_.omit`
      field_def = delete field_def.filter_type
      project_page_module.curProj().setProjectCustomFields(project_custom_fields, -> return)
    
    return

  Template.custom_field_conf_text_options_editor.helpers 
    isColumnFilterEnabled: ->
      tpl = Template.instance()
      return tpl.isColumnFilterEnabled()

  Template.custom_field_conf_text_options_editor.events
    "click .field-configuration": (e, tpl) ->
      if tpl.isColumnFilterEnabled()
        tpl.disableColumnFilter()
      else
        tpl.enableColumnFilter()

      return