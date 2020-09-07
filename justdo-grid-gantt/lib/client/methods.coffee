_.extend JustdoGridGantt.prototype,
  setProgressPercentage: (task_id, new_progress_percentage, cb) ->
    Meteor.call "jggSetProgressPercentage", task_id, new_progress_percentage, cb
    