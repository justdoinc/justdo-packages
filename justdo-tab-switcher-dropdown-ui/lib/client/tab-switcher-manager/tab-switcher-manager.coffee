TabSwitcherManager = ->
  @sections_reactive_items_list = new JustdoHelpers.ReactiveItemsList()

  @sections_items_label_filter_keyword_rv = new ReactiveVar(null)

  @sections_reactive_items_list.registerGlobalListingCondition "sections-label-filter", (item) =>
    if (sections_items_label_filter_keyword = @sections_items_label_filter_keyword_rv.get())?
      if _.isEmpty(item.data.itemsSource(@, false))
        return false
      else
        return true

    return true

  return @

itemsSource = (tab_switcher_manager, ignore_listing_condition) ->
  if @itemsGenerator?
    items = @itemsGenerator()

    if ignore_listing_condition
      return items

    items = _.filter items, (item_data) => tab_switcher_manager.isPassingFilter(item_data)

    return items
  return @reactive_items_list.getList("default", ignore_listing_condition)

_.extend TabSwitcherManager.prototype,
  isPassingFilter: (item_data) ->
    if (sections_items_label_filter_keyword = @sections_items_label_filter_keyword_rv.get())?
      return RegExp(JustdoHelpers.escapeRegExp(sections_items_label_filter_keyword), "i").test(item_data.label)

    return true

  setSectionsItemsLabelFilter: (keyword=null) ->
    if (not _.isString(keyword)) or (_.isString(keyword) and keyword.trim() == "")
      keyword = null
    else
      keyword = keyword.trim()

    @sections_items_label_filter_keyword_rv.set(keyword)

    return

  registerSection: (section_id, conf) ->
    if not conf?
      conf = {}

    Meteor._ensure conf, "data" # It is very unlikely that we won't have data object, as it is needed to set a label for the section

    # Create shallow copy to avoid affecting the original data obj provided
    conf.data = _.extend {}, conf.data,
      reactive_items_list: new JustdoHelpers.ReactiveItemsList()

      itemsSource: itemsSource

    conf.data.reactive_items_list.registerGlobalListingCondition "label-filter", (item) => @isPassingFilter(item.data)

    @sections_reactive_items_list.registerItem section_id, conf

    return

  unregisterSection: (section_id) -> @sections_reactive_items_list.unregisterItem section_id

  getSections: (ignore_listing_condition) -> @sections_reactive_items_list.getList("default", ignore_listing_condition)

  getCurrentSectionItem: ->
    unknown_tab_def =
      label: "Unknown Tab"
      tab_id: "unknown-tab"

      icon_type: "feather"
      icon_val: "circle"

    zoom_in_tab_def =
      label: "Zoom In"
      tab_id: "unknown-tab"

      icon_type: "font-awesome"
      icon_val: "fa-window-restore"

    loading_tab_icon =
      label: "Loading Tab"
      tab_id: "loading"

      icon_type: "feather"
      icon_val: "loader"

    current_tab_id = APP.modules.project_page.getCurrentTabId()
    current_sections_state = APP.modules.project_page.getCurrentTabSectionsState()

    if not APP.modules.project_page.getCurrentTabId()? or APP.modules.project_page.getCurrentTabState() == "loading"
      return loading_tab_icon

    for section in @getSections(true)
      for tab in section.itemsSource(@, true)
        tab_sections_state = tab.tab_sections_state or {}

        # Since the tab itself might set sections states in addition to those defined for it in the
        # tab_sections_state. When comaring the current_sections_state to the tab_sections_state,
        # we compare only those states that exists in the tab_sections_state. The partial_current_sections_state
        # includes only those states.
        partial_current_sections_state = _.pick(current_sections_state, _.keys(tab_sections_state))
        for attribute_type, attribute_type_keys of partial_current_sections_state
          partial_current_sections_state[attribute_type] = _.pick(attribute_type_keys, _.keys(tab_sections_state[attribute_type]))

        if tab.tab_id == current_tab_id and JustdoHelpers.jsonComp(partial_current_sections_state, tab_sections_state)
          return tab

    if current_tab_id == "sub-tree"
      return zoom_in_tab_def

    return unknown_tab_def

  registerSectionItem: (section_id, item_id, conf) ->
    if (section_reactive_items_list = @sections_reactive_items_list.getItem(section_id, true).data.reactive_items_list)?
      section_reactive_items_list.registerItem item_id, conf

    return

  resetSectionItems: (section_id) ->
    if (section_reactive_items_list = @sections_reactive_items_list.getItem(section_id, true).data.reactive_items_list)?
      section_reactive_items_list.unregisterAllItems()

    return

  unregisterSectionItem: (section_id, item_id) ->
    if (section_reactive_items_list = @sections_reactive_items_list.getItem(section_id, true).data.reactive_items_list)?
      section_reactive_items_list.unregisterItem item_id

    return

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  module.tab_switcher_manager = new TabSwitcherManager()
  module.tab_switcher_manager.registerSection "main",
    position: 100
  module.tab_switcher_manager.registerSectionItem "main", "main-view",
    position: 100
    data:
      label: "Main View"
      tab_id: "main"

      icon_type: "feather"
      icon_val: "grid"

  module.tab_switcher_manager.registerSectionItem "main", "my-favorites",
    position: 150
    data:
      label: "My Favorites"
      tab_id: "favorites"

      icon_type: "feather"
      icon_val: "star"

  Tracker.autorun (c) ->
    # Wait for user_id to become ready
    if not (user_id = Meteor.userId())?
      return

    c.stop() # Need to run only once, when the user logged-in

    module.tab_switcher_manager.registerSectionItem "main", "due-list",
      position: 200
      data:
        label: "My Due List"
        tab_id: "due-list"

        icon_type: "feather"
        icon_val: "check-square"

        tab_sections_state:
          global:
            owners: user_id

    return

  module.tab_switcher_manager.registerSection "recently",
    position: 200
    data:
      label: "Recently"
  module.tab_switcher_manager.registerSectionItem "recently", "completed",
    position: 100
    data:
      label: "Completed"
      tab_id: "recent-updates"

      icon_type: "feather"
      icon_val: "check"

      tab_sections_state:
        global:
          "tracked-field": "state_updated_at"
          "custom-query": """#{JSON.stringify(JustdoHelpers.getCoreStateMongoQuery("done"))}"""
  module.tab_switcher_manager.registerSectionItem "recently", "updated",
    position: 100
    data:
      label: "Updated"
      tab_id: "recent-updates"

      icon_type: "feather"
      icon_val: "rotate-cw"

      tab_sections_state:
        global:
          "tracked-field": "updatedAt"
  module.tab_switcher_manager.registerSectionItem "recently", "created",
    position: 100
    data:
      label: "Created"
      tab_id: "recent-updates"

      icon_type: "feather"
      icon_val: "plus"

      tab_sections_state:
        global:
          "tracked-field": "createdAt"

  module.tab_switcher_manager.registerSection "misc",
    position: 300
    data:
      label: "Miscellaneous"

  module.tab_switcher_manager.registerSectionItem "misc", "task-ownership-transfers",
    position: 100
    data:
      label: "Tasks Ownership Transfers"
      tab_id: "awaiting-transfer"

      icon_type: "feather"
      icon_val: "repeat"

  module.tab_switcher_manager.registerSectionItem "misc", "tickets-queues",
    position: 200
    data:
      label: "Ticket Queues"
      tab_id: "tickets-queues"

      icon_type: "feather"
      icon_val: "file"

    listingCondition: -> APP.collections.TicketsQueues.find().count() > 0

  module.tab_switcher_manager.registerSection "members-due-lists",
    position: 400
    data:
      label: "Members Due Lists"

      itemsGenerator: ->
        res = [
          {
            label: "All Members Due List"
            tab_id: "due-list"

            icon_type: "feather"
            icon_val: "users"

            tab_sections_state:
              global:
                owners: "*"
          }
        ]

        for member_user_doc, i in APP.modules.project_page.template_helpers.project_all_members_except_me_sorted_by_first_name()
          res.push
            label: JustdoHelpers.displayName(member_user_doc)
            tab_id: "due-list"

            icon_type: "user-avatar"
            icon_val: member_user_doc

            tab_sections_state:
              global:
                owners: member_user_doc.user_id

        return res

    listingCondition: -> APP.modules.project_page.template_helpers.project_all_members_except_me().length > 0

  return