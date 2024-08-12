_.extend JustdoSiteAdmins.modules["proxy-users"],
  serverDeferredInit: ->
    self = @

    Meteor.methods
      saSetAsProxyUsers: (user_ids) ->
        check @userId, String
        if _.isString user_ids
          user_ids = [user_ids]
        check user_ids, [String]
        self.requireUserIsSiteAdmin @userId

        query =
          _id:
            $in: user_ids

        options =
          fields:
            deactivated: 1
            "site_admin.is_site_admin": 1

        users = Meteor.users.find(query, options).fetch()

        for user in users
          if user.site_admin?.is_site_admin
            throw self._error "not-supported", "Cannot set a site admin as a proxy user."

          if user.deactivated
            throw self._error "not-supported", "Cannot set a deactivated user as a proxy user."

        Meteor.users.update query, {$set: {is_proxy: true}}, {multi: true}
        APP.accounts.removeUserAvatar user_ids

        return

      saUnsetAsProxyUsers: (user_ids) ->
        check @userId, String
        if _.isString user_ids
          user_ids = [user_ids]
        check user_ids, [String]
        self.requireUserIsSiteAdmin @userId

        Meteor.users.update {_id: {$in: user_ids}}, {$unset: {is_proxy: 1}}, {multi: true}
        return

    return
