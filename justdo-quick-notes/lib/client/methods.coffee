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

  createTaskFromQuickNote: (quick_note_id, project_id, parent_path, order, cb) ->
    return Meteor.call "createTaskFromQuickNote", quick_note_id, project_id, parent_path, order, cb

  undoCreateTaskFromQuickNote: (quick_note_id, cb) ->
    Meteor.call "undoCreateTaskFromQuickNote", quick_note_id, cb
    return
