#
# General Helpers
#

# JustdoHelpers.common_regexps.email only matches a single email address,
# Here we modify the regex to match multiple email addresses from a string.
email_regex = new RegExp JustdoHelpers.common_regexps.email.toString().replace(/\/\^|\$\//g, ""), "g"

ProjectPageDialogs.showMemberDialog = ->
  message_template =
    APP.helpers.renderTemplateInNewNode(Template.invite_new_user_dialog)

  bootbox.dialog
    title: "Add New Members"
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
    emails_array = $el.val().match email_regex
    users = tpl.users.get()
    users_emails = _.map users, (user) -> user.email
    emails_array = _.difference emails_array, users_emails

    APP.accounts.getFirstLastNameByEmails emails_array, {}, (error, registered_users_details) ->
      if error?
        console.log error
        return

      _.each emails_array, (email) ->
        user =
          first_name: ""
          last_name: ""
          email: email
          role: "member"
          registered: false

        # Registered user
        if (user_name = registered_users_details[email])?
          _.extend user,
            first_name: user_name.first_name
            last_name: user_name.last_name
            registered: true

        users.push user
        return

      tpl.users.set users

    $el.val ""
    $(".users-table-wrapper").animate({ scrollTop: $(".users-table-wrapper").prop("scrollHeight")}, 300)

    return

  return

Template.invite_new_user_dialog.onRendered ->
  $(".users-email-input").focus()

  return

Template.invite_new_user_dialog.helpers
  usersExist: -> Template.instance().users.get().length

  newUsers: ->
    new_users = []

    for user in Template.instance().users.get()
      if not user.registered
        new_users.push user

    return new_users

  registeredUsers: ->
    registered_users = []

    for user in Template.instance().users.get()
      if user.registered
        registered_users.push user

    return registered_users

  getUserRowData: ->
    # Returns an obj of the user inside the {{#each}} loop along with tpl.users and tpl.users_validation_active_rv
    # No need to create a new obj as "@" comes from newUsers/registeredUsers
    tpl = Template.instance()
    return _.extend @, {users: tpl.users, users_validation_active_rv: tpl.users_validation_active_rv}

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
    if e.keyCode == 13 or e.keyCode == 32
      tpl.recognizeEmails()

    return

  "keyup .users-email-input": (e, tpl) ->
    $input = $(e.target).closest(".users-email-input")

    if e.keyCode == 32
      $input.val ""

    if $input.val().trim()
      tpl.show_invite_button_rv.set true
    else
      tpl.show_invite_button_rv.set false

    return

  "paste .users-email-input": (e, tpl) ->
    setTimeout ->
      tpl.recognizeEmails()
    , 50

    return

  "click .users-email-add": (e, tpl) ->
    tpl.recognizeEmails()

    return

  "click .members-all": (e, tpl) ->
    el = $(e.target).closest(".members-all")
    $user_section = el.parents(".users-section")
    users = tpl.users.get()
    registered = null

    if $user_section.hasClass "new-users"
      registered = false

    if $user_section.hasClass "registered-users"
      registered = true

    _.each users, (user) ->
      if user.registered == registered
        user.role = "member"

      return

    tpl.users.set users

    $user_section.find(".user-type-select").val "member"

    return

  "click .guests-all": (e, tpl) ->
    el = $(e.target).closest(".guests-all")
    $user_section = el.parents(".users-section")
    users = tpl.users.get()
    registered = null

    if $user_section.hasClass "new-users"
      registered = false

    if $user_section.hasClass "registered-users"
      registered = true

    _.each users, (user) ->
      if user.registered == registered
        user.role = "guest"

      return

    tpl.users.set users

    $user_section.find(".user-type-select").val "guest"

    return

  "click .proxy-all": (e, tpl) ->
    el = $(e.target).closest(".proxy-all")
    $user_section = el.parents(".users-section")
    users = tpl.users.get()

    _.each users, (user) ->
      if not user.registered
        user.role = "proxy"

      return

    tpl.users.set users

    $user_section.find(".user-type-select").val "proxy"

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
    selected_tasks = tpl.selected_tasks_rv.get()
    users = tpl.users.get()
    proxy_users = _.map _.filter(users, (user) -> user.role is "proxy"), (user) ->
      obj_for_creating_proxy_user =
        email: user.email
        profile: _.pick user, "first_name", "last_name"
      return obj_for_creating_proxy_user

    if not _.isEmpty proxy_users
      APP.accounts.createProxyUsers proxy_users

    # Prepare the array of task ids for assigning membership to new users/members
    if not _.isEmpty selected_tasks
      grid_data = APP.modules.project_page.gridControl()._grid_data
      # Get ids of sub-tree tasks of selected_tasks
      subtree_tasks_ids = []
      tree_traversing_options =
        expand_only: false
        filtered_tree: false
      for task_id in selected_tasks
        grid_data.each "/#{task_id}/", tree_traversing_options, (section, item_type, item_obj) ->
          if item_obj?
            subtree_tasks_ids.push item_obj._id
          return
      selected_tasks = selected_tasks.concat subtree_tasks_ids

    _.each users, (user) ->
      invite_member_option =
        email: user.email
        add_as_guest: user.role is "guest"
      if not user.registered and user.role isnt "proxy" # Proxy users are handled above despite the registered flag isn't updated.
        invite_member_option.profile =
          first_name: user.first_name
          last_name: user.last_name

      active_justdo.inviteMember invite_member_option, (err, user_id) ->
        if err?
          # XXX add error handler
          return

        # Assign membership to selected_tasks as well as their sub-tree tasks
        # This is done for each user instead of batched since we obtain user_id inside this callback
        # The use of $each is to comply with the set of allowed operators
        active_justdo.bulkUpdate selected_tasks, {$addToSet: {users: {$each: [user_id]}}}

        return

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
