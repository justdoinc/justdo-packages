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

  _addQuickNoteOptionsSchema: new SimpleSchema
    title:
      type: String
  addQuickNote: (options, user_id) ->
    check user_id, String
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_addQuickNoteOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    _.extend options,
      user_id: user_id
      order: _.now()

    @quick_notes_collection.insert options
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

  _createTaskFromQuickNoteOptionsSchema: new SimpleSchema
    project_id:
      type: String

    parent_path:
      type: String
      defaultValue: "/"

    order:
      type: Number
      optional: true
  createTaskFromQuickNote: (quick_note_id, options, user_id) ->
    check user_id, String
    check quick_note_id, String
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_createTaskFromQuickNoteOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    {project_id, parent_path, order} = cleaned_val

    quick_note_doc = @requireQuickNoteDoc(quick_note_id, user_id, {title: 1, created_task_id: 1})
    if quick_note_doc.created_task_id?
      throw @_error "task-created-already", "A task was already created from this Quick Note"

    # Check if user is a member of this project
    APP.projects.requireUserIsMemberOfProject project_id, user_id

    task_fields =
      project_id: project_id
      title: quick_note_doc.title
      _created_from_quick_note: quick_note_id

    # Check on whether user is a member of the parent task is performed inside addChild()
    if not (created_task_id = APP.projects._grid_data_com.addChild parent_path, task_fields, user_id)?
      throw @_error "add-task-failed", "Failed to create task from Quick Note"

    quick_note_op =
      $set:
        deleted: new Date
        created_task_id: created_task_id

    @quick_notes_collection.update quick_note_id, quick_note_op

    path_to_created_task = "#{parent_path}/#{created_task_id}/"
    return path_to_created_task

  undoCreateTaskFromQuickNote: (path_to_created_task, project_id, user_id) ->
    check user_id, String
    check path_to_created_task, String

    # Check if user is a member of this project
    APP.projects.requireUserIsMemberOfProject project_id, user_id

    task_id = GridDataCom.helpers.getPathItemId path_to_created_task
    if not (quick_note_doc = @quick_notes_collection.findOne({user_id: user_id, created_task_id: task_id}, {_id: 1}))?
      throw @_error "unknown-quick-note", "Unknown Quick Note"

    APP.projects._grid_data_com.removeParent path_to_created_task, user_id

    @quick_notes_collection.update quick_note_doc._id,
      $set:
        created_task_id: null
        deleted: null

    return
