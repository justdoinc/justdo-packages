_.extend JustdoGridGantt.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jggSetProgressPercentage: (task_id, new_progress_percentage) ->
        check task_id, String
        check new_progress_percentage, Number
        
        self.setProgressPercentage task_id, new_progress_percentage, @userId

        return

    return
  