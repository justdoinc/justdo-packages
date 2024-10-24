TASKS_COUNT_TO_SHOW_CONFIRM_BOOTBOX = 500

APP.executeAfterAppLibCode ->
  email_regex = new RegExp JustdoHelpers.common_regexps.email
  email_regex_str = JustdoHelpers.common_regexps.email.toString()
  email_regex_str = email_regex_str.substring(2, email_regex_str.length - 2)
  email_regex2 = new RegExp "^<\s*#{email_regex_str}\s*>$"

  Template.members_dropdown_invite.onCreated ->
    tpl = @
    tpl.curProj = APP.modules.project_page.helpers.curProj()
    tpl.users_rv = new ReactiveVar []
    tpl.root_tasks_rv = new ReactiveVar []
    tpl.projects_rv = new ReactiveVar []

    tpl.selected_tasks_rv = new ReactiveVar []
    tpl.selected_projects_rv = new ReactiveVar []

    tpl.active_share_option = new ReactiveVar null
    tpl.search_projects_val_rv = new ReactiveVar ""
    tpl.show_add_button_rv = new ReactiveVar false
    tpl.show_projects_picker_dep = new Tracker.Dependency()
    tpl.invalid_email_input_rv = new ReactiveVar []
    tpl.show_clear_projects_search_rv = new ReactiveVar false

    tpl.autorun ->
      grid_tree = APP.modules.project_page.gridControl()._grid_data.grid_tree
      root_tasks = []
      for item in grid_tree
        if item[0]._id? and item[1] == 0
          root_tasks.push item[0]._id

      tpl.root_tasks_rv.set root_tasks

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
      invite_mode = tpl.data.inviteMode.get()

      if invite_mode
        invite_input_val = $(".invite-members-input").val()

        if email_regex.test(invite_input_val)
          tpl.recognizeEmails()
        else if email_regex2.test(invite_input_val)
          tpl.recognizeEmails()

        tpl.checkAddButtonVisibility()
      else
        tpl.users_rv.set []
        $(".invite-members-input").val ""

      return

    all_tasks_count = APP.collections.Tasks.find({"project_id": JD.activeJustdoId()}).count()
    tpl.share_options = [
      { "class": "share-all", "title": TAPi18n.__ "member_dropdown_invite_share_all_with_number_html", {count: all_tasks_count} },
      { "class": "share-specific", "title": TAPi18n.__ "member_dropdown_invite_share_specific" },
      { "class": "share-none", "title": TAPi18n.__ "member_dropdown_invite_share_none" },
    ]

    tpl.setDefaultSettings = ->
      tpl.users_rv.set []
      tpl.active_share_option.set tpl.share_options[0]

      return

    tpl.setDefaultSettings()

    tpl.checkAddButtonVisibility = ->
      if _.isEmpty($(".invite-members-input").val().trim())
        tpl.show_add_button_rv.set false
      else
        tpl.show_add_button_rv.set true

      return

    tpl.recognizeEmails = (show_advanced_dialog = false) ->
      $el = $(".invite-members-input")
      new_users = {}
      users = tpl.users_rv.get().slice()
      inputs = $el.val().split(",")
      invalid_inputs = []
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
          invalid_inputs.push input
          continue

        if not (existing_user = _.find existing_members, (user) -> JustdoHelpers.getUserMainEmail(user) is email)?
          if names.length == 0
            first_name = last_name = ""
          else if names.length == 1
            first_name = names[0]
            last_name = ""
          else
            first_name = names.slice(0, -1).join(" ")
            last_name = names[names.length - 1]

          if not (existing_user = _.find(users, (user) -> user.email == email))
            new_users[email] = {first_name, last_name}
          else
            JustdoSnackbar.show
              text: "<strong>#{JustdoHelpers.displayName(existing_user)}(#{email})</strong> has already been added"
              duration: 2000
              showAction: false
        else
          JustdoSnackbar.show
            text: "<strong>#{JustdoHelpers.displayName(existing_user)}(#{email})</strong> is already a member of the JustDo"
            duration: 2000
            showAction: false

      new_emails = _.keys(new_users)

      APP.accounts.getFirstLastNameByEmails new_emails, {}, (error, registered_users_details) ->
        if error?
          console.error error
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
            first_name: JustdoHelpers.ucFirst name.first_name
            last_name: JustdoHelpers.ucFirst name.last_name
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

        if show_advanced_dialog
          ProjectPageDialogs.showMemberDialog({initial_users: users})
        else
          tpl.users_rv.set users

      tpl.invalid_email_input_rv.set invalid_inputs

      $el.val ""

      return

    return

  Template.members_dropdown_invite.onRendered ->
    $("#members-invite-projects-selector").on "shown.bs.modal", ->
      media = $(".no-results .tutorial-media")[0]

      if media
        media.play()
        media.playbackRate = 1.5

      return

    return

  Template.members_dropdown_invite.helpers
    users: ->
      return Template.instance().users_rv.get()

    shareOptions: ->
      return Template.instance().share_options

    activeShareOption: ->
      return Template.instance().active_share_option.get().title

    projects: ->
      return Template.instance().projects_rv.get()

    filteredProjects: ->
      tpl = Template.instance()
      tpl.show_projects_picker_dep.depend() # Re-opening projects picker should trigger refresh of project list

      search_val = tpl.search_projects_val_rv.get()
      filter_regexp = JustdoHelpers.createUnicodeSupportedSearchTermRegex search_val

      projects = tpl.projects_rv.get()
      selected_projects_task_id = Tracker.nonreactive -> tpl.selected_projects_rv.get()
      filtered_projects = _.filter projects, (doc) -> doc._id in selected_projects_task_id
      filtered_projects = filtered_projects.concat _.filter projects, (doc) -> doc._id not in selected_projects_task_id
      filtered_projects = _.filter filtered_projects, (doc) ->  filter_regexp.test(doc.title)

      return filtered_projects

    projectIsSelected: ->
      selected_projects = Template.instance().selected_projects_rv.get()

      if _.contains(selected_projects, @_id)
        return "selected"

      return

    isProjectsSelected: ->
      tpl = Template.instance()
      selected_projects = tpl.selected_projects_rv.get()
      return not _.isEmpty selected_projects

    selectedProjectsCount: ->
      tpl = Template.instance()
      return _.size tpl.selected_projects_rv.get()

    isProjectSelectBtnDisabled: ->
      tpl = Template.instance()

      if _.size(tpl.selected_projects_rv.get()) is 0
        return "disabled"

      return

    showAddButton: ->
      return Template.instance().show_add_button_rv.get()

    # Currnetly this helper only shows error related to invalid email input
    # But it's designed to show errs from multiple sources
    alertMsg: ->
      tpl = Template.instance()
      err_msg = []

      if _.isEmpty(invalid_email_input = tpl.invalid_email_input_rv.get())
        return
      
      err_msg.push TAPi18n.__("member_dropdown_invite_cannot_recognize_email_with_input", {input: invalid_email_input.join ", "})

      return err_msg

    showClearProjectsSearch: ->
      return Template.instance().show_clear_projects_search_rv.get()

  Template.members_dropdown_invite.events
    "click .invite-settings-share .invite-setings-btn": (e, tpl) ->
      $(".invite-menu").removeClass "open"
      $dropdown = $(e.target).parents(".invite-settings-share")
      $dropdown_menu = $dropdown.find(".invite-menu")
      $dropdown_menu.toggleClass "open"

      return

    "click .members-dropdown-invite": (e, tpl) ->
      $dropdown = $(e.target).parents(".invite-settings-share")

      if not $dropdown[0]
        $(".invite-menu").removeClass "open"

      return

    "click .invite-menu .dropdown-item": (e, tpl) ->
      $(e.target).parents(".invite-menu").removeClass "open"

      return

    "keydown .invite-members-input": (e, tpl) ->
      tpl.invalid_email_input_rv.set []
      return

    "keyup .invite-members-input": (e, tpl) ->
      if e.keyCode == 13
        tpl.recognizeEmails()

      tpl.checkAddButtonVisibility()

      return

    "paste .invite-members-input": (e, tpl) ->
      Meteor.defer ->
        tpl.recognizeEmails()
        return

      return

    "click .invite-members-input-add": (e, tpl) ->
      tpl.recognizeEmails()
      tpl.checkAddButtonVisibility()
      $(".invite-members-input").focus()

      return

    "click .close": (e, tpl) ->
      tpl.invalid_email_input_rv.set []
      return

    "click .remove-invite-email": (e, tpl) ->
      users = tpl.users_rv.get()
      email_to_remove = @email
      users = users.filter (user) -> user.email != email_to_remove
      tpl.users_rv.set users

      return

    "click .invite-settings-share .dropdown-item": (e, tpl) ->
      if @class == "share-specific"
        tpl.show_projects_picker_dep.changed()
        tpl.search_projects_val_rv.set ""
        tpl.selected_projects_rv.set _.map tpl.selected_tasks_rv.get(), (task) -> task
        $(".search-projects-input").val("")
        $("#members-invite-projects-selector").modal "show"
        $(".search-projects-input").focus()
      else
        tpl.selected_projects_rv.set []
        tpl.active_share_option.set @

      return

    "keyup .search-projects-input": (e, tpl) ->
      value = $(e.target).val().trim()

      if _.isEmpty value
        tpl.search_projects_val_rv.set ""
        tpl.show_clear_projects_search_rv.set false
      else
        tpl.show_clear_projects_search_rv.set true

      tpl.search_projects_val_rv.set value

      return

    "click .clear-projects-search": (e, tpl) ->
      tpl.search_projects_val_rv.set ""
      tpl.show_clear_projects_search_rv.set false
      $(".search-projects-input").val("").focus()

      return

    "click .project-item": (e, tpl) ->
      selected_projects = tpl.selected_projects_rv.get()
      task_id = @_id

      if _.contains(selected_projects, task_id)
        selected_projects = selected_projects.filter (id) -> id isnt task_id
      else
        selected_projects.push task_id

      tpl.selected_projects_rv.set selected_projects

      return

    "click .select-all-projects": (e, tpl)->
      e.preventDefault()

      selected_projects = tpl.selected_projects_rv.get()
      all_projects = tpl.projects_rv.get()
      if not _.isEmpty selected_projects
        tpl.selected_projects_rv.set []
      else
        tpl.selected_projects_rv.set _.map all_projects, (doc) -> doc._id

      return

    "click .save-selected-tasks": (e, tpl) ->
      selected_projects = tpl.selected_projects_rv.get()
      tpl.selected_tasks_rv.set _.map selected_projects, (project) -> project
      active_share_option = tpl.share_options[1]
      active_share_option.title = TAPi18n.__ "member_dropdown_invite_share_projects_with_number_html", {count: selected_projects.length}

      tpl.active_share_option.set active_share_option
      $("#members-invite-projects-selector").modal "hide"

      return

    "click .invite-settings-advanced .invite-setings-btn": (e, tpl) ->
      show_advanced_dialog = true
      tpl.recognizeEmails(show_advanced_dialog)
      share.members_dropdown.closeDropdown()  # defined in ./members-dropdown/members-dropdown-button.coffee

      return

    "click .invite-members-btn": (e, tpl) ->
      invite_input_val = $(".invite-members-input").val()

      if not _.isEmpty invite_input_val
        tpl.recognizeEmails()
      else
        users = tpl.users_rv.get()

        if users.length > 0
          active_justdo = APP.modules.project_page.helpers.curProj()
          
          selected_tasks = []
          share_option = tpl.active_share_option.get()?.class
          if share_option is "share-all"
            selected_tasks = tpl.root_tasks_rv.get()
          if share_option is "share-specific"
            selected_tasks = tpl.selected_tasks_rv.get()
          selected_tasks_and_children_set = new Set(selected_tasks)
          
          for user in users
            if not user.registered or not user.first_name?
              user.first_name = ""
              user.last_name = ""
            user.role = "member"

          proxy_users = _.map _.filter(users, (user) -> user.role is "proxy" and not user.registered), (user) ->
            obj_for_creating_proxy_user =
              email: user.email
              profile: _.pick user, "first_name", "last_name"
            return obj_for_creating_proxy_user

          # Prepare the array of task ids for assigning membership to new users/members
          if not _.isEmpty selected_tasks
            gdc = APP.modules.project_page.gridControl()._grid_data._grid_data_core
            subtree = gdc.getAllItemsKnownDescendantsIdsObj(selected_tasks)
            for task_id of subtree
              selected_tasks_and_children_set.add task_id

          execInviteMemberAndAddTaskMembers = ->
            if not _.isEmpty proxy_users
              APP.accounts.createProxyUsers proxy_users

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

              if not _.isEmpty(all_members) and selected_tasks_and_children_set.size > 0
                APP.modules.project_page.curProj().bulkUpdateTasksUsers
                  tasks: Array.from(selected_tasks_and_children_set)
                  user_perspective_root_items: selected_tasks
                  members_to_add: all_members

              tpl.data.invitedMembersCount.set invited_members.length

              return

            tpl.setDefaultSettings()
            tpl.data.inviteMode.set false

          if (tasks_count = selected_tasks_and_children_set.size) > TASKS_COUNT_TO_SHOW_CONFIRM_BOOTBOX
            msg = "You are about to grant access of #{tasks_count} tasks of this JustDo to"
            if (users_count = _.size(users)) > 1
              msg += " #{users_count} users"
            else if users_count is 1
              msg += " #{users_count} user"
              
            if (proxy_users_count = _.size(proxy_users)) > 0
              if users_count > 0
                msg += " and"
              if proxy_users_count is 1
                msg += " #{proxy_users_count} proxy user"
              else
                msg += " #{proxy_users_count} proxy users"
            msg += ". Proceed?"

            bootbox.confirm
              message: msg
              animate: true
              className: "bootbox-new-design"
              callback: (res) ->
                if res is true
                  execInviteMemberAndAddTaskMembers()
                return
          else
            execInviteMemberAndAddTaskMembers()
      return
