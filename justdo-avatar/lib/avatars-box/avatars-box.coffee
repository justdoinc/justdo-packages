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
  @options = _.extend {}, default_options, Template.currentData()

  @max_users_to_display = null # null means unlimited
  if @options.box_grid?.cols?
    @options.box_dim = null # ignore box_dim if box_grid provided

    cols = @options.box_grid.cols
    rows = @options.box_grid.rows
    if not rows?
      rows = 1

    @max_users_to_display = cols * rows
  else if @options.box_dim?.width?
    avatar_outer_width =
      (@options.avatar_dim.width + @options.avatar_dim.margin_right)

    users_per_row = Math.floor(@options.box_dim.width / avatar_outer_width)

    users_per_col = 1
    if @options.box_dim?.height?
      avatar_outer_height =
        (@options.avatar_dim.height + @options.avatar_dim.margin_bottom)

      users_per_col = Math.floor(@options.box_dim.height / avatar_outer_height)

    @max_users_to_display = users_per_row * users_per_col

  @show_button = false
  show_button_op = @options.show_button
  if show_button_op == "always"
    @max_users_to_display -= 1

    @show_button = true
  if show_button_op == "on-excess"
    users_count = @options.primary_users.length
    if @options.secondary_users?
      users_count += @options.secondary_users.length

    if users_count > @max_users_to_display
      @max_users_to_display -= 1

      @show_button = true

  if @max_users_to_display < 0
    @max_users_to_display = 0

normalizeUsersInput = (users) ->
  if _.isEmpty users
    return users

  if _.isString users[0] # we assume single type
    users = JustdoHelpers.getUsersDocsByIds(users)

  return users

tplProp = JustdoHelpers.tplProp
Template.justdo_avatars_box.helpers
  box_components: ->
    max_users_to_display = tplProp("max_users_to_display")
    primary_users = normalizeUsersInput(@primary_users)
    components = primary_users.slice(0, max_users_to_display)
    primary_comps_length = components.length

    if primary_comps_length < max_users_to_display and not _.isEmpty @secondary_users
      space_left = max_users_to_display - primary_comps_length 

      components.push {type: "sep"}

      secondary_users = normalizeUsersInput(@secondary_users)

      components = components.concat secondary_users.slice(0, space_left)

    if tplProp("show_button")
      components.push {type: "btn"}

    if (last_item_obj = _.last components)?
      last_item_obj.last = true

    return components

  button_content: -> tplProp("options").button_content