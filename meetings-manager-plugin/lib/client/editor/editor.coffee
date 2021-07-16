lock_timeout = 1000 * 10 # 10 seconds
update_lock_timeout = 1000 * 5 # 5 seconds
idle_save_timeout = 500 # 0.5 seconds

Template.locking_text_editor.onCreated ->
  @status = new ReactiveVar "init"
  @content = new ReactiveVar ""
  @disabled = new ReactiveVar false
  @lock = new ReactiveVar null
  @editable = new ReactiveVar true

  @autorun =>
    data = Template.currentData()
    @disabled.set data.disabled
    @lock.set data.lock
    @editable.set data.editable

  @autorun =>
    status = @status.get()

    # We don't want to touch the text editor once the content is being edited
    if status != "editing"
      data = Template.currentData()
      @content.set data.content

    if status == "init"
      @status.set "ready"

    if @disabled.get()
      @status.set "disabled"
      return


    # XXX seems like getServerTime isn't reactive for some reason.
    lock = @lock.get()
    if lock?.user_id != Meteor.userId() and (TimeSync.getServerTime() - lock?.date) < lock_timeout
      @status.set "locked"
      return

    if status != "editing"
      @status.set "ready"
      return

  @update_lock_timer = null
  @idle_save_timer = null

  @beginEditing = =>
    if not @editable.get()
      return
    @status.set "editing"
    @data.onSave { lock: { user_id: Meteor.userId(), date: TimeSync.getServerTime() } }

    Tracker.flush()
    APP.getEnv (env) =>
      @$(".note-froala").froalaEditor({
        toolbarButtons: ["bold", "italic", "underline", "strikeThrough", "color", "insertTable", "fontSize",
          "align", "formatOL", "formatUOL", "undo", "redo",
        ]
        imageEditButtons: ['imageReplace', 'imageAlign', 'imageCaption', 'imageRemove', '|', 'imageLink', 'linkOpen', 
          'linkEdit', 'linkRemove', '-', 'imageDisplay', 'imageStyle', 'imageAlt', 'imageSize']
        tableStyles:
          "fr-no-borders": "No borders"
          "fr-dashed-borders": "Dashed Borders"
          "fr-alternate-rows": "Alternate Rows"
        quickInsertTags: []
        charCounterCount: false
        key: env.FROALA_ACTIVATION_KEY
      })
      .on "froalaEditor.blur", (e, editor) =>
        if editor.core.isEmpty()
          content = ""
        else
          content = editor.html.get()

        @endEditing(content)
        editor.destroy()
        return
      .on "froalaEditor.contentChanged", (e, editor) =>
        @autosave(editor.html.get())

      @$(".note-froala").froalaEditor "html.set", @data.content
      @$(".note-froala").froalaEditor "events.focus"

  @keepLockCallback = () =>
    @data.onSave { lock: { user_id: Meteor.userId(), date: TimeSync.getServerTime() } }

  @autosave = (content) =>

    if @idle_save_timer?
      Meteor.clearTimeout @idle_save_timer
      @idle_save_timer = null

    if not @update_lock_timer?
      @update_lock_timer = Meteor.setTimeout @keepLockCallback, update_lock_timeout

    @idle_save_timer = Meteor.setTimeout @idleSaveCalback.bind(@, content), idle_save_timeout

  @idleSaveCalback = (content) =>
    @idle_save_timer = null
    @data.onSave { content: content, lock: { user_id: Meteor.userId(), date: TimeSync.getServerTime() } }

  @endEditing = (content) =>
    if @update_lock_timer?
      Meteor.clearTimeout @update_lock_timer
      @update_lock_timer = null

    if @idle_save_timer?
      Meteor.clearTimeout @idle_save_timer
      @idle_save_timer = null

    @status.set "ready"
    @data.onSave { content: content, lock: {} }

Template.locking_text_editor.helpers
  content: ->
    tmpl = Template.instance()

    return tmpl.content.get()

  editing: ->
    tmpl = Template.instance()
    status = tmpl.status.get()
    return status == "editing"

  locked: ->
    tmpl = Template.instance()
    status = tmpl.status.get()
    return status == "locked"

  locked_by_self: ->
    lock = @lock
    user_id = Meteor.userId()
    return lock? and lock.user_id == user_id and (TimeSync.getServerTime() - lock?.date) < lock_timeout

  locked_user_id: ->
    lock = @lock
    return lock?.user_id

  locked_user: ->
    lock = @lock
    return lock? and Meteor.users.findOne { _id: lock.user_id }

  editing_class: ->
    tmpl = Template.instance()
    status = tmpl.status.get()
    return status == "editing" and "locking-text-editor-editing"

  locked_class: ->
    tmpl = Template.instance()
    status = tmpl.status.get()
    return status == "locked" and "locking-text-editor-locked"

Template.locking_text_editor.events
  "click .note-box": (e, tmpl) ->
    tmpl.beginEditing tmpl

  # "blur textarea": (e, tmpl) ->
  #   tmpl.endEditing($(e.currentTarget).val())
