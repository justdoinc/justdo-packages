_.extend JustdoQuickNotes.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "addQuickNote": (fields) ->
        check @userId, String
        # Check on fields will be performed in self.addQuickNote()

        self.addQuickNote fields, @userId
        return

      "editQuickNote": (quick_note_id, options) ->
        check @userId, String
        check quick_note_id, String
        # Check on options will be performed in self.editQuickNote()

        self.editQuickNote quick_note_id, options, @userId
        return

      "reorderQuickNote": (target_quick_note_id, put_after_quick_note_id) ->
        check @userId, String
        check target_quick_note_id, String
        check put_after_quick_note_id, Match.Maybe String

        self.reorderQuickNote target_quick_note_id, put_after_quick_note_id, @userId
        return

      "createTaskFromQuickNote": (quick_note_id, project_id, parent_path, order) ->
        check @userId, String
        check quick_note_id, String
        check project_id, String
        check parent_path, String
        check order, Number

        return self.createTaskFromQuickNote quick_note_id, project_id, parent_path, order, @userId

      "undoCreateTaskFromQuickNote": (quick_note_id) ->
        check @userId, String
        check quick_note_id, String

        self.undoCreateTaskFromQuickNote quick_note_id, @userId
        return
        
    return
