_.extend JustdoQuickNotes.prototype,
  addQuickNote: (fields, cb) ->
    Meteor.call "addQuickNote", fields, cb
    return

  editQuickNote: (quick_note_id, options, cb) ->
    Meteor.call "editQuickNote", quick_note_id, options, cb
    return

  reorderQuickNote: (target_quick_note_id, put_after_quick_note_id, cb) ->
    Meteor.call "reorderQuickNote", target_quick_note_id, put_after_quick_note_id, cb
    return

  createTaskFromQuickNote: (quick_note_id, options, cb) ->
    return Meteor.call "createTaskFromQuickNote", quick_note_id, options, cb

  undoCreateTaskFromQuickNote: (path_to_created_task, project_id, cb) ->
    Meteor.call "undoCreateTaskFromQuickNote", path_to_created_task, project_id, cb
    return
