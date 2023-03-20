_.extend JustdoAvatar,
  avatar_required_fields: JustdoHelpers.avatar_required_fields

  getAvatarHtml: (user_doc) ->
    return """<img class="justdo-avatar" src="#{JustdoHelpers.xssGuard(JustdoAvatar.showUserAvatarOrFallback(user_doc))}" title="#{JustdoHelpers.xssGuard(JustdoHelpers.displayName(user_doc))}" />"""

justdo_avatar_helpers =
  avatar_url: ->
    if _.isObject @profile
      # We assume that if profile is object we are within a Meteor.users
      # doc context
      return JustdoAvatar.showUserAvatarOrFallback(@)

    return JustdoAvatar.showAvatarOrFallback(@profile_pic, @email, @first_name, @last_name)

  title_name: ->
    if _.isObject @profile
      return "#{@profile.first_name} #{@profile.last_name}"
    else
      title = ""

      if @first_name?
        title += "#{@first_name}"

      if @last_name?
        title += " #{@last_name}"

      return title

  user_id: ->
    return @_id

Template.justdo_avatar.helpers justdo_avatar_helpers

Template.justdo_avatar_no_tooltip.helpers justdo_avatar_helpers
