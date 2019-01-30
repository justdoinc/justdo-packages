_.extend JustdoBackendCalculatedFields.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    @registerConfigTemplate() # Defined under project-configuration.coffee

    if @destroyed
      return

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

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return