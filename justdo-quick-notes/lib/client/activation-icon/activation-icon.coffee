share.justdo_quick_notes_dropdown = null

Template.justdo_quick_notes_activation_icon.onCreated ->
  APP.justdo_quick_notes.subscribeQuickNotesInfo()

  return

Template.justdo_quick_notes_activation_icon.onRendered ->
  @justdo_quick_notes_dropdown = new share.QuickNotesDropdown(@firstNode) # defined in ./dropdown/dropdown.coffee

  share.justdo_quick_notes_dropdown = @justdo_quick_notes_dropdown

  return

Template.justdo_quick_notes_activation_icon.onDestroyed ->
  if @justdo_quick_notes_dropdown?
    @justdo_quick_notes_dropdown.destroy()
    @justdo_quick_notes_dropdown = null

  APP.justdo_quick_notes.unsubscribeQuickNotesInfo()

  return

Template.justdo_quick_notes_activation_icon.helpers
  activeNotesCount: ->
    return APP.collections.QuickNotesInfo.findOne("active_quick_notes_count", {count: 1})?.count or 0
