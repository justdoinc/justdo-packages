share.justdo_quick_notes_dropdown = null

Template.justdo_quick_notes_activation_icon.onCreated ->
  active_quick_notes_sub = APP.justdo_quick_notes.subscribeActiveQuickNotes()

  return

Template.justdo_quick_notes_activation_icon.onRendered ->
  @justdo_quick_notes_dropdown = new share.QuickNotesDropdown(@firstNode) # defined in ./dropdown/dropdown.coffee

  share.justdo_quick_notes_dropdown = @justdo_quick_notes_dropdown

  return

Template.justdo_quick_notes_activation_icon.onDestroyed ->
  if @justdo_quick_notes_dropdown?
    @justdo_quick_notes_dropdown.destroy()
    @justdo_quick_notes_dropdown = null

  return

Template.justdo_quick_notes_activation_icon.helpers
  activeNotesCount: ->
    return APP.collections.QuickNotes.find({$and:[{completed:null }]}).fetch().length
