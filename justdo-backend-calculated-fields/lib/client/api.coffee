_.extend JustdoBackendCalculatedFields.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    @registerConfigTemplate() # Defined under project-configuration.coffee

    if @destroyed
      return

    @setupCustomFeatureMaintainer()

    return

  enableBackendCalculatedFieldsForCurrentProject: ->
    APP.modules.project_page.curProj().enableCustomFeatures(@options.custom_feature_id)

    return

  disableBackendCalculatedFieldsForCurrentProject: ->
    APP.modules.project_page.curProj().disableCustomFeatures(@options.custom_feature_id)

    return

  setupParamsFieldEditorSystemMessagesClearer: ->
    self = @
    clearSystemMessagesFromEditor = (editor) ->
      if self.isParamsValueIsSystemMessage(editor.serializeValue())
        editor.setInputValue(" ")

      return

    Template.app_layout.onRendered ->      
      $(".global-wrapper").on "focus", ".additional-field-item textarea", (e) ->
        $field_editor = $(e.target).closest(".field-editor")
        if $field_editor.data("editor_field_id") == "backend_calc_field_cmd_params"
          clearSystemMessagesFromEditor($field_editor.data("editor").editor)

          setTimeout ->
            # The click on the text area might cause lose focus when the height of the textarea changes
            # after the clear. Make sure it is focused.

            if not $field_editor.find("textarea").is(":focus")
              $(e.target).focus()
          , 1000


      return

    Tracker.autorun ->
      if (gc = APP.modules.project_page.gridControl())?
        slick_grid = gc._grid

        if not slick_grid._backend_calculated_fields_hooks_installed
          slick_grid.onEditCell.subscribe (e, edit_req) ->
            if edit_req.column.field == "backend_calc_field_cmd_params"
              clearSystemMessagesFromEditor(edit_req.currentEditor)

          slick_grid._backend_calculated_fields_hooks_installed = true

    return
  
  commands:
    max_due_date_of_direct_subtasks:
      label: "Max due date by direct child-tasks"
    max_due_date_of_all_subtasks:
      label: "Max due date by all child tasks"
    max_due_date_of:
      label: "Max due date of specific tasks"
    due_date_offset:
      label: "Due date by offset"

  setupCustomFeatureMaintainer: ->
    self = @

    self.custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage self.options.custom_feature_id,
        installer: =>
          commands_select_options = []
          for command_id, command_def of @commands
            commands_select_options.push
              option_id: command_id
              label: command_def.label

          APP.modules.project_page.setupPseudoCustomField "backend_calc_field_cmd",
            "field_type" : "select",
            "grid_editable_column" : true,
            "grid_visible_column" : true,
            "label" : "Calc command",
            "default_width" : 240,
            "field_options" :
              "select_options" : commands_select_options
          
          APP.modules.project_page.setupPseudoCustomField "backend_calc_field_cmd_params",
            "field_type" : "string",
            "grid_editable_column" : true,
            "grid_visible_column" : true,
            "label" : "Calc parameters",
            "default_width" : 250

        destroyer: =>
          APP.modules.project_page.removePseudoCustomFields "backend_calc_field_cmd"

          APP.modules.project_page.removePseudoCustomFields "backend_calc_field_cmd_params"

          return

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @custom_feature_maintainer.stop()

    @destroyed = true
    
    @logger.debug "Destroyed"

    return