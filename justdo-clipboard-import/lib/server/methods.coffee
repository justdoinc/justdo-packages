_.extend JustdoClipboardImport.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "clearupTempImportId": (temp_import_ids) ->
        self.clearupTempImportId temp_import_ids, @userId

        return

      "cleanUpDuplicatedManualValue": (task_ids, field_to_clear) ->
        self.cleanUpDuplicatedManualValue task_ids, field_to_clear, @userId

        return

    return