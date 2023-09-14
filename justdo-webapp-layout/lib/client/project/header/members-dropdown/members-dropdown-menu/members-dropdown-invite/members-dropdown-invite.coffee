

APP.executeAfterAppLibCode ->
  email_regex = new RegExp JustdoHelpers.common_regexps.email
  email_regex_str = JustdoHelpers.common_regexps.email.toString()
  email_regex_str = email_regex_str.substring(2, email_regex_str.length-2)
  email_regex2 = new RegExp "^<\s*#{email_regex_str}\s*>$"

  Template.members_dropdown_invite.onCreated ->
    tpl = @
    tpl.invite_list = new ReactiveVar []

    tpl.recognizeEmails = ->
      $el = $(".invite-members-input")
      inputs = $el.val().replace(/,/g, ";").split(";")

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
          invite_list = tpl.invite_list.get()
          if not _.contains(invite_list, email)
            invite_list.push email
            tpl.invite_list.set invite_list

      $el.val ""

      return

    return

  Template.members_dropdown_invite.helpers
    inviteListEmails: ->
      return Template.instance().invite_list.get()

    inviteListEmailsHTML: ->
      invite_list = Template.instance().invite_list.get()
      html = ""

      for email in invite_list
        html += """
          <div class="invite-list-item">
            <div class="invite-list-item-email">
              #{email}
            </div>
            <svg class="jd-icon remove"><use xlink:href="/layout/icons-feather-sprite.svg#x"></use></svg>
          </div>
        """
      return html

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

    "click .invite-list-item .remove": (e, tpl) ->
      invite_list = tpl.invite_list.get()
      invite_list.splice(invite_list.indexOf(@.substring()), 1);
      tpl.invite_list.set invite_list

      return
