_.extend JustdoQuickNotes.prototype,
  addQuickNote: (title, cb) ->
    Meteor.call "addQuickNote", title, cb
    return

  editQuickNote: (quick_note_id, new_title, cb) ->
    Meteor.call "editQuickNote", quick_note_id, new_title, cb
    return

  reorderQuickNote: (target_quick_note_id, put_after_quick_note_id, cb) ->
    Meteor.call "reorderQuickNote", target_quick_note_id, put_after_quick_note_id, cb
    return

  markQuickNoteAsCompleted: (quick_note_id, cb) ->
    Meteor.call "markQuickNoteAsCompleted", quick_note_id, cb
    return

  createTaskFromQuickNote: (quick_note_id, project_id, parent_id="/", order=0, cb) ->
    if parent_id is 0 or parent_id is "0"
      parent_id = "/"
    Meteor.call "createTaskFromQuickNote", quick_note_id, project_id, parent_id, order, cb
    return
