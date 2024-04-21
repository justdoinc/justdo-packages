# Print to console "changed" and a trace, everytime a
# Tracker.Dependecy changes.

original_changed = Tracker.Dependency.prototype.changed

_.extend JustdoHelpers,
  debugTracker: (enable=true) ->
    if enable
      Tracker.Dependency.prototype._changed = original_changed

      Tracker.Dependency.prototype.changed = ->
        console.log("changed")
        console.trace()

        @_changed()
    else
      Tracker.Dependency.prototype.changed = original_changed