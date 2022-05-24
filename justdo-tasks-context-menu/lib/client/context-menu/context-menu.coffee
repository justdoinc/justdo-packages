close_to_bottom_range = 50

Template.tasks_context_menu.onCreated ->
  @tasks_context_menu_controller = @data.controller

  return

Template.tasks_context_menu.helpers
  isVisible: ->
    return APP.justdo_tasks_context_menu.isVisible()

  isMultiSelect: ->
    if not (gc = APP.modules.project_page?.gridControl())?
      return false

    return gc.isMultiSelectMode()

  getMainSections: -> 
    return APP.justdo_tasks_context_menu.getMainSections()

  updatedAt: ->
    return @controller.getContextItemObj({updatedAt: 1})?.updatedAt

  isSectionHasItems: (section) ->
    return section.reactive_items_list.getList().length > 0

Template.tasks_context_section.onCreated ->
  # moveTimer used in mouseleave and mousemove events (.dropdown-item) to detect when the mouse stop
  @moveTimer = null

  @isLimitRenderedItems = =>
    return @data.section.limit_rendered_items

  if not @isLimitRenderedItems()
    @resetItemsRenderLimit = => return
  else
    @last_close_to_bottom_threshold = 0

    @items_render_limit_rv = new ReactiveVar 0
    @resetItemsRenderLimit = =>
      @items_render_limit_rv.set @data.section.limit_rendered_items_initial_items
      @last_close_to_bottom_threshold = 0

      return

  return

Template.tasks_context_section.onRendered ->
  if @isLimitRenderedItems()
    # Initialize rv and event handler for scroll-to-show

    @resetItemsRenderLimit()

    @increaseItemsRenderLimit = =>
      @items_render_limit_rv.set @items_render_limit_rv.get() + @data.section.limit_rendered_items_load_more_items
      return

    $dropdown_menu = $(".nested-dropdown-menu-#{@data.dropdown_menu_id} .dropdown-items-wrapper")

    getCurrentCloseToBottomThreshold = ->
      return $dropdown_menu.get(0).scrollHeight - close_to_bottom_range

    $dropdown_menu.scroll (e) =>
      is_close_to_bottom = getCurrentCloseToBottomThreshold() <= $dropdown_menu.outerHeight() + $dropdown_menu.scrollTop()

      if is_close_to_bottom
        current_close_to_bottom_threshold = getCurrentCloseToBottomThreshold()

        if current_close_to_bottom_threshold > @last_close_to_bottom_threshold
          @last_close_to_bottom_threshold = current_close_to_bottom_threshold
          @increaseItemsRenderLimit()

      return

  return

Template.tasks_context_section.helpers
  hasNestedSections: -> @is_nested_section is true

  getNestedSections: (parent_section_id, nested_section_id) ->
    return APP.justdo_tasks_context_menu.getNestedSections parent_section_id, nested_section_id

  getSectionItems: ->
    tpl = Template.instance()

    section_items = @section.itemsSource()

    if tpl.isLimitRenderedItems()
      section_items = section_items.slice 0, tpl.items_render_limit_rv.get()

    return section_items

repositionEventMenu = (e) ->
  $item = $(e.target).closest(".context-nested-section-item")

  # Credit: https://stackoverflow.com/questions/18955334/collision-detection-in-bootstrap-dropdown
  $menu = $item.find(".dropdown-menu")
  if $menu != null and $menu.length == 1
    $menu.position
      of: $item
      my: "left top"
      at: "right top"
      collision: "flipfit"
      using: (new_position, details) =>
        target = details.target
        element = details.element

        element.element.css
          top: new_position.top - 8
          left: new_position.left

  return

Template.tasks_context_section.events
  "mouseenter .context-nested-section-item": (e) ->
    $("body").scrollTop(0)
    
    APP.justdo_tasks_context_menu.clearAndFocusFirstSectionFilterInMostNestedMenu()

    return

  "mouseenter .dropdown-item": (e) ->
    $item = $(e.target).closest(".dropdown-item")
    $parent = $item.parents ".context-nested-section-item"

    if not $parent.get(0)
      $menu = $item.find(".dropdown-menu")

      if $menu != null and $menu.length == 1
        repositionEventMenu(e)
        $(".dropdown-item.show-fix").removeClass "show-fix"
        $item.addClass "show-fix"

    return

  "mousemove .dropdown-item": (e, tpl) ->
    $item = $(e.target).closest(".dropdown-item")
    $parent = $item.parents ".context-nested-section-item"

    if not $parent.get(0)
      clearTimeout(tpl.moveTimer)
      tpl.moveTimer = setTimeout ->
        if not $item.hasClass "show-fix"
          $(".dropdown-item.show-fix").removeClass "show-fix"
      , 100

    return

  "mouseleave .dropdown-item": (e, tpl) ->
    clearTimeout(tpl.moveTimer)

    return

  "mouseover .context-nested-section-item": (e) -> repositionEventMenu(e)

  "click .context-nested-section-item": (e) ->
    if $(e.target).closest(".context-action-item").hasClass("context-nested-section-item")
      # Stop propagation to avoid closing the context-menu when the sub-menu item clicked (to be in-line with
      # common behaviour of UI).
      e.stopPropagation()

    return

  "click .context-action-item": (e) ->
    tpl = Template.instance()

    if not @close_on_click
      e.stopPropagation()

    if $(e.target).closest(".dropdown-menu").get(0) == $(e.delegateTarget).get(0) # This to ensure that when an item is clicked in a sub-menu the dom-encolsing parent menus events handlers won't trigger the op a second time
      if _.isFunction @op
        call_args = [@].concat(tpl.closestInstance("tasks_context_menu").tasks_context_menu_controller._sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator())
        return @op.apply(@, call_args)

        return

    return

  "keyup .section-filter": (e, tpl) ->
    tpl.resetItemsRenderLimit()

    filter_val = $(e.target).closest(".section-filter").val()

    APP.justdo_tasks_context_menu.setSectionFilterState(@id, filter_val)

    Tracker.flush() # To update UI for the new filter state

    repositionEventMenu(e)

    return

Template.tasks_context_menu_label_content.helpers
  getLabelValue: ->
    tpl = Template.instance()

    if _.isFunction @label
      call_args = [@].concat(tpl.closestInstance("tasks_context_menu").tasks_context_menu_controller._sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator())
      return @label.apply(@, call_args)

    if _.isString @label
      return @label

    return undefined

  getLabelAddendumDataContext: ->
    tpl = Template.instance()
    return [@].concat(tpl.closestInstance("tasks_context_menu").tasks_context_menu_controller._sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator())

Template.tasks_context_menu_icon.helpers
  getIconValValue: ->
    tpl = Template.instance()

    if _.isFunction @icon_val
      call_args = [@].concat(tpl.closestInstance("tasks_context_menu").tasks_context_menu_controller._sectionsAndItemsReactiveItemsListListingConditionCustomArgsGenerator())
      return @icon_val.apply(@, call_args)

    if _.isString @icon_val
      return @icon_val

    return undefined