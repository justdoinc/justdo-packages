APP.executeAfterAppLibCode ->
  email_regex = new RegExp JustdoHelpers.common_regexps.email
  email_regex_str = JustdoHelpers.common_regexps.email.toString()
  email_regex_str = email_regex_str.substring(2, email_regex_str.length-2)
  email_regex2 = new RegExp "^<\s*#{email_regex_str}\s*>$"

  Template.members_dropdown_invite.onCreated ->
    tpl = @
    tpl.curProj = APP.modules.project_page.helpers.curProj()
    tpl.users = new ReactiveVar []
    tpl.selected_tasks_rv = new ReactiveVar []
    tpl.selected_projects_rv = new ReactiveVar []
    tpl.root_tasks_rv = new ReactiveVar []
    tpl.projects_rv = new ReactiveVar []
    tpl.active_access_role = new ReactiveVar null
    tpl.active_share_option = new ReactiveVar null
    tpl.search_projects_val_rv = new ReactiveVar ""
    tpl.show_add_button_rv = new ReactiveVar false

    tpl.autorun ->
      grid_tree = APP.modules.project_page.gridControl()._grid_data.grid_tree
      root_tasks = []
      for item in grid_tree
        if item[0]._id? and item[1] == 0
          root_tasks.push item[0]._id

      tpl.root_tasks_rv.set root_tasks
      tpl.selected_tasks_rv.set root_tasks

      projects_query =
        project_id: JD.activeJustdoId()
        "p:dp:is_project": true
        "p:dp:is_archived_project":
          $ne: true
      tpl.projects_rv.set APP.collections.Tasks.find(projects_query, {sort: {seqId: 1}}).fetch()

      return

    # When switching to the invite mode,
    # if the input contains a valid email - it's immediately added to the invite list
    tpl.autorun ->
      invited_mode = tpl.data.inviteMode.get()

      if invited_mode
        invite_input_val = $(".invite-members-input").val()

        if email_regex.test(invite_input_val)
          tpl.recognizeEmails()
        else if email_regex2.test(invite_input_val)
          tpl.recognizeEmails()

      return

    tpl.access_roles = [
      {
        "role": "member",
        "title": "Members access"
      },
      {
        "role": "guest",
        "title": "Guest access",
        "subtitle": "Is a member that can't see the list of all members of the JustDo"
      }
    ]

    share_all_title = "Share all"
    all_tasks_count = APP.collections.Tasks.find({"project_id": JD.activeJustdoId()}).count()

    if all_tasks_count > 1
      share_all_title += " <span>#{all_tasks_count}</span> tasks"

    tpl.share_options = [
      { "class": "share-all", "title": share_all_title },
      { "class": "share-specific", "title": "Share specific projects" },
      { "class": "share-none", "title": "Share none" },
    ]

    tpl.setDefaulSettings = ->
      tpl.users.set []
      tpl.active_access_role.set tpl.access_roles[0]
      tpl.active_share_option.set tpl.share_options[0]

      return

    tpl.setDefaulSettings()

    tpl.recognizeEmails = ->
      $el = $(".invite-members-input")
      new_users = {}
      users = tpl.users.get().slice()
      inputs = $el.val().replace(/,/g, ";").split(";")
      existing_members = tpl.curProj.getMembersDocs()
      existing_emails = _.map(existing_members, (member) -> member.emails[0].address)

      for input in inputs
        input_segments = input.split(/\s+/g)
        names = []
        email = null

        for input_segment in input_segments
          input_segment = input_segment.trim().toLowerCase()
          if input_segment.length == 0
            continue

          if email_regex.test(input_segment)
            email = input_segment
            break # Once we found an email, we stop looking forward
          else if email_regex2.test(input_segment)
            email = input_segment.substring(1, input_segment.length-1).trim()
            break # Once we found an email, we stop looking forward
          else
            names.push(input_segment)

        if not email?
          continue

        if not _.contains(existing_emails, email)
          if names.length == 0
            first_name = last_name = ""
          else if names.length == 1
            first_name = names[0]
            last_name = ""
          else
            first_name = names.slice(0, -1).join(" ")
            last_name = names[names.length - 1]

          if not _.find(users, (user) -> user.email == email)
            new_users[email] = {first_name, last_name}
          else
            JustdoSnackbar.show
              text: "<strong>#{input}</strong> has already been added"
              duration: 2000
              showAction: false
        else
          JustdoSnackbar.show
            text: "<strong>#{input}</strong> is already a member of the JustDo"
            duration: 2000
            showAction: false

      new_emails = _.keys(new_users)

      APP.accounts.getFirstLastNameByEmails new_emails, {}, (error, registered_users_details) ->
        if error?
          console.log error
          return

        existing_members_set = new Map()
        for justdo_member in JD.activeJustdo({members: 1})?.members
          role = "member"
          if justdo_member.is_admin
            role = "admin"
          if justdo_member.is_guest
            role = "guest"
          existing_members_set.set justdo_member.user_id, {role: role}

        for email, name of new_users
          user =
          first_name: name.first_name
          last_name: name.last_name
          email: email
          role: "member"
          registered: false

          # Registered user
          if (user_info = registered_users_details[email])?
            _.extend user,
              _id: user_info._id
              first_name: user_info.first_name
              last_name: user_info.last_name
              registered: true
              if user_info.is_proxy
                is_proxy: true
                role: "proxy"
              if (justdo_member = existing_members_set.get user_info._id)
                is_justdo_member: true
                role: justdo_member.role

          users.push user

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

    shareOptions: ->
      return Template.instance().share_options

    activeShareOption: ->
      return Template.instance().active_share_option.get().title

    projects: ->
      search_val = Template.instance().search_projects_val_rv.get()
      filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(search_val)}", "i")

      projects = Template.instance().projects_rv.get()
      filtered_projects = _.filter projects, (doc) ->  filter_regexp.test(doc.title)

      return filtered_projects

    projectIsSelected: ->
      selected_projects = Template.instance().selected_projects_rv.get()

      if _.contains(selected_projects, @._id)
        return "selected"

      return

    showAddButton: ->
      return Template.instance().show_add_button_rv.get()

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

    "keyup .invite-members-input": (e, tpl) ->
      input_val = $(".invite-members-input").val().trim()

      if _.isEmpty input_val
        tpl.show_add_button_rv.set false
      else
        tpl.show_add_button_rv.set true

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

    "click .invite-members-input-add": (e, tpl) ->
      tpl.recognizeEmails()
      $(".invite-members-input").focus()

      return

    "click .members-access-menu .dropdown-item": (e, tpl) ->
      tpl.active_access_role.set @

      return

    "click .invite-list-item .remove": (e, tpl) ->
      users = tpl.users.get()
      email_to_remove = @.email
      users = users.filter (user) -> user.email != email_to_remove
      tpl.users.set users

      return

    "click .share-tasks-menu .dropdown-item": (e, tpl) ->
      if @.class == "share-specific"
        $("#members-invite-projects-selector").modal "show"
      else
        tpl.selected_projects_rv.set []
        tpl.active_share_option.set @

        if @.class == "share-all"
          tpl.selected_tasks_rv.set tpl.root_tasks_rv.get()

        if @.class == "share-none"
          tpl.selected_tasks_rv.set []

      return

    "keyup .search-projects-input": (e, tpl) ->
      value = $(e.target).val().trim()

      if _.isEmpty value
        tpl.search_projects_val_rv.set null

      tpl.search_projects_val_rv.set value

      return

    "click .project-item": (e, tpl) ->
      selected_projects = tpl.selected_projects_rv.get()
      task_id = @._id

      if _.contains(selected_projects, task_id)
        selected_projects = selected_projects.filter (id) -> id isnt task_id
      else
        selected_projects.push task_id

      tpl.selected_projects_rv.set selected_projects

      return

    "click .save-selected-tasks": (e, tpl) ->
      selected_projects = tpl.selected_projects_rv.get()
      tpl.selected_tasks_rv.set selected_projects
      active_share_option = tpl.share_options[1]
      active_share_option.title = """Share <span>#{selected_projects.length}</span> project"""

      if selected_projects.length > 1
        active_share_option.title += "s"

      tpl.active_share_option.set active_share_option
      $("#members-invite-projects-selector").modal "hide"

      return

    "click .invite-settings-advanced": (e, tpl) ->
      ProjectPageDialogs.showMemberDialog()

      return


    "click .invite-members-btn": (e, tpl) ->
      users = tpl.users.get()

      if users.length > 0
        active_justdo = APP.modules.project_page.helpers.curProj()
        sub_trees_roots_selected = tpl.selected_tasks_rv.get()
        selected_tasks = tpl.selected_tasks_rv.get()
        selected_tasks_set = new Set(selected_tasks)


        for user in users
          if not user.registered or not user.first_name?
            user.first_name = ""
            user.last_name = ""

          user.role = tpl.active_access_role.get().role

        proxy_users = _.map _.filter(users, (user) -> user.role is "proxy" and not user.registered), (user) ->
          obj_for_creating_proxy_user =
            email: user.email
            profile: _.pick user, "first_name", "last_name"
          return obj_for_creating_proxy_user

        if not _.isEmpty proxy_users
          APP.accounts.createProxyUsers proxy_users

        # Prepare the array of task ids for assigning membership to new users/members
        if not _.isEmpty selected_tasks
          gdc = APP.modules.project_page.gridControl()._grid_data._grid_data_core
          subtree = gdc.getAllItemsKnownDescendantsIdsObj(selected_tasks)
          for task_id of subtree
            selected_tasks_set.add task_id

        invite_member_promises = []
        existing_members_ids = []

        _.each users, (user) ->
          if user.is_justdo_member
            existing_members_ids.push user._id
          else
            invite_member_option =
              email: user.email
              add_as_guest: user.role is "guest"
            if not user.registered and user.role isnt "proxy" # Proxy users are handled above despite the registered flag isn't updated.
              invite_member_option.profile =
                first_name: user.first_name
                last_name: user.last_name

            promise = new Promise (resolve, reject) ->
              active_justdo.inviteMember invite_member_option, (err, user_id) ->
                if err?
                  resolve({
                    error: err
                    email: user.email
                  })
                  return

                resolve(user_id)
                return
            invite_member_promises.push promise
          return

        Promise.all(invite_member_promises).then (results) ->
          invited_members = []
          emails_not_added_due_to_strict_registration = []
          emails_not_added_due_to_other_reason = []
          for result in results
            if (result.error)
              if (result.error.error == "user-creation-prevented-due-to-strict-registration")
                emails_not_added_due_to_strict_registration.push(result.email)
              else
                emails_not_added_due_to_other_reason.push({
                  error: result.error.reason or result.error.error
                  email: result.email
                })
            else
              invited_members.push result

          if emails_not_added_due_to_strict_registration.length > 0 or emails_not_added_due_to_other_reason.length > 0
            invite_members_failed_tpl =
              JustdoHelpers.renderTemplateInNewNode Template.invite_members_failed, {
                emails_not_added_due_to_strict_registration: if emails_not_added_due_to_strict_registration.length > 0 then emails_not_added_due_to_strict_registration else null,
                emails_not_added_due_to_other_reason: if emails_not_added_due_to_other_reason.length > 0 then emails_not_added_due_to_other_reason else null
              }

            cur_project_id = JD.activeJustdoId()
            dialog = null
            auto_close_modal_computation = Tracker.autorun (computation) ->
              if JD.activeJustdoId() isnt cur_project_id
                dialog?.modal? "hide"
                computation.stop()
              return

            dialog = bootbox.dialog
              title: "Some of the members are not invited"
              message: invite_members_failed_tpl.node
              animate: false
              className: "bootbox-new-design"

              onEscape: ->
                auto_close_modal_computation?.stop?()
                return true

              buttons:
                close:
                  label: "Close"

                  className: "btn-primary"

                  callback: ->
                    auto_close_modal_computation?.stop?()
                    return true

          all_members = invited_members.concat(existing_members_ids)

          if not _.isEmpty(all_members) and selected_tasks_set.size > 0
            APP.modules.project_page.curProj().bulkUpdateTasksUsers
              tasks: Array.from(selected_tasks_set)
              user_perspective_root_items: sub_trees_roots_selected
              members_to_add: all_members

          tpl.data.invitedMembersCount.set invited_members.length

          return

        tpl.setDefaulSettings()
        tpl.data.inviteMode.set false

      return
