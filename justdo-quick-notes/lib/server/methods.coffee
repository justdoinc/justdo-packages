_.extend JustdoQuickNotes.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "addQuickNote": (options) ->
        check @userId, String
        # Check on options will be performed in self.addQuickNote()

        self.addQuickNote options, @userId
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

      "createTaskFromQuickNote": (quick_note_id, options) ->
        check @userId, String
        check quick_note_id, String
        # Check on options will be performed in self.createTaskFromQuickNote()

        return self.createTaskFromQuickNote quick_note_id, options, @userId

      "undoCreateTaskFromQuickNote": (path_to_created_task, project_id) ->
        check @userId, String
        check path_to_created_task, String

        self.undoCreateTaskFromQuickNote path_to_created_task, project_id, @userId
        return
        
    return
