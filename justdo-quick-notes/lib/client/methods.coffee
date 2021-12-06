_.extend JustdoQuickNotes.prototype,
  addQuickNote: (options, cb) ->
    Meteor.call "addQuickNote", options, cb
    return

  editQuickNote: (quick_note_id, new_title, completed, cb) ->
    Meteor.call "editQuickNote", quick_note_id, new_title, completed, cb
    return

  reorderQuickNote: (target_quick_note_id, put_after_quick_note_id, cb) ->
    Meteor.call "reorderQuickNote", target_quick_note_id, put_after_quick_note_id, cb
    return

  createTaskFromQuickNote: (quick_note_id, project_id, parent_path="/", order=0, cb) ->
    Meteor.call "createTaskFromQuickNote", quick_note_id, project_id, parent_path, order, cb
    return

  undoCreateTaskFromQuickNote: (path_to_created_task, cb) ->
    Meteor.call "undoCreateTaskFromQuickNote", path_to_created_task, cb
    return
