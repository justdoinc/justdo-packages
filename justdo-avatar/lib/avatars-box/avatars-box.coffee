default_options =
  box_dim: null

  box_grid: null

  avatar_dim: # If you change defaults update avatars-box.sass as well
    width: 30
    height: 30
    margin_right: 5
    margin_bottom: 0

  show_button: "on-excess"

  button_content: '<div class="default-avatar-box-button"><i class="fa fa-ellipsis-h"></i></div>'

Template.justdo_avatars_box.onCreated ->
  @max_users_to_display_rv = new ReactiveVar(null) # null means unlimited
  @options_rv = new ReactiveVar(default_options)
  @controller_rv = new ReactiveVar({})
  @show_button_rv = new ReactiveVar(false)

  @recalculateState = (template_current_data) ->
    options = _.extend {}, default_options, template_current_data

    @controller_rv.set(options.controller)

    max_users_to_display = null
    if options.box_grid?.cols?
      options.box_dim = null # ignore box_dim if box_grid provided

      cols = options.box_grid.cols
      rows = options.box_grid.rows
      if not rows?
        rows = 1

      max_users_to_display = cols * rows
    else if options.box_dim?.width?
      avatar_outer_width =
        (options.avatar_dim.width + options.avatar_dim.margin_right)

      users_per_row = Math.floor(options.box_dim.width / avatar_outer_width)

      users_per_col = 1
      if options.box_dim?.height?
        avatar_outer_height =
          (options.avatar_dim.height + options.avatar_dim.margin_bottom)

        users_per_col = Math.floor(options.box_dim.height / avatar_outer_height)

      max_users_to_display = users_per_row * users_per_col

    show_button = false
    show_button_op = options.show_button
    if show_button_op == "always"
      max_users_to_display -= 1

      show_button = true
    if show_button_op == "on-excess"
      users_count = options.primary_users.length
      if options.secondary_users?
        users_count += options.secondary_users.length

      if users_count > max_users_to_display
        max_users_to_display -= 1

        show_button = true

    if max_users_to_display < 0
      max_users_to_display = 0
    
    @max_users_to_display_rv.set(max_users_to_display)
    @options_rv.set(options)
    @show_button_rv.set(show_button)

    return
  
  @autorun =>
    template_current_data = Template.currentData()
    
    Tracker.nonreactive => @recalculateState(template_current_data)

    return

  return

normalizeUsersInput = (users, max_users) ->
  if _.isEmpty users
    return users

  if _.isString users[0] # we assume single type
    users = JustdoHelpers.getUsersDocsByIds(users, {find_options: {limit: max_users}, user_fields_reactivity: false, missing_users_reactivity: true, get_docs_by_reference: true})

  return users

Template.justdo_avatars_box.helpers
  controller: ->
    tpl = Template.instance()

    return tpl.controller_rv.get()

  box_components: ->
    tpl = Template.instance()

    max_users_to_display = tpl.max_users_to_display_rv.get()
    components = normalizeUsersInput(@primary_users, max_users_to_display)
    primary_comps_length = components.length

    if primary_comps_length < max_users_to_display and not _.isEmpty @secondary_users
      space_left = max_users_to_display - primary_comps_length


      if not _.isEmpty(secondary_users = normalizeUsersInput(@secondary_users, space_left))
        components.push {type: "sep"}
        components = components.concat secondary_users

    if tpl.show_button_rv.get()
      components.push {type: "btn"}

    return components

  button_content: ->
    tpl = Template.instance()

    tmpl_data = tpl.data
    users_limit = tmpl_data.users_limit
    users_count = tmpl_data.primary_users.length + tmpl_data.secondary_users.length
    users_diff = users_count - users_limit

    if users_diff > 0
      return """<div class="default-avatar-box-button avatar-box-plus-users text-primary">+#{users_diff}</div>"""
    else
      return tpl.options_rv.get()?.button_content

tplProp = JustdoHelpers.tplProp
Template.justdo_avatars_box_avatar.onCreated ->
  @controller = Template.currentData().controller

  return

Template.justdo_avatars_box_avatar.helpers
  containersCustomContentGenerator: -> tplProp("controller")?.containersCustomContentGenerator(@)
