system_minimal_seq_id_space_on_grid = 3

time_description_last_read_introduced_time_stamp = +(new Date(Date.UTC(2020, 7, 14, 0, 0, 0, 0))) # Descriptions edited before or on that time will always be regarded as read

getHeighestSeqId = ->
  # Returns seqId of the item with the highest sequence id under @collection
  # has, or undefined, if no item, or no item with sequence id exists.
  #
  # If APP.modules.project_page.curProj() exists, we limit the search
  # for the heighest sequence id to the current project only.
  #
  # Reactive resource
  #
  # Must be called with @ set to the current GridControl object.

  query = 
    seqId:
      $ne: null

  if (current_project_id = APP?.modules?.project_page?.curProj?())?
    # Not the most "pure" programming style to include a reference
    # to APP.modules.project_page.curProj() here, but the code doesn't
    # depend on it so that's a reasonable compromise with minimal
    # technical debt -Daniel
    query.project_id = current_project_id.id

  # Turned out to be too slow approach since minimongo with sort results in
  # 100s of ms computations
  # highest_seq_id_doc = @collection.findOne(query, {fields: {seqId: 1}, sort: {seqId: -1}})
  #
  # if not highest_seq_id_doc?
  #   return undefined
  #
  # return highest_seq_id_doc.seqId

  # This approach will work only in environments with JustDo enabled
  highest_seq_id = APP?.modules?.project_page?.curProj()?.getProjectDoc({fields: {lastTaskSeqId: 1}})?.lastTaskSeqId

  return highest_seq_id

getIsDeliveryPlannerPluginEnabled = ->
  # return APP?.modules?.project_page?.curProj()?.isCustomFeatureEnabled("justdo_delivery_planner")
  return true # In Jul 2nd 2020 projects became a built-in feature

getIsTimeTrackerPluginEnabled = ->
  # The time tracker plugin needs both itself installed, and the resource manager as dependency
  return APP?.modules?.project_page?.curProj()?.isCustomFeatureEnabled(JustdoTimeTracker?.project_custom_feature_id) and APP?.modules?.project_page?.curProj()?.isCustomFeatureEnabled(JustdoResourcePlanner?.project_custom_feature_id)

getIsResourcePlannerPluginEnabled = ->
  # The time tracker plugin needs both itself installed, and the resource manager as dependency
  return APP?.modules?.project_page?.curProj()?.isCustomFeatureEnabled(JustdoResourcePlanner?.project_custom_feature_id)

getIsChecklistPluginEnabled = ->
  if not JustdoChecklist?.project_custom_feature_id?
    return false

  return APP?.modules?.project_page?.curProj()?.isCustomFeatureEnabled(JustdoChecklist?.project_custom_feature_id)

getIsMeetingsPluginEnabled = ->
  custom_features = APP?.modules?.project_page?.curProj()?.getProjectConfiguration()?.custom_features

  return custom_features.indexOf("meetings_module") > -1

getMinimalSeqIdSpace = ->
  # Returns the maximum between 3 and the the digits count of the item
  # returned from getHeighestSeqId.
  #
  # Reactive resource
  #
  # Must be called with @ set to the current GridControl object. 

  current_heighest_seq_id = getHeighestSeqId.call(@)

  if current_heighest_seq_id?
    current_heighest_seq_id_space = ("" + current_heighest_seq_id).length
  else
    current_heighest_seq_id_space = 0

  return Math.max(system_minimal_seq_id_space_on_grid, current_heighest_seq_id_space)

GridControl.installFormatter "textWithTreeControls",
  is_slick_grid_tree_control_formatter: true

  # gridControlInit: ->
  #   Defined in text_with_tree_controls-events.coffee

  # slick_grid_jquery_events:
  #   Defined in text_with_tree_controls-events.coffee

  slickGridColumnStateMaintainer: ->
    if not Tracker.active
      @logger.warn "slickGridColumnStateMaintainer: called outside of computation, skipping"

      return

    # Create a dependency and depend on it.
    dep = new Tracker.Dependency()
    dep.depend()

    highest_seqId_computation = null
    is_delivery_planner_plugin_enabled_computation = null
    is_justdo_planning_utilities_plugin_enabled_computation = null
    is_time_tracker_plugin_enabled_computation = null
    is_resource_planner_plugin_enabled_computation = null
    is_checklist_plugin_enabled_computation = null
    is_meetings_plugin_enabled_computation = null

    Tracker.nonreactive =>
      # Run in an isolated reactivity scope
      highest_seqId_computation = Tracker.autorun =>
        current_val = getMinimalSeqIdSpace.call(@) # Reactive
        cached_val = @getCurrentColumnData("minimal_seq_id_space") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("minimal_seq_id_space", current_val)

          dep.changed()

        return

      is_delivery_planner_plugin_enabled_computation = Tracker.autorun =>
        current_val = getIsDeliveryPlannerPluginEnabled.call(@) # Reactive
        cached_val = @getCurrentColumnData("delivery_planner_plugin_enabled") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("delivery_planner_plugin_enabled", current_val)

          dep.changed()

        return

      is_justdo_planning_utilities_plugin_enabled_computation = Tracker.autorun =>
        current_val = APP.justdo_planning_utilities.isPluginInstalledOnJustdo JD.activeJustdoId() # Reactive
        cached_val = @getCurrentColumnData("justdo_planning_utilities_plugin_enabled") # non reactive
        if current_val != cached_val
          @setCurrentColumnData("justdo_planning_utilities_plugin_enabled", current_val)
          dep.changed()

        return

      is_time_tracker_plugin_enabled_computation = Tracker.autorun =>
        current_val = getIsTimeTrackerPluginEnabled.call(@) # Reactive
        cached_val = @getCurrentColumnData("time_tracker_plugin_enabled") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("time_tracker_plugin_enabled", current_val)

          dep.changed()

        return

      is_resource_planner_plugin_enabled_computation = Tracker.autorun =>
        current_val = getIsResourcePlannerPluginEnabled.call(@) # Reactive
        cached_val = @getCurrentColumnData("resource_planner_plugin_enabled") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("resource_planner_plugin_enabled", current_val)

          dep.changed()

        return

      is_checklist_plugin_enabled_computation = Tracker.autorun =>
        current_val = getIsChecklistPluginEnabled.call(@) # Reactive
        cached_val = @getCurrentColumnData("checklist_plugin_enabled") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("checklist_plugin_enabled", current_val)

          dep.changed()

        return

      is_meetings_plugin_enabled_computation = Tracker.autorun =>
        current_val = getIsMeetingsPluginEnabled.call(@) # Reactive
        cached_val = @getCurrentColumnData("meetings_plugin_enabled") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("meetings_plugin_enabled", current_val)

          dep.changed()

        return

    Tracker.onInvalidate ->
      highest_seqId_computation.stop()
      is_delivery_planner_plugin_enabled_computation.stop()
      is_justdo_planning_utilities_plugin_enabled_computation.stop()
      is_time_tracker_plugin_enabled_computation.stop()
      is_resource_planner_plugin_enabled_computation.stop()
      is_checklist_plugin_enabled_computation.stop()
      is_meetings_plugin_enabled_computation.stop()

      return

    return
    

  slick_grid: ->
    {row, cell, value, doc, self, path} = @getFriendlyArgs()

    level = @_grid_data.getItemLevel row
    expand_state = @_grid_data.getItemExpandState row

    state = ""
    svg_icon_name = ""
    if expand_state == 1
      state = "expand"
      svg_icon_name = "minus"
    else if expand_state == 0
      state = "_collapse" # .collapse is part of the bs4 framework, hence, we can't use the same name.
      svg_icon_name = "plus"
    else if expand_state == -1
      svg_icon_name = "minus"

    if not value?
      value = ""

    value = self.xssGuard value

    value = linkifyHtml value,
      nl2br: @options.allow_dynamic_row_height
      linkClass: "jd-underline font-weight-bold text-body"

    current_left_pos = 0
    horizontal_padding = 3

    current_left_pos += horizontal_padding

    tree_control = ""

    if doc.priority?
      priority_width = 6 + 3 # (3 for right outline)

      priority_indentation = current_left_pos

      # We keep outside the grid-formatter container due to positioning needs (need it relative to the
      # .slick-dynamic-row-height .slick-cell for correct height)
      tree_control += """
        <div class="grid-tree-control-priority slick-prevent-edit"
             style="background-color: #{JustdoColorGradient.getColorRgbString(doc.priority or 0)}; left: #{priority_indentation}px;"></div>
      """

      current_left_pos += priority_width

    toggle_margin_left = 0
    toggle_width = 21
    toggle_margin_right = 0

    level_indent = 15
    indentation_margin = (level_indent * level)
    toggle_indentation = current_left_pos + toggle_margin_left + indentation_margin

    tree_control += """
      <div class="grid-formatter text-tree-control">
    """

    tree_control += """
      <div class="grid-tree-control-toggle slick-prevent-edit #{state}"
           style="left: #{toggle_indentation}px;">
           <svg><use xlink:href="/layout/icons-feather-sprite.svg##{svg_icon_name}"></use></svg>
      </div>
    """

    current_left_pos += indentation_margin + toggle_margin_left + toggle_width + toggle_margin_right

    # item icons
    tree_control += """
      <div class="grid-tree-control-item-icons">
    """

    if @getCurrentColumnData("time_tracker_plugin_enabled") and not doc._type?
      if doc[JustdoTimeTracker?.running_task_private_field_id]?
        tree_control += """
            <i class="fa fa-fw fa-stop-circle-o jdt-stop jdt-grid-icon slick-prevent-edit" title="You are working on this task now, press to stop and log the time worked" aria-hidden="true"></i>
        """
      else
        tree_control += """
            <i class="fa fa-fw fa-play-circle-o jdt-play jdt-grid-icon slick-prevent-edit" title="Start working on this task" aria-hidden="true"></i>
        """

    if @getCurrentColumnData("meetings_plugin_enabled") and not doc._type?
      if doc[MeetingsManagerPlugin.task_meetings_cache_field_id]?
        meeting_ids = new Set(doc[MeetingsManagerPlugin.task_meetings_cache_field_id])

        if meeting_ids.size > 0
          tree_control += """
            <svg class="task-meetings slick-prevent-edit jd-c-pointer text-dark">
              <title>Meetings</title>
              <use xlink:href="/layout/icons-feather-sprite.svg#jd-meetings" class="slick-prevent-edit"></use>
            </svg>"""

    if @getCurrentColumnData("justdo_planning_utilities_plugin_enabled")
      if doc[JustdoPlanningUtilities?.is_milestone_pseudo_field_id] == "true"
        tree_control +=  """
          <svg class="jd-icon ongrid-jd-icon text-secondary slick-prevent-edit">
            <title>Gantt Milestone</title>
            <use xlink:href="/layout/icons-feather-sprite.svg#jd-rhombus" class="slick-prevent-edit"></use>
          </svg>
        """

      if doc[JustdoPlanningUtilities?.is_buffer_task_field_id]
        tree_control +=  """
          <svg class="jd-icon ongrid-jd-icon text-secondary slick-prevent-edit" style="margin-right:2px; fill:black;">
            <title>Buffer Task</title>
            <use xlink:href="/layout/icons-feather-sprite.svg#jd-buffer-set" class="slick-prevent-edit"></use>
          </svg>
        """

    if @getCurrentColumnData("resource_planner_plugin_enabled") and not doc._type?
      user_has_planned_hours_for_the_task =
        doc["p:rp:b:work-hours_p:b:user:#{Meteor.userId()}"]? and
        doc["p:rp:b:work-hours_p:b:user:#{Meteor.userId()}"] > 0

      user_has_executed_hours_for_the_task =
        doc["p:rp:b:work-hours_e:b:user:#{Meteor.userId()}"]? and
        doc["p:rp:b:work-hours_e:b:user:#{Meteor.userId()}"] > 0

      task_has_unassigned_hours =
        doc["p:rp:b:unassigned-work-hours"]? and
        doc["p:rp:b:unassigned-work-hours"] > 0

      task_has_planned_hours = doc["p:rp:b:work-hours_p"]? and doc["p:rp:b:work-hours_p"] > 0
      task_has_executed_hours = doc["p:rp:b:work-hours_e"]? and doc["p:rp:b:work-hours_e"] > 0

      if user_has_planned_hours_for_the_task or user_has_executed_hours_for_the_task or
         task_has_unassigned_hours or
         task_has_planned_hours or task_has_executed_hours
        if user_has_planned_hours_for_the_task or user_has_executed_hours_for_the_task
          resource_planner_classes = "task-planned-or-executed-by-current-user"
        else
          resource_planner_classes = ""

        tree_control += """
            <i class="fa fa-fw resource_planner fa-tasks #{resource_planner_classes} slick-prevent-edit" title="Resources" aria-hidden="true"></i>
        """

    if (description_last_update = doc[Projects.tasks_description_last_update_field_id])?
      # Mark as unread if I read the description after its last update time
      if +description_last_update > time_description_last_read_introduced_time_stamp
        if (doc[Projects.tasks_description_last_read_field_id] or 0) < description_last_update
          description_classes = "description-new-updates"
        else
          description_classes = ""

      tree_control += """
          <i class="fa fa-fw #{description_classes} fa-align-left task-description slick-prevent-edit" title="Task description" aria-hidden="true"></i>
      """

    if (last_message_date = doc[JustdoChat.tasks_chat_channel_last_message_date_field_id])?
      # Mark as unread if last message isn't from me, and I never read the messages in this channel,
      # or, didn't read yet.
      if doc[JustdoChat.tasks_chat_channel_last_message_from_field_id] != Meteor.userId() and
         (not (last_read = doc[JustdoChat.tasks_chat_channel_last_read_field_id])? or last_message_date > last_read)
        chat_classes = "fa-comments chat-messages-new"
      else
        chat_classes = "fa-comments-o"

      tree_control += """
          <i class="fa fa-fw chat-messages #{chat_classes} slick-prevent-edit" title="Chat messages" aria-hidden="true"></i>
      """

    if (files = doc.files)?
      if files.length > 0
        tree_control += """
            <i class="fa fa-fw fa-paperclip task-files slick-prevent-edit" title="#{files.length} files" aria-hidden="true"></i>
        """

    if (justdo_files_count = doc[JustdoFiles.files_count_task_doc_field_id])?
      justdo_files_count = parseInt(justdo_files_count, 10) # Don't open an XSS chance.
      if justdo_files_count > 0
        tree_control += """
            <i class="fa fa-fw fa-paperclip justdo-files slick-prevent-edit" title="#{justdo_files_count} files" aria-hidden="true"></i>
        """

    if @getCurrentColumnData("delivery_planner_plugin_enabled")
      if (is_project = doc["p:dp:is_project"])?
        is_archived_project = doc["p:dp:is_archived_project"]
        
        if is_project
          tree_control += """
              <i class="fa fa-fw fa-briefcase task-is-project #{if is_archived_project then "task-is-archived-project" else ""} slick-prevent-edit" title="Task is a project" aria-hidden="true"></i>
          """

    if @getCurrentColumnData("checklist_plugin_enabled") and not doc._type?
      tree_control += APP.justdo_checklist.getOnGridCheckMarkHtml(doc, path)

    tree_control += """
      <svg class="jd-icon jd-icon-context-menu ongrid-jd-icon jd-c-pointer text-secondary slick-prevent-edit">
        <use xlink:href="/layout/icons-feather-sprite.svg#more-vertical" class="slick-prevent-edit"></use>
      </svg>
    """

    tree_control += """
      </div>
    """

    index = null
    if doc.seqId? and not doc._omit_seqId_comp
      index = doc.seqId # Note we don't worry about reactivity -> seqId considered static.
    # else
    #   index = getRandomArbitrary(0, 10000) # getRandomArbitrary = (min, max) -> Math.floor(Math.random() * (max - min) + min)

    # We can't tell for sure whether slickGridColumnStateMaintainer is the
    # only one to affect the column cache, therefore, we don't rely on it
    # to set the value for us. We set the value ourself if we don't find one.
    if not (minimal_seq_id_space = @getCurrentColumnData("minimal_seq_id_space"))?
      minimal_seq_id_space = Tracker.nonreactive => getMinimalSeqIdSpace.call(@)
      @setCurrentColumnData("minimal_seq_id_space", minimal_seq_id_space)

    if index?
      index_width_per_char = 8.2

      # minimal_seq_id_space won't be accurate in environment without JustDo
      # projects, in such cases, we need to fallback to current cell seqId
      # length
      index_chars = Math.max(minimal_seq_id_space, ("" + index).length)   

      index_width = Math.ceil(index_chars * index_width_per_char)
      index_horizontal_paddings = 6 * 2
      # Note: index label is box-sizing: content-box
      index_outer_width = index_width + index_horizontal_paddings
      index_margin_right = 3
      index_left = current_left_pos

      tree_control += """
        <span class="label label-primary grid-tree-control-task-id slick-prevent-edit cell-handle"
               style="left: #{index_left}px;
                      width: #{index_width}px;" jd-tt="task-info?id=#{doc._id}">
          #{index}
      """

      if doc["priv:favorite"]?
        tree_control += """
          <div class="grid-tree-control-task-favorite">
            <svg><use xlink:href="/layout/icons-feather-sprite.svg#star"></use></svg>
          </div>
        """

      tree_control += """
        </span>
      """


      current_left_pos += index_outer_width + index_margin_right

    # shortcuts
    owner_id = pending_owner_id = null
    if doc.owner_id? and not doc._omit_owner_control
      owner_id = doc.owner_id # For reactivity, make sure to specify owner_id and pending_owner_id as
                               # dependencies
      pending_owner_id = doc.pending_owner_id

    if owner_id?
      doc = @_grid_data.extendObjForeignKeys doc,
        in_place: false
        foreign_keys: ["owner_id"]

      owner_doc = doc.owner

      if owner_doc?
        owner_display_name = JustdoHelpers.xssGuard(owner_doc?.profile?.first_name + " " + owner_doc?.profile?.last_name)

      owner_id_width = 28
      owner_id_margin_right = 0
      owner_id_left = 1 + current_left_pos
      current_left_pos += owner_id_width + owner_id_margin_right

      title = owner_display_name
      if pending_owner_id?
        doc = @_grid_data.extendObjForeignKeys doc,
          in_place: false
          foreign_keys: ["pending_owner_id"]

        pending_owner_doc = doc.pending_owner

        if pending_owner_doc?
          pending_owner_display_name = JustdoHelpers.xssGuard(pending_owner_doc?.profile?.first_name + " " + pending_owner_doc?.profile?.last_name)

        title += " &rarr; " + pending_owner_display_name

      if doc.is_removed_owner is true
        title += " - the task owner is no longer a member of this task"

      tree_control += """
        <div class="grid-tree-control-user slick-prevent-edit"
             title="#{title}"
             style="left: #{owner_id_left}px;
                    width: #{owner_id_width}px;
                    height: #{owner_id_width}px;">
          <img src="#{JustdoAvatar.showUserAvatarOrFallback(owner_doc)}"
               class="grid-tree-control-user-img slick-prevent-edit"
               alt="#{owner_display_name}"
               style="left: #{owner_id_left}px;
                      width: #{owner_id_width}px;
                      height: #{owner_id_width}px;">
      """

      if pending_owner_id? or doc.is_removed_owner is true
        if doc.is_removed_owner is true
          sprite_icon = "jd-alert"
          transfer_type = "transfer-no-owner"
        else
          sprite_icon = "arrow-right"
          transfer_type = "transfer-non-related"
          if Meteor.userId() == pending_owner_id
            transfer_type = "transfer-to-me"
          else if Meteor.userId() == owner_id
            transfer_type = "transfer-from-me"

        tree_control += """
          <div class="transfer-owner #{transfer_type} slick-prevent-edit">
            <svg><use xlink:href="/layout/icons-feather-sprite.svg##{sprite_icon}"></use></svg>
          </div>
        """

      tree_control += """
        </div>
      """

    text_left_margin = current_left_pos

    tree_control += """
        <div class="grid-tree-control-text" dir="auto"
              style="margin-left: #{text_left_margin}px;">#{value}</div>
    """

    tree_control += """
      </div>
    """

    # We keep outside the grid-formatter container due to positioning needs (need it relative to the
    # .slick-dynamic-row-height .slick-cell for correct height)
    tree_control += """
      <div class="grid-tree-control-activation-area slick-prevent-edit"
               style="width: #{toggle_indentation}px;"></div>
    """

    if state is "expand"
      tree_control += """
        <div class="hl hl-f" style="left: #{level_indent * (level + 1) + 4}px"></div>
      """

    if level > 0
      for i in [1..level]
        tree_control += """
          <div class="hl" style="left: #{level_indent * i + 4}px"></div>
        """

    return tree_control

  print: (doc, field, path) ->
    return @defaultPrintFormatter()
