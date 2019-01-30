_.extend JustdoSystemUpdates.prototype,
  isUserReadSystemUpdate: (user_id, update_id) ->
    return Meteor.users.findOne({_id: user_id, "profile.read_system_updates.update_id": update_id})?
