getCurrentProjectMembersIds = ->
  if not (current_project = APP.modules.project_page.curProj())?
    return []

  return current_project.getMembersIds()

getCurrentProjectMembersDocsSortedByDisplayNameWithLoggedInUserFirst = ->
  if not (current_project = APP.modules.project_page.curProj())?
    return []

  members_docs = current_project.getMembersDocs()

  return JustdoHelpers.sortUsersDocsArrayByDisplayName(members_docs, {logged_in_user_first: true})

#
# Filter controller constructor
#
OwnersFilterControllerConstructor = (context) ->
  GridControl.FilterController.call this

  @once "insterted-to-dom", =>
    $(".owners-search-input").focus()

    return

  @grid_control = context.grid_control
  @column_settings = context.column_settings
  @column_filter_state_ops = context.column_filter_state_ops

  @filter_change_listener = => @refresh_state()

  @grid_control.on "filter-change", @filter_change_listener

  @controller = $("""<div class="owners-filter-controller" />""")

  # note, the reason why we seperate the ul for the dropdown-header is that
  # the vertical scroll of the members ul, when there are many members, go
  # over the x button that close the filter controller.
  # (we might avoid this title at all, if we didn't have this issue)
  @controller.append("""
    <div class="owners-search">
      <input class="owners-search-input form-control form-control-sm" placeholder="Filter Tasks Owners">
    </div>

    <div class="owners-filter-controller-members-wrapper">
      <ul class="owners-filter-controller-members"></ul>
    </div>

    <div class="no-results text-muted" style="display: none">No results found</div>
  """)

  @members_computation = Tracker.autorun =>
    @members = getCurrentProjectMembersDocsSortedByDisplayNameWithLoggedInUserFirst()

    @renderMembers()

    return

  $(@controller).on "keyup", ".owners-search-input", (e) =>
    value = $(e.target).val().trim()

    if _.isEmpty value
      $(".member-item", @controller).removeClass("filtered-out")
      $(".no-results", @controller).hide()
    else
      members_passing_filter = JustdoHelpers.filterUsersDocsArray(@members, value)

      members_ids_passing_filter = {}

      _.each members_passing_filter, (member_doc) ->
        members_ids_passing_filter[member_doc._id] = true

        return

      if _.isEmpty(members_ids_passing_filter)
        $(".no-results", @controller).show()
      else
        $(".no-results", @controller).hide()

      $(".member-item", @controller).each ->
        $this = $(this)

        if $this.attr("member-id") of members_ids_passing_filter
          $this.removeClass("filtered-out")
        else
          $this.addClass("filtered-out")

    return

  $(@controller).on "click", ".member-item", (e) =>
    filter_state = @column_filter_state_ops.getColumnFilter()

    $el = $(e.target).closest(".member-item")
    member_id = $el.attr("member-id")

    if $el.hasClass("selected")
      filter_state = _.without filter_state, member_id
    else
      if filter_state?
        filter_state = _.union filter_state, [member_id]
      else
        filter_state = [member_id]

    if _.isEmpty(filter_state)
      @column_filter_state_ops.clearColumnFilter()
    else
      @column_filter_state_ops.setColumnFilter(filter_state)

  @refresh_state()

  return @

Util.inherits OwnersFilterControllerConstructor, GridControl.FilterController

_.extend OwnersFilterControllerConstructor.prototype,
  renderMembers: ->
    members_items = ""
    for member in @members
      member_item = """<li class="member-item" member-id="#{JustdoHelpers.xssGuard(member?._id, {enclosing_char: '"'})}">""" # Not part of xssGuard below, because xssGuard removes member-id
      member_item += JustdoHelpers.xssGuard("""
          <img class="justdo-avatar" src="#{JustdoAvatar.showUserAvatarOrFallback(member)}" title="#{JustdoHelpers.xssGuard(JustdoHelpers.displayName(member))}" jd-tt="user-info?id=#{member?._id}">
          <div class="display-name">#{JustdoHelpers.displayName(member)}</div>
      """, {allow_html_parsing: true, enclosing_char: ""})
      member_item += """</li>"""

      members_items += member_item

    $(".owners-filter-controller-members", @controller).html(members_items)

    return

  refresh_state: ->
    filter_state = @column_filter_state_ops.getColumnFilter()

    # Remove the selected class from all items
    $(".member-item", @controller).removeClass("selected bg-selected")
    if not filter_state?
      return

    for member_id in filter_state
      $("[member-id=#{member_id}]", @controller).addClass("selected bg-selected")

  destroy: ->
    @grid_control.removeListener "filter-change", @filter_change_listener

    @controller.remove()

    @members_computation.stop()

    @members = [] # release from GC

    return

#
# stateToQuery
#
columnFilterStateToQuery = (column_filter_state, context) ->
  if not context.grid_control.owners_filters_query_updater?
    installOwnersFiltersQueryUpdater(context.grid_control)

  # Remove from column_filter_state members that doesn't exist
  # anymore
  members_ids = getCurrentProjectMembersIds()
  existing_members_ids = _.intersection(members_ids, column_filter_state)
  if column_filter_state.length != existing_members_ids.length
    # Update the column filter state, remove obsolete states.

    if _.isEmpty(existing_members_ids)
      # If after removing obsolete states, we left with no members
      # in the filter, clear the filter.
      context.column_filter_state_ops.clearColumnFilter()
    else
      context.column_filter_state_ops.setColumnFilter(existing_members_ids)

  # Prepare query according to existing_members_ids found
  if _.isEmpty(existing_members_ids)
    query = {}
  else
    if (customQueryGenerator = context.column_schema_definition.grid_column_filter_settings.options?.customQueryGenerator)?
      query = customQueryGenerator(existing_members_ids)
    else
      query = {"#{context.column_id}": {$in: existing_members_ids}}

  return query

getSelectAllFilterState = (context) ->
  return _.map getCurrentProjectMembersDocsSortedByDisplayNameWithLoggedInUserFirst(), (user_doc) -> user_doc._id

GridControl.installFilterType "owners-filter",
  controller_constructor: OwnersFilterControllerConstructor
  column_filter_state_to_query: columnFilterStateToQuery
  getSelectAllFilterState: getSelectAllFilterState

installOwnersFiltersQueryUpdater = (grid_control) ->
  # Note! we install only one updater per grid control no matter
  # how many columns are using the owners-filter.
  #
  # We install the updater the first time an owners-filter is
  # set on any column. We stop the updater upon the destruction of
  # the grid control.

  if grid_control.owners_filters_query_updater?
    logger.warn("onstallOwnersFiltersQueryUpdater already installed")

  previous_value = null
  grid_control.owners_filters_query_updater = Tracker.autorun ->
    current_value = getCurrentProjectMembersIds()

    # We check if != null since in the first time we don't want to
    # trigger redundant update
    if previous_value != null and current_value != previous_value
      # Updated, recalculate filters state
      console.log "XXX Force update"
      grid_control._updateFilterState(true) # true means forced update
                                            # Read more on: grid-control/lib/client/plugins/grid_views/filters/filters.coffee
                                            # under _updateFilterState implementation

    previous_value = current_value

  grid_control.once "destroyed", ->
    grid_control.owners_filters_query_updater.stop()

  return
