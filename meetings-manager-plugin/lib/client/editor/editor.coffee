lock_timeout = 1000 * 10 # 10 seconds
update_lock_timeout = 1000 * 5 # 5 seconds
idle_save_timeout = 500 # 0.5 seconds

Template.locking_text_editor.onCreated ->
  @status = new ReactiveVar "init"
  @content = new ReactiveVar ""
  @disabled = new ReactiveVar false
  @lock = new ReactiveVar null

  @autorun =>
    data = Template.currentData()
    @disabled.set data.disabled
    @lock.set data.lock

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
    @status.set "editing"
    @data.onSave { lock: { user_id: Meteor.userId(), date: TimeSync.getServerTime() } }

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
    return status == "editing" or status == "ready"

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
  "focus textarea": (e, tmpl) ->
    tmpl.beginEditing()

  "keypress textarea": (e, tmpl) ->
    # Use a set timeout to capture the updated value (which is set after this
    # event is done firing)
    Meteor.setTimeout =>
      tmpl.autosave($(e.currentTarget).val())
    ,
      1

  "blur textarea": (e, tmpl) ->
    tmpl.endEditing($(e.currentTarget).val())


Template.locking_text_editor_textarea.onRendered ->
  @$('textarea').autosize()

Template.locking_text_editor_textarea.helpers
  content: ->
    tmpl = Template.instance()
    Meteor.setTimeout =>
      tmpl.$('textarea').trigger('autosize.resize')
    ,
      1

    return @content
