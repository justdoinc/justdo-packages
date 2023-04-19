#
# General Helpers
#

# JustdoHelpers.common_regexps.email only matches a single email address,
# Here we modify the regex to match multiple email addresses from a string.
email_regex = new RegExp JustdoHelpers.common_regexps.email
email_regex_str = JustdoHelpers.common_regexps.email.toString()
email_regex_str = email_regex_str.substring(2, email_regex_str.length-2)
email_regex2 = new RegExp "^<\s*#{email_regex_str}\s*>$"

ProjectPageDialogs.showMemberDialog = ->
  message_template =
    APP.helpers.renderTemplateInNewNode(Template.invite_new_user_dialog)

  bootbox.dialog
    title: "Invite New Members"
    message: message_template.node
    animate: false
    className: "bootbox-new-design invite-new-user-dialog"

    onEscape: ->
      return true

  return

Template.invite_new_user_dialog.onCreated ->
  tpl = @
  tpl.users = new ReactiveVar []
  tpl.users_validation_active_rv = new ReactiveVar false
  tpl.show_select_projects_rv = new ReactiveVar false
  tpl.selected_tasks_rv = new ReactiveVar []
  tpl.search_tasks_val_rv = new ReactiveVar ""
  tpl.show_invite_button_rv = new ReactiveVar false

  tpl.recognizeEmails = ->
    $el = $(".invite-new-wrapper .users-email-input")
    
    new_users = {}
    users = tpl.users.get().slice()
    inputs = $el.val().replace(/,/g, ";").split(";")

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

      return

    $el.val ""
    $(".users-table-wrapper").animate({scrollTop: $(".users-table-wrapper").prop("scrollHeight")}, 300)

    return

  return

Template.invite_new_user_dialog.onRendered ->
  $(".users-email-input").focus()

  return

Template.invite_new_user_dialog.helpers
  groupedUsers: ->
    tpl = Template.instance()
    all_users_rv = tpl.users

    new_users = []
    registered_users = []
    existing_justdo_members = []
    for user in all_users_rv.get()
      if user.is_justdo_member
        existing_justdo_members.push user
      else if user.registered
        registered_users.push user
      else
        new_users.push user

    return {new_users, registered_users, existing_justdo_members}

  getUserGroupData: (base_data) ->
    base_data = base_data.hash
    tpl = Template.instance()
    return _.extend base_data, {users: tpl.users, users_validation_active_rv: tpl.users_validation_active_rv}

  usersExist: -> Template.instance().users.get().length

  showInviteButton: -> Template.instance().show_invite_button_rv.get()

  showSelectProjects: -> Template.instance().show_select_projects_rv.get()

  projects: ->
    project = APP.modules.project_page.project.get()

    if project?
      projects = APP.collections.Tasks.find({
        "p:dp:is_project": true
        "p:dp:is_archived_project":
          $ne: true
        project_id: project.id
      }, {sort: {"title": 1}}).fetch()

      search_val = Template.instance().search_tasks_val_rv.get()

      filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(search_val)}", "i")
      filtered_projects = _.filter projects, (doc) ->  filter_regexp.test(doc.title)

      return filtered_projects

  root_tasks: ->
    root_tasks = []
    grid_tree = APP.modules.project_page.gridControl()._grid_data.grid_tree

    for item in grid_tree
      if item[0]._id? and item[1] == 0
        root_tasks.push item[0]

    search_val = Template.instance().search_tasks_val_rv.get()

    filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(search_val)}", "i")
    filtered_root_tasks = _.filter root_tasks, (doc) ->  filter_regexp.test(doc.title)

    return filtered_root_tasks

  task_is_selected: ->
    selected_tasks = Template.instance().selected_tasks_rv.get()

    if _.contains(selected_tasks, @._id)
      return true
    else
      return false

Template.invite_new_user_dialog.events
  "keydown .users-email-input": (e, tpl) ->
    if e.keyCode == 13
      tpl.recognizeEmails()

    return

  "keyup .users-email-input": (e, tpl) ->
    $input = $(e.target).closest(".users-email-input")

    if $input.val().trim()
      tpl.show_invite_button_rv.set true
    else
      tpl.show_invite_button_rv.set false

    return

  "paste .users-email-input": (e, tpl) ->
    Meteor.defer ->
      tpl.recognizeEmails()
      return
      
    return

  "click .users-email-add": (e, tpl) ->
    tpl.recognizeEmails()

    return

  "click .next": (e, tpl) ->
    e.stopPropagation()

    go_next = true
    tpl.users_validation_active_rv.set true
    name_inputs = $(".user-first-name-input, .user-last-name-input")

    _.each name_inputs, (input) ->
      if $(input).val().trim() == ""
        go_next = false

      return

    if go_next
      tpl.show_select_projects_rv.set true

      setTimeout ->
        $(".search-tasks").focus()
      , 400

    return

  "click .prev": (e, tpl) ->
    e.stopPropagation()
    tpl.show_select_projects_rv.set false

    setTimeout ->
      $(".users-email-input").focus()
    , 400

    return

  "click .task-item": (e, tpl) ->
    selected_tasks = tpl.selected_tasks_rv.get()
    task_id = @._id

    if _.contains(selected_tasks, task_id)
      selected_tasks = selected_tasks.filter (id) -> id isnt task_id
    else
      selected_tasks.push task_id

    tpl.selected_tasks_rv.set selected_tasks

    return

  "keyup .search-tasks": (e, tpl) ->
    value = $(e.target).val().trim()

    if _.isEmpty value
      tpl.search_tasks_val_rv.set null

    tpl.search_tasks_val_rv.set value

    return

  "click .invite": (e, tpl) ->
    active_justdo = APP.modules.project_page.helpers.curProj()
    sub_trees_roots_selected = tpl.selected_tasks_rv.get()
    selected_tasks = tpl.selected_tasks_rv.get()
    selected_tasks_set = new Set(selected_tasks)
    users = tpl.users.get()
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

        bootbox.dialog
          title: "Some of the members are not invited"
          message: invite_members_failed_tpl.node
          animate: false
          className: "bootbox-new-design"

          onEscape: ->
            return true

          buttons:
            close:
              label: "Close"

              className: "btn-primary"

              callback: ->
                return true

      all_members = invited_members.concat(existing_members_ids)

      if not _.isEmpty(all_members) and selected_tasks_set.size > 0
        APP.modules.project_page.curProj().bulkUpdateTasksUsers
          tasks: Array.from(selected_tasks_set)
          user_perspective_root_items: sub_trees_roots_selected
          members_to_add: all_members

      return

    return

Template.batch_add_user_group.onCreated ->
  @users = @data.users
  @users_validation_active_rv = @data.users_validation_active_rv
  @group_type = @data.group_type
  @group_type_to_class_name_and_title =
    new_users:
      wrapper_class: "new-users"
      title: "New Users"
    registered_users:
      wrapper_class: "registered-users"
      title: "Existing Users"
    existing_members:
      wrapper_class: "existing-members"
      title: "Existing Members of this JustDo"
  return

Template.batch_add_user_group.helpers
  getGroupWrapperClassName: ->
    tpl = Template.instance()
    return tpl.group_type_to_class_name_and_title[tpl.group_type].wrapper_class

  getGroupTitle: ->
    tpl = Template.instance()
    return tpl.group_type_to_class_name_and_title[tpl.group_type].title

  getUserGroupType: ->
    return Template.instance().group_type

  showProxyAll: ->
    return Template.instance().group_type == "new_users" and APP.justdo_site_admins.siteAdminFeatureEnabled("proxy-users")

  isProxyUserEnabled: ->
    return APP.justdo_site_admins.siteAdminFeatureEnabled("proxy-users")

  getUserRowData: ->
    # Returns an obj of the user inside the {{#each}} loop along with tpl.users and tpl.users_validation_active_rv
    # No need to create a new obj as "@" comes from newUsers/registeredUsers
    tpl = Template.instance()
    return _.extend @, {users: tpl.users, users_validation_active_rv: tpl.users_validation_active_rv}

Template.batch_add_user_group.events
  "click .members-all": (e, tpl) ->
    users = tpl.users.get()
    registered = true

    if tpl.group_type is "new_users"
      registered = false

    _.each users, (user) ->
      if user.registered == registered and not user.is_proxy and not user.is_justdo_member
        user.role = "member"

      return

    tpl.users.set users

    return

  "click .guests-all": (e, tpl) ->
    users = tpl.users.get()
    registered = true

    if tpl.group_type is "new_users"
      registered = false

    _.each users, (user) ->
      if user.registered == registered and not user.is_proxy and not user.is_justdo_member
        user.role = "guest"
      return

    tpl.users.set users

    return

  "click .proxy-all": (e, tpl) ->
    users = tpl.users.get()

    _.each users, (user) ->
      if not user.registered
        user.role = "proxy"
      return

    tpl.users.set users

    return

Template.batch_add_user_row.onCreated ->
  @users = @data.users
  @users_validation_active_rv = @data.users_validation_active_rv
  return

Template.batch_add_user_row.helpers
  isUserTypeSelected: (user_type) ->
    if @role is user_type
      return "selected"
    return

  showBorderIfEmpty: (name_type) ->
    if Template.instance().users_validation_active_rv.get() and _.isEmpty @[name_type]
      return "border-danger"
    return

  isDisabled: ->
    if @is_proxy or @is_justdo_member
      return "disabled"
    return
  
  showProxy:->
    return not @registered and APP.justdo_site_admins.siteAdminFeatureEnabled("proxy-users")

Template.batch_add_user_row.events
  "click .user-delete": (e, tpl) ->
    email = @email
    users = tpl.users.get()
    users = _.filter users, (user) -> user.email != email
    tpl.users.set users

    return

  "keyup .user-first-name-input, keyup .user-last-name-input": (e, tpl) ->
    input = $(e.target).closest("input")
    name_val = $(input).val().trim()

    if tpl.users_validation_active_rv.get()
      if name_val == ""
        $(input).addClass "border-danger"
      else
        $(input).removeClass "border-danger"

    return

  "change .user-first-name-input": (e, tpl) ->
    input = $(e.target).closest ".user-first-name-input"
    first_name = $(input).val().trim()
    $(input).val first_name

    email = @email
    users = tpl.users.get()

    _.each users, (user) ->
      if user.email == email
        user.first_name = first_name

      return

    tpl.users.set users

    return

  "change .user-last-name-input": (e, tpl) ->
    input = $(e.target).closest ".user-last-name-input"
    last_name = $(input).val().trim()
    $(input).val last_name

    email = @email
    users = tpl.users.get()

    _.each users, (user) ->
      if user.email == email
        user.last_name = last_name

      return

    tpl.users.set users

    return

  "change .user-type-select": (e, tpl) ->
    select = $(e.target).closest ".user-type-select"
    role = $(select).val()
    email = @email
    users = tpl.users.get()

    _.each users, (user) ->
      if user.email == email
        user.role = role

      return

    tpl.users.set users

    return
