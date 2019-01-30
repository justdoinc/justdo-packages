_.extend JustdoAccounts.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "publicBasicUsersInfo", (users_ids) ->
      # Returns the public info of the specified users_ids
      if _.isString users_ids
        users_ids = [users_ids]

      check users_ids, [String]

      self.basicUserInfoPublicationHandler(@, {users_ids: users_ids})

      return
