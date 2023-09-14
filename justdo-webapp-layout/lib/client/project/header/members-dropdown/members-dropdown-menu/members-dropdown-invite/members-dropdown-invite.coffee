

APP.executeAfterAppLibCode ->
  email_regex = new RegExp JustdoHelpers.common_regexps.email
  email_regex_str = JustdoHelpers.common_regexps.email.toString()
  email_regex_str = email_regex_str.substring(2, email_regex_str.length-2)
  email_regex2 = new RegExp "^<\s*#{email_regex_str}\s*>$"

  Template.members_dropdown_invite.onCreated ->
    tpl = @
    tpl.users = new ReactiveVar []
    tpl.access_roles = [
      {
        "role": "member",
        "title": "Members access"
      },
      {
        "role": "guest",
        "title": "Guest access",
        "subtitle": "Is a member that can't see the list of all members of the JustDo"
      },
    ]

    tpl.active_access_role = new ReactiveVar tpl.access_roles[0]

    tpl.recognizeEmails = ->
      $el = $(".invite-members-input")
      inputs = $el.val().replace(/,/g, ";").split(";")
      users = tpl.users.get()
      existing_emails = _.map users, (user) -> user.email
      new_emails = []

      for input in inputs
        input_segments = input.split(/\s+/g)
        email = null
        for input_segment in input_segments
          input_segment = input_segment.trim().toLowerCase()
          if input_segment.length == 0
            continue

          if email_regex.test(input_segment)
            email = input_segment
            break # Once we found an email, we stop looking forward

          if email_regex2.test(input_segment)
            email = input_segment.substring(1, input_segment.length-1).trim()
            break # Once we found an email, we stop looking forward

        if email?
          if not _.contains(existing_emails, email)
            users.push {"email": email}
            tpl.users.set users

      $el.val ""

      return

    return

  Template.members_dropdown_invite.helpers
    users: ->
      return Template.instance().users.get()

    activeAccessRole: ->
      return Template.instance().active_access_role.get()

    accessRoles: ->
      return Template.instance().access_roles

  Template.members_dropdown_invite.events
    "click .invite-menu-btn": (e, tpl) ->
      $(".invite-menu").removeClass "open"
      $dropdown = $(e.target).parents(".invite-menu-wrapper")
      $dropdown_menu = $dropdown.find(".invite-menu")
      $dropdown_menu.toggleClass "open"

      return

    "click .members-dropdown-invite": (e, tpl) ->
      $dropdown = $(e.target).parents(".invite-menu-wrapper")

      if not $dropdown[0]
        $(".invite-menu").removeClass "open"

      return

    "click .invite-menu .dropdown-item": (e, tpl) ->
      $(e.target).parents(".invite-menu").removeClass "open"

      return

    "keydown .invite-members-input": (e, tpl) ->
      if e.keyCode == 13
        tpl.recognizeEmails()

      return

    "paste .invite-members-input": (e, tpl) ->
      Meteor.defer ->
        tpl.recognizeEmails()
        return

      return

    "click .members-access-menu .dropdown-item": (e, tpl) ->
      tpl.active_access_role.set @

      return

    "click .invite-list-item .remove": (e, tpl) ->
      users = tpl.users.get()
      users.splice(users.indexOf(@.substring()), 1);
      tpl.users.set users

      return

    "click .invite-members-btn": (e, tpl) ->
      active_justdo = APP.modules.project_page.helpers.curProj()
      users = tpl.users.get()
      users = _.map users, (user) -> {"email": user.email, "role": tpl.active_access_role.get().role}

      console.log users

      return
