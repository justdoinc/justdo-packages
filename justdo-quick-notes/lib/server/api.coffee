# When attempting to reorder a quick note at the bottom,
# we take the order of (old) the quick note at the bottom and minus this constant,
# then use it as the order of the target quick note
space_between_the_last_quick_note = 100000

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

  _addQuickNoteFieldsSchema: new SimpleSchema
    title:
      type: String
  addQuickNote: (fields, user_id) ->
    check user_id, String
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_addQuickNoteFieldsSchema,
        fields,
        {self: @, throw_on_error: true}
      )
    fields = cleaned_val

    _.extend fields,
      user_id: user_id
      order: _.now()

    @quick_notes_collection.insert fields
    return

  _editQuickNoteOptionsSchema: new SimpleSchema
    title:
      type: String
      optional: true

    completed:
      type: Boolean
      optional: true

    deleted:
      type: Boolean
      optional: true
  editQuickNote: (quick_note_id, options, user_id) ->
    check user_id, String
    check quick_note_id, String
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_editQuickNoteOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if _.isEmpty options
      throw @_error "missing-argument", "There is nothing to edit"

    # In db, completed and deleted are stored as a date
    # If a client wants to set either of these as true, we'll convert the option from boolean to date here
    for option in ["completed", "deleted"]
      if options[option]?
        if options[option]
          options[option] = new Date()
        else
          options[option] = null

    # Below is to ensure quick_note_id is valid and the note belongs to user_id
    # Error will be thrown by requireQuickNoteDoc() if any of the two is invalid.
    @requireQuickNoteDoc quick_note_id, user_id

    @quick_notes_collection.update quick_note_id, {$set: options}
    return

  reorderQuickNote: (target_quick_note_id, put_after_quick_note_id, user_id) ->
    check user_id, String
    check target_quick_note_id, String
    check put_after_quick_note_id, Match.Maybe String

    if not target_quick_note_id?
      throw @_error "missing-argument", "Target quick note ID must be provided"

    if target_quick_note_id is put_after_quick_note_id
      throw @_error "invalid-argument", "You cannot put a quick note after itself"

    # Check if target quick note exists and user has access to this quick note
    @requireQuickNoteDoc target_quick_note_id, user_id

    # Putting the target quick note to the top
    if not put_after_quick_note_id?
      @quick_notes_collection.update target_quick_note_id,
        $set:
          order: _.now()
      return

    put_after_quick_note_order = @requireQuickNoteDoc(put_after_quick_note_id, user_id, {order: 1}).order

    #
    # IMPORTANT, if you change put_before_quick_note_query, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see QUICK_NOTES_REORDER_PUT_BEFORE_QUERY_INDEX)
    #
    put_before_quick_note_query =
      _id:
        $ne: target_quick_note_id
      deleted: null
      user_id: user_id
      order:
        $lt: put_after_quick_note_order

    put_before_quick_note_options =
      sort:
        order: -1
      limit: 1

    put_before_quick_note_order = @quick_notes_collection.findOne(put_before_quick_note_query, put_before_quick_note_options)?.order

    # If put_before_quick_note exists, squeeze target_quick_note in between put_before_quick_note and put_after_quick_note
    if put_before_quick_note_order?
      target_quick_note_update_op =
        $set:
          order: Math.floor((put_before_quick_note_order + put_after_quick_note_order) / 2)
    # Else we're putting the target_quick_note to the bottom
    else
      target_quick_note_update_op =
        $set:
          order: put_after_quick_note_order - space_between_the_last_quick_note

    @quick_notes_collection.update target_quick_note_id, target_quick_note_update_op
    return

  createTaskFromQuickNote: (quick_note_id, project_id, parent_path, order, user_id) ->
    check user_id, String
    check quick_note_id, String
    check project_id, String
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

    grid_data = APP.projects._grid_data_com

    # Check on whether user is a member of the parent task is performed inside addChild()
    if not (created_task_id = grid_data.addChild parent_path, task_fields, user_id)?
      throw @_error "add-task-failed", "Failed to create task from Quick Note"

    if ((parent_id = GridDataCom.helpers.getPathItemId parent_path) is "/")
      parent_id = "0"

    created_task_path = parent_path + created_task_id + "/"

    if order?
      # Move the order of the created task
      grid_data.movePath created_task_path, {parent: parent_id, order: order}, user_id

    quick_note_op =
      $set:
        deleted: new Date
        created_task_id: created_task_id

    @quick_notes_collection.update quick_note_id, quick_note_op

    return created_task_id

  undoCreateTaskFromQuickNote: (quick_note_id, user_id) ->
    check user_id, String
    check quick_note_id, String

    # One could simply use quick_note_id to query for task doc,
    # but since we'll need requireQuickNoteDoc() to check if the quick note belongs to the user,
    # the created_task_id is obtained for better query performance on the tasks collection
    if not (task_id = @requireQuickNoteDoc(quick_note_id, user_id, {created_task_id: 1}).created_task_id)?
      throw @_error "invalid-argument", "No task was created by this Quick Note"

    if not (task_parent = _.keys @tasks_collection.findOne(task_id, {fields: {parents: 1}})?.parents)?
      throw @_error "task-not-found", "Task not found"

    if (task_parent.length > 1)
      throw @_error "cannot-undo", "Undo not supported for this task"

    path_to_created_task = "/#{task_parent[0]}/#{task_id}/"
    APP.projects._grid_data_com.removeParent path_to_created_task, user_id

    @quick_notes_collection.update quick_note_id,
      $set:
        created_task_id: null
        deleted: null

    return
