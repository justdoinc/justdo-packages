APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  OwnerSetterManager = (grid_control) ->
    EventEmitter.call this

    @logger = Logger.get("owners-setter")

    @dropdown_calibration_needed = true

    @grid = grid_control

    @current_item_owners_management_node = null

    Meteor.defer =>
      @_init()

    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        @destroy()

  Util.inherits OwnerSetterManager, EventEmitter

  _.extend OwnerSetterManager.prototype,
    _init: ->
      dropdown_html = """
        <div class="dropdown owner-setter-dropdown">
          <div class="dropdown-menu owners-dropdown-menu"></div>
        </div>
      """

      @$dropdown =
        @grid.initGridBoundElement dropdown_html,
          container: $(".slick-viewport", @grid.container)
          positionUpdateHandler: ($connected_element) =>
            @updateDropdownPosition($connected_element)
          openedHandler: => @dropdownOpenedHandler()
          closedHandler: => @dropdownClosedHandler()
          close_button_html: null

      @grid.container.on "click", (e) ->
        # Avoid click event from reaching bootstrap's click handler for dropdowns
        e.stopPropagation()

      @grid.on "tree-control-user-image-clicked", => @ownerSetterClickHandler.apply(@, arguments)

      @position_update_interval = null

      return

    updatePosition: ->
      @$dropdown.data("updatePosition")()

      return

    ownerSetterClickHandler: (e, $clicked_element, item) ->
      e.stopPropagation()

      @$dropdown.data("item", item)

      @openDropdown(item._id, $clicked_element)

    openDropdown: (item_id, $connected_element) ->
      @dropdown_calibration_needed = true
      @$dropdown.data("open")(item_id, $connected_element)

    closeDropdown: ->
      @$dropdown.data("close")()

    lockGridData: -> @grid._grid_data._lock()

    releaseGridData: -> @grid._grid_data._release()

    dropdownOpenedHandler: ->
      @lockGridData()

      item = @$dropdown.data("item")

      if @current_item_owners_management_node?
        @current_item_owners_management_node.destroy()

      @current_item_owners_management_node = 
        APP.helpers.renderTemplateInNewNode("item_owners_management", item)

      $(".dropdown-menu", @$dropdown).html @current_item_owners_management_node.node

      @position_update_interval = setInterval =>
        @updatePosition()
      , 100

      return

    dropdownClosedHandler: ->
      # style removal is here to fix an issue with IE11 that doesn't
      # position correctly the dropdown after consecutive opening without
      # clearing the previous state style.
      $(".owner-setter-dropdown").removeAttr("style")

      @releaseGridData()

      @clearPositionUpdateInterval()

      return

    clearPositionUpdateInterval: ->
      if @position_update_interval?
        clearInterval @position_update_interval

      return

    updateDropdownPosition: ($connected_element) ->
      max_owner_dropdown_height = 300
      ownership_avatar_height = 33

      # The task in the middle need to have enough space below it/above it + the size of the avatar
      if $(".slick-viewport", @grid.container).height() < (max_owner_dropdown_height + ownership_avatar_height)
        collision_type = "fit"
      else
        collision_type = "flip"

      @$dropdown
        .position
          of: $connected_element
          my: "left top"
          at: "left bottom"
          collision: "none #{collision_type}"
          using: (new_position, details) =>
            target = details.target
            element = details.element

            if target.left < 0
              # If connected_element isn't visible anymore close dropdown
              @closeDropdown()

              return

            top_offset = 0
            if collision_type == "flip"
              if details.vertical == "bottom"
                # flipped
                top_offset = -3
              else
                # regular
                top_offset = 0

            element.element.css
              top: new_position.top + top_offset
              left: new_position.left

      if @dropdown_calibration_needed
        # In some browsers (all?) the first time we show the dropdown
        # updateDropdownPosition need to call twice to show in its correct
        # location
        @dropdown_calibration_needed = false
        @updateDropdownPosition($connected_element)

    destroy: ->
      # Might be called more than once
      if @current_item_owners_management_node?
        @current_item_owners_management_node.destroy()

      @clearPositionUpdateInterval()

      @grid = null # just to reduce risk of GC missing this one

  module.OwnerSetterManager = OwnerSetterManager

  getEventDropdownData = (e, data_label) ->
    $(e.target).closest(".dropdown").data(data_label)

  Template.item_owners_management.onCreated ->
    @state = new ReactiveVar "base"
    @current_members_filter = new ReactiveVar null

  Template.item_owners_management.onRendered ->
    if ($members_search_input = $(".members-search-input")).length > 0
      $members_search_input.focus()

    return

  Template.item_owners_management.events
    "click .manage-members": (e, template) ->
      task_id = template.data._id

      getEventDropdownData(e, "close")()

      ProjectPageDialogs.members_management_dialog.open(task_id)

      return

    "keyup .members-search-input": (e, template) ->
      value = $(e.target).val().trim()

      if _.isEmpty value
        return template.current_members_filter.set(null)
      else
        template.current_members_filter.set(value)

      return

    "click .new-owner-option": (e, template) ->
      new_owner_doc = @
      item_doc = template.data

      if new_owner_doc._id == Meteor.userId()
        APP.collections.Tasks.update item_doc._id,
          $set:
            owner_id: new_owner_doc._id
            pending_owner_id: null
      else
        APP.collections.Tasks.update item_doc._id,
          $set:
            owner_id: Meteor.userId() # The one that request the transfer become the owner
            pending_owner_id: new_owner_doc._id

      getEventDropdownData(e, "close")()

    "click .cancel-transfer": (e, template) ->
      item_doc = template.data

      if (reject_message = template.$("textarea").val())?
        # Reject transfer - (reject message text area is our indicator)
        APP.projects.modules.owners.rejectOwnershipTransfer(item_doc._id, reject_message)
      else
        # Cancel transfer
        doc_updates = 
          $set:
            owner_id: item_doc.owner_id
            pending_owner_id: null

        APP.collections.Tasks.update item_doc._id, doc_updates

      getEventDropdownData(e, "close")()

    "click .pre-reject-button": (e, tpl) ->
      tpl.state.set("pre-reject")

      return

    "click .cancel-reject-button": (e, tpl) ->
      tpl.state.set("base")

      return

    "click .take-ownership": (e, template) ->
      item_doc = template.data

      APP.collections.Tasks.update item_doc._id,
        $set:
          owner_id: Meteor.userId()
          pending_owner_id: null

      getEventDropdownData(e, "close")()

    "click .approve-transfer": (e, template) ->
      item_doc = template.data

      APP.collections.Tasks.update item_doc._id,
        $set:
          owner_id: Meteor.userId()
          pending_owner_id: null

      getEventDropdownData(e, "close")()

  currentTaskMembersIdsOtherThanMe = ->
    if not (users = module.activeItemObjFromCollection({users: 1})?.users)?
      module.logger.warn "Can't find the active task users"

      return null

    return _.without users, Meteor.userId()

  currentTaskMembersDocsOtherThanMe = ->
    return JustdoHelpers.getUsersDocsByIds(currentTaskMembersIdsOtherThanMe())

  Template.item_owners_management.helpers
    getState: ->
      tpl = Template.instance()

      return tpl.state.get()

    taskHasOtherMembers: ->
      return not _.isEmpty currentTaskMembersIdsOtherThanMe()

    taskMembersOtherThanMeMatchingFilter: ->
      tpl = Template.instance()

      current_members_filter = tpl.current_members_filter.get()

      task_members = currentTaskMembersDocsOtherThanMe()

      task_members_docs = JustdoHelpers.filterUsersDocsArray(task_members, current_members_filter)

      return _.sortBy task_members_docs, (member) -> JustdoHelpers.displayName(member)

  Template.item_owners_management_reject_transfer_request_input.onRendered ->
    $textarea = @$("textarea")

    $textarea.focus()

    $textarea.autosize()

    return
