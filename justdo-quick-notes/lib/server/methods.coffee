_.extend JustdoQuickNotes.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "addQuickNote": (title) ->
        check @userId, String
        check title, String

        self.addQuickNote title, @userId
        return

      "editQuickNote": (quick_note_id, new_title) ->
        check @userId, String
        check new_title, String
        check quick_note_id, String

        self.editQuickNote quick_note_id, new_title, @userId
        return

      "reorderQuickNote": (target_quick_note_id, put_after_quick_note_id) ->
        check @userId, String
        check target_quick_note_id, String
        if put_after_quick_note_id?
          check put_after_quick_note_id, String

        self.reorderQuickNote target_quick_note_id, put_after_quick_note_id, @userId
        return

      "markQuickNoteAsCompleted": (quick_note_id) ->
        check @userId, String
        check quick_note_id, String

        self.markQuickNoteAsCompleted quick_note_id, @userId
        return

      "createTaskFromQuickNote": (quick_note_id, project_id, parent_id, order) ->
        check @userId, String
        check quick_note_id, String
        check project_id, String
        check parent_id, String
        check order, Number

        return self.createTaskFromQuickNote quick_note_id, project_id, parent_id, order, @userId

    return
