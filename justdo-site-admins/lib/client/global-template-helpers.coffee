_.extend JustdoSiteAdmins.prototype,
  registerGlobalTemplateHelpers: ->
    self = @

    template_helpers =
      isSiteAdmin: (user_id) ->
        # User can be determined from the argument, from a user object in the data context
        # or from the current Meteor.userId() in that order.

        if user_id? and not _.isString(user_id)
          throw new Meteor.Error "invalid-argument", "user_id must be a string, if it is provided"

        # If user_id is a string, it takes precedence over the attempt to draw
        # the data from the data context or Meteor.userId()
        if user_id?
          return self.isUserSiteAdmin(user_id)

        if @profile? or @site_admin?
          # If the this (@) contains either @profile or @site_admin, we consider
          # it to represent blaze data with a user doc.
          #
          # We assume that it has been requested with the required fields to determine whether
          # the user is a site admin otherwise just call isSiteAdmin with the user_id arg.
          #
          # Important: don't get confused to think that @profile and @site_admin are
          # the only fields required to determine whether the user is a site admin.
          #
          # For example the emails, or their transformed version: all_emails_verified, are
          # also required to determine whether the user is a site admin.
          #
          # We don't document all the fields required here.
          return self.isUserSiteAdmin(@) # avoid sending request to minimongo that might trigger request for data from the server which we might have gotten already by other means

        # By this point we know that user_id is not set and that the data context
        # does not contain the required fields to determine whether the user is a site admin.
        #
        # We try to determine the user_id from Meteor.userId().
        if not (user_id = Meteor.userId())?
          return false

        return self.isUserSiteAdmin(user_id)

    for helper_name, helper of template_helpers
      Template.registerHelper helper_name, helper

    return
