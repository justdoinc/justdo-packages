_.extend JustdoQuickNotes.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "addQuickNote": (title) ->
        check @userId, String
        check title, String

        self.addQuickNote title, @userId
        return

      "editQuickNote": (quick_note_id, new_title, completed) ->
        check @userId, String
        check quick_note_id, String
        check new_title, Match.Maybe String
        check completed, Match.Maybe Boolean

        self.editQuickNote quick_note_id, new_title, completed, @userId
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

      "undoCreateTaskFromQuickNote": (path_to_created_task) ->
        check @userId, String
        check path_to_created_task, String

        self.undoCreateTaskFromQuickNote path_to_created_task, @userId
        return
        
    return
