APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

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
          <div class="dropdown-menu owners-dropdown-menu border-0 shadow-lg"></div>
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

      @grid.on "tree-control-user-image-clicked", (...args) => @ownerSetterClickHandler.apply(@, args)

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
          my: "#{APP.justdo_i18n.getRtlAwareDirection "left"} top"
          at: "#{APP.justdo_i18n.getRtlAwareDirection "left"} bottom"
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

  project_page_module.OwnerSetterManager = OwnerSetterManager

  getEventDropdownData = (e, data_label) ->
    $(e.target).closest(".dropdown").data(data_label)

  currentTaskMembersIdsOtherThanMe = ->
    tpl = Template.instance()

    if not (users = JD.activeItemUsers())?
      project_page_module.logger.warn "Can't find the active task users"

      return null

    return _.without users, Meteor.userId()

  currentTaskMembersDocsOtherThanMe = ->
    return JustdoHelpers.getUsersDocsByIds(currentTaskMembersIdsOtherThanMe())

  Template.item_owners_management.onCreated ->
    @state = new ReactiveVar "base"
    @current_members_filter = new ReactiveVar null
    @task_has_other_members_rv = new ReactiveVar false

    @takeOwnership = (e) ->
      item_doc = @data

      APP.projects.modules.owners.takeOwnership(item_doc._id, Meteor.userId())
      getEventDropdownData(e, "close")()

      return

    @autorun =>
      @task_has_other_members_rv.set "loading"
      JD.subscribeItemsAugmentedFields JD.activeItemId(), ["users"], {}, =>
        Meteor.defer => # Meteor.defer is used to ensure Tracker.flush() won't be called in the autorun tick.
          if _.isEmpty currentTaskMembersIdsOtherThanMe()
            @task_has_other_members_rv.set "no"
          else
            @task_has_other_members_rv.set "yes"
            Tracker.flush()
            @$(".members-search-input").focus()

          return 
    
    return

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

      if APP.accounts.isProxyUser(new_owner_doc)
        # Tasks are transferred to proxy users directly
        APP.projects.modules.owners.takeOwnership(item_doc._id, new_owner_doc._id)
      else
        modifier =
          $set:
            owner_id: Meteor.userId() # The one that request the transfer becomes the owner
            is_removed_owner: null
            pending_owner_id: new_owner_doc._id
        APP.collections.Tasks.update item_doc._id, modifier

      # if there are relevant child tasks:
      item_has_child_query = 
        "parents.#{item_doc._id}": 
          $ne: null
        users: new_owner_doc._id
      item_has_child = APP.collections.Tasks.findOne(item_has_child_query, {fields: {_id: 1}})?

      showChildTasksTransferredSnackbar = (affected_task_ids) ->
        JustdoSnackbar.show
          text: TAPi18n.__ "owners_mgmt_transfer_child_tasks_done", {count: affected_task_ids.length}
          actionText: TAPi18n.__ "undo"
          duration: 10000
          showDismissButton: true
          onActionClick: =>
            APP.projects.modules.owners.undoTransferChildTasks(item_doc._id, affected_task_ids, new_owner_doc._id)
            JustdoSnackbar.close()
            return

        return

      if item_has_child?
        JustdoSnackbar.show
          text: TAPi18n.__ "owners_mgmt_transfer_child_tasks_too"
          showDismissButton: true
          actionText: TAPi18n.__ "owners_mgmt_transfer_my_child_tasks"
          onActionClick: =>
            transfer_child_tasks_options = 
              limit_owners: Meteor.userId()
              new_owner_id: new_owner_doc._id

            affected_task_ids = APP.projects.modules.owners.transferChildTasks item_doc._id, transfer_child_tasks_options

            showChildTasksTransferredSnackbar(affected_task_ids)

            return
          showSecondButton: true
          secondButtonText: TAPi18n.__ "owners_mgmt_transfer_all_child_tasks"
          onSecondButtonClick: =>
            transfer_child_tasks_options = 
              limit_owners: null
              new_owner_id: new_owner_doc._id

            affected_task_ids = APP.projects.modules.owners.transferChildTasks item_doc._id, transfer_child_tasks_options

            showChildTasksTransferredSnackbar(affected_task_ids)

            return
      
      getEventDropdownData(e, "close")()

      return

    "click .cancel-transfer": (e, template) ->
      item_doc = template.data

      if (reject_message = template.$("textarea").val())?
        # Reject transfer - (reject message text area is our indicator)
        APP.projects.modules.owners.rejectOwnershipTransfer(item_doc._id, reject_message)
      else
        # Cancel transfer
        APP.projects.modules.owners.takeOwnership(item_doc._id, item_doc.owner_id)

      getEventDropdownData(e, "close")()

    "click .pre-reject-button": (e, tpl) ->
      tpl.state.set("pre-reject")

      return

    "click .cancel-reject-button": (e, tpl) ->
      tpl.state.set("base")

      return

    "click .approve-transfer": (e, template) ->
      template.takeOwnership(e)

      return
    
    "click .take-ownership": (e, template) ->
      item_doc = template.data
      item_owner_doc = JustdoHelpers.getUserDocById(item_doc.owner_id)

      template.takeOwnership(e)
      
      JustdoSnackbar.show
        text: TAPi18n.__ "owners_mgmt_transfer_take_child_tasks_too"
        showDismissButton: true
        actionText: TAPi18n.__ "owners_mgmt_transfer_child_tasks_owned_by", {name: JustdoHelpers.displayName(item_owner_doc)}
        onActionClick: =>
          transfer_child_tasks_options = 
            limit_owners: item_owner_doc._id
            new_owner_id: Meteor.userId()
          APP.projects.modules.owners.transferChildTasks item_doc._id, transfer_child_tasks_options

          JustdoSnackbar.close()

          return
        showSecondButton: true
        secondButtonText: TAPi18n.__ "owners_mgmt_transfer_all_child_tasks"
        onSecondButtonClick: =>
          transfer_child_tasks_options = 
            new_owner_id: Meteor.userId()
          APP.projects.modules.owners.transferChildTasks item_doc._id, transfer_child_tasks_options

          JustdoSnackbar.close()

          return
      
      return

    "keydown .ownership-transfer-dialog" : (e) ->
      $el = $(e.target).closest(".ownership-dialog-item")
      el_index = $(".ownership-dialog-item").index($el)

      if e.keyCode == 38 and $(".ownership-dialog-item")[el_index - 1]
        e.preventDefault()
        $(".ownership-dialog-item")[el_index - 1].focus()

      if e.keyCode == 40 and $(".ownership-dialog-item")[el_index + 1]
        e.preventDefault()
        $(".ownership-dialog-item")[el_index + 1].focus()

      if e.keyCode == 13
        $el.click()

      return

  Template.item_owners_management.helpers
    hasPermissionToEditMemebers: ->
      if (item_id = JD.activeItemId())?
        return APP.justdo_permissions?.checkTaskPermissions("task-field-edit.users",item_id)
      return false
    
    getState: ->
      tpl = Template.instance()

      return tpl.state.get()

    taskHasOtherMembers: ->
      return Template.instance().task_has_other_members_rv.get()

    taskMembersOtherThanMeMatchingFilter: ->
      tpl = Template.instance()

      current_members_filter = tpl.current_members_filter.get()

      task_members = currentTaskMembersDocsOtherThanMe()

      task_members_docs = JustdoHelpers.filterUsersDocsArray(task_members, current_members_filter)

      return task_members_docs

  Template.item_owners_management_reject_transfer_request_input.onRendered ->
    $textarea = @$("textarea")

    $textarea.focus()

    $textarea.autosize()

    return

  Template.item_owners_management_reject_transfer_request_input.events
    "keydown .reject-message-input": (e) ->
      if (e.metaKey || e.ctrlKey) && e.keyCode == 13
        $(".cancel-transfer").click()

      return
