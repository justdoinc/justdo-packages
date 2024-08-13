_.extend JustdoSiteAdmins.prototype,
  registerCoreGlobalTemplateHelpers: ->
    self = @

    template_helpers =
      isSiteAdmin: (user_id) ->
        # User can be determined from the argument, from a user object in the data context
        # or from the current Meteor.userId() in that order.

        if not _.isString user_id
          if @profile? or @site_admin?
            # If we see either @profile or @site_admin under data, we consider
            # data as a user doc (and assume that it been requested with the
            # required fields to determine whether the user is a site admin
            # otherwise just call isSiteAdmin with the user_id arg)
            return self.isUserSiteAdmin(@) # avoid sending request to minimongo that might trigger request for data from the server which we might have gotten already by other means
          else if (_user_id = Meteor.userId())?
            user_id = _user_id

        if user_id?
          return self.isUserSiteAdmin(user_id)

        return false

    for helper_name, helper of template_helpers
      Template.registerHelper helper_name, helper

    return
