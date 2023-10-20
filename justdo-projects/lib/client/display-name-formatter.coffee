getDisplayName = (user) ->
  return JustdoHelpers.displayName(user)

GridControl.installFormatter "display_name_formatter",
  slickGridColumnStateMaintainer: ->
    # current_baseline = APP.justdo_planning_utilities.getCurrentBaseline() 
    # JustdoHelpers.getUserPreferredDateFormat()

    return

  slick_grid: ->
    {value} = @getFriendlyArgs()

    user_doc = Meteor.users.findOne(value, {fields: {profile: 1}})
    display_name = getDisplayName(user_doc) or ""

    icon_width = 28
    margin = 4 + icon_width

    formatter_html = """<div class="grid-formatter display-name-formatter">"""
    
    if user_doc?
      formatter_html += """
        <span class="slick-prevent-edit grid-tree-control-user-display-only"
            style="
                  width: #{icon_width}px;
                  height: #{icon_width}px;">
          <img src="#{JustdoAvatar.showUserAvatarOrFallback(user_doc)}"
                class="grid-tree-control-user-img slick-prevent-edit"
                alt="#{display_name}"
                style="
                      width: #{icon_width}px;
                      height: #{icon_width}px;">
        </span>
        <span style="margin-left:#{margin}px;">#{display_name}</span>
      """

    formatter_html += "</div>"

    return formatter_html
  
  print: ->
    {value} = @getFriendlyArgs()

    return getDisplayName(value)