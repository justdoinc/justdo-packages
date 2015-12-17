Meteor.startup ->
  # Extend jQuery UI sortable:

  # Add a new event: beforeStart: if callback returns false 
  oldMouseStart = $.ui.sortable.prototype._mouseStart
  $.ui.sortable.prototype._mouseStart = (event, overrideHandle, noActivation) ->
    allowStart = $.Widget.prototype._trigger.call this, "beforeStart", event, this._uiHash()

    if not allowStart
      # If beforeStart returned false, sortable isn't allowed to begin
      return false

    oldMouseStart.apply this, [event, overrideHandle, noActivation]