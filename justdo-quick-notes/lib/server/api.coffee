_.extend JustdoQuickNotes.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  performInstallProcedures: (project_doc, user_id) ->
    # Called when plugin installed for project project_doc._id
    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    return

  getQuickNoteDoc: (quick_note_id, user_id, fields) ->
    check user_id, String
    check quick_note_id, String
    check fields, Object

    return @quick_notes_collection.findOne {_id: quick_note_id, user_id: user_id}, {fields: fields}

  requireQuickNoteDoc: (quick_note_id, user_id, fields={_id: 1}) ->
    # Checks on parameter will be performed in getQuickNoteDoc()
    if not (quick_note_doc = @getQuickNoteDoc quick_note_id, user_id, fields)?
      throw @_error "unknown-quick-note", "Unknown Quick Note"
    return quick_note_doc

  addQuickNote: (title, user_id) ->
    check user_id, String
    check title, String

    @quick_notes_collection.insert
      title: title
      user_id: user_id
      order: _.now()
    return

  editQuickNote: (quick_note_id, new_title, user_id) ->
    check user_id, String
    check quick_note_id, String
    check new_title, Match.Maybe String

    # Below is to ensure quick_note_id is valid and the note belongs to user_id
    # Error will be thrown by requireQuickNoteDoc() if any of the two is invalid.
    @requireQuickNoteDoc quick_note_id, user_id

    @quick_notes_collection.update quick_note_id,
        $set:
          title: new_title
    return

  reorderQuickNote: (target_quick_note_id, put_after_quick_note_id, user_id) ->
    check user_id, String
    check target_quick_note_id, String
    check put_after_quick_note_id, Match.Maybe String

    if not target_quick_note_id?
      throw @_error "missing-argument", "Target quick note ID must be provided"

    # Check if target quick note exists and user has access to this quick note
    @requireQuickNoteDoc target_quick_note_id, user_id

    # Putting the target quick note to top
    if not put_after_quick_note_id?
      @quick_notes_collection.update target_quick_note_id,
        $set:
          order: _.now()
      return

    put_after_quick_note_order = @requireQuickNoteDoc(put_after_quick_note_id, user_id, {order: 1}).order
    # Putting the target quick note after "put after quick note"
    @quick_notes_collection.update target_quick_note_id,
      $set:
        order: put_after_quick_note_order - 1
    return

  markQuickNoteAsCompleted: (quick_note_id, user_id) ->
    check user_id, String
    check quick_note_id, String

    # Check if target quick note exists and user has access to this quick note
    @requireQuickNoteDoc quick_note_id, user_id

    @quick_notes_collection.update quick_note_id,
      $set:
        completed: new Date
    return

  createTaskFromQuickNote: (quick_note_id, project_id, parent_id="/", order=0, user_id) ->
    if parent_id is 0 or parent_id is "0"
      parent_id = "/"

    check user_id, String
    check quick_note_id, String
    check project_id, String
    check parent_id, String
    check order, Number

    quick_note_doc = @requireQuickNoteDoc(quick_note_id, user_id, {title: 1, created_task_id: 1})
    if quick_note_doc.created_task_id?
      throw @_error "task-created-already", "A task was already created from this Quick Note"

    # Check if user is a member of this project
    APP.projects.requireUserIsMemberOfProject project_id, user_id

    task_fields =
      project_id: project_id
      title: quick_note_doc.title
      _created_from_quick_note: quick_note_id

    if not (created_task_id = APP.projects._grid_data_com.addChild parent_id, task_fields, user_id)?
      throw @_error "add-task-failed", "Failed to create task from Quick Note"

    quick_note_op =
      $set:
        deleted: new Date
        created_task_id: created_task_id

    @quick_notes_collection.update quick_note_id, quick_note_op

    return created_task_id
