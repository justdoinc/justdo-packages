mainGridControl = -> APP.modules.project_page.mainGridControl()

human_readable_workdays_names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

raw_data_moment_format = "YYYY-MM-DD"

normalizeUserPreferenceDateFormatAndFormatToUnicodeDateString = (user_format_date_string) ->
  if not user_format_date_string? or user_format_date_string == ""
    return ""

  return moment(user_format_date_string, raw_data_moment_format).format(JustdoHelpers.getUserPreferredDateFormat())

APP.executeAfterAppLibCode ->
  _.extend JustdoDeliveryPlanner.prototype,
    tab_changes_dependency: new Tracker.Dependency()

    amplify_selected_resources_tab_key: "dpSelectedResourcesTab"

    default_tab: "project"

    taskPaneSectionGetCurrentTab: ->
      @tab_changes_dependency.depend()

      return if (selected_tab = amplify.store @amplify_selected_resources_tab_key)? then selected_tab else @default_tab

    taskPaneSectionSetCurrentTab: (tab_id) ->
      amplify.store @amplify_selected_resources_tab_key, tab_id

      @tab_changes_dependency.changed()

      return

    _initMembersAvailabilityProxy: _.once (self) ->
      self._members_availability_proxy_dep = new Tracker.Dependency()

      return

    initMembersAvailabilityProxy: ->
      @_initMembersAvailabilityProxy(@)

      @_members_availability_proxy = {}
      @_members_availability_proxy_dep.changed()

      return

    reloadMembersAvailabilityProxy: ->
      self = @

      members_availability_proxy =
        members: []

        changed: new ReactiveVar(false)

        save: ->
          if (active_item_obj = Tracker.nonreactive -> APP.modules.project_page.activeItemObj(devPlanner()._getProjectRelevantFieldsProjection()))?
            existing_members_availability = active_item_obj[JustdoDeliveryPlanner.task_project_members_availability_field_name]

          new_members_availability = existing_members_availability.slice()

          for member in @members
            member_obj =
              user_id: member.user_id

              availability_type: member.getAvailabilityType()

              # Always keep the simple value
              simple_daily_availability: member.getSimpleDailyAvailability()

            if member_obj.availability_type != "simple"
              member_obj.extended_daily_availability = member.getExtendedDailyAvailability()
              member_obj.extended_daysoff_ranges = member.getExtendedDaysoffRanges()

            existing_index = null
            for existing_member, index in existing_members_availability
              if existing_member.user_id == member_obj.user_id
                existing_index = index

            if existing_index?
              new_members_availability[existing_index] = member_obj
            else
              # I don't think this should ever happen...
              new_members_availability.push(member_obj)

          if (active_item_id = module.activeItemId())?
            self.tasks_collection.update active_item_id, {$set: {"#{JustdoDeliveryPlanner.task_project_members_availability_field_name}": new_members_availability}}, (err) =>
              if not err?
                members_availability_proxy.changed.set false

              return

          return 

      # Updates to the members list should be triggered by the refresh button, and not as
      # a result of changes to the underlying data (as we don't want to interfere user editing).
      if (active_item_obj = Tracker.nonreactive -> APP.modules.project_page.activeItemObj(devPlanner()._getProjectRelevantFieldsProjection()))?
        members_availability = active_item_obj[JustdoDeliveryPlanner.task_project_members_availability_field_name]

        project_base_workdays = active_item_obj[JustdoDeliveryPlanner.task_base_project_workdays_field_name]
        default_extended_daily_availability = _.map project_base_workdays, (is_enable) -> is_enable * JustdoDeliveryPlanner.default_simple_member_daily_availability_seconds

        for member in members_availability
          member_controller =
            user_id: member.user_id

            user_doc: Tracker.nonreactive -> Meteor.users.findOne(member.user_id)

            _availability_type: new ReactiveVar(member.availability_type)

            _simple_daily_availability: new ReactiveVar(member.simple_daily_availability)

            _extended_daily_availability_dep: new Tracker.Dependency()
            _extended_daily_availability: member.extended_daily_availability or default_extended_daily_availability.slice() # create shallow copy

            _extended_daysoff_ranges_dep: new Tracker.Dependency()
            _extended_daysoff_ranges: member.extended_daysoff_ranges or []

          do (member_controller) ->
            member_controller.getAvailabilityType = -> member_controller._availability_type.get()

            member_controller.setAvailabilityType = (new_val) ->
              members_availability_proxy.changed.set(true)

              return member_controller._availability_type.set(new_val)

            member_controller.getSimpleDailyAvailability = -> member_controller._simple_daily_availability.get()

            member_controller.getFormattedSimpleDailyAvailability = -> dataTypeDef().formatter(member_controller.getSimpleDailyAvailability())

            member_controller.setSimpleDailyAvailability = (new_val) ->
              members_availability_proxy.changed.set(true)

              return member_controller._simple_daily_availability.set(new_val)

            member_controller.getExtendedDailyAvailability = ->
              member_controller._extended_daily_availability_dep.depend()

              return member_controller._extended_daily_availability

            member_controller.getFormattedExtendedDailyAvailability = ->
              return _.map member_controller.getExtendedDailyAvailability(), (daily_val) -> dataTypeDef().formatter(daily_val)

            member_controller.setExtendedDailyAvailability = (new_extended_daily_availability) ->
              members_availability_proxy.changed.set(true)

              member_controller._extended_daily_availability = new_extended_daily_availability
              member_controller._extended_daily_availability_dep.changed()

              return

            member_controller.getExtendedDaysoffRanges = ->
              member_controller._extended_daysoff_ranges_dep.depend()

              return member_controller._extended_daysoff_ranges.slice()

            member_controller.setExtendedDaysoffRanges = (new_extended_daysoff_ranges) ->
              members_availability_proxy.changed.set(true)

              member_controller._extended_daysoff_ranges = new_extended_daysoff_ranges
              member_controller._extended_daysoff_ranges_dep.changed()

              return

          members_availability_proxy.members.push member_controller

      @_members_availability_proxy = members_availability_proxy
      @_members_availability_proxy_dep.changed()

      return

    getMembersAvailabilityProxy: ->
      @_members_availability_proxy_dep.depend()

      return @_members_availability_proxy

    _initBurndownData: _.once (self) ->
      self._burndown_data_dep = new Tracker.Dependency()
      self._current_burndown_projection_dep = new Tracker.Dependency()

      return

    initBurndownData: ->
      @_initBurndownData(@)

      @_burndown_data = null
      @_burndown_data_dep.changed()

      @_current_burndown_projection = []
      @_current_burndown_projection_dep.changed()

      @_active_request_id = null
      @_burndown_data_pending_request = false

      return

    setCurrentBurndownProjection: (projection) ->
      @_current_burndown_projection = projection
      @_current_burndown_projection_dep.changed()

      return

    getCurrentBurndownProjection: ->
      @_current_burndown_projection_dep.depend()

      return @_current_burndown_projection

    getChartHasProjection: ->
      return @getCurrentBurndownProjection().length > 0

    reloadBurndownData: ->
      # Reloading of the burndown data will also update the members availability
      # array with new members that got added as resources since last load

      if not (active_item_id = module.activeItemId())?
        return

      if @_burndown_data_pending_request
        return

      _active_request_id = @_active_request_id = Random.id()
      @_burndown_data_pending_request = true
      do (_active_request_id) =>
        @getProjectBurndownData active_item_id, (err, burndown_data) =>
          if _active_request_id != @_active_request_id
            # Ignore the request, init requested
            console.info "reloadBurndownData: request ignored, init requested"

            return
          
          if err?
            @_burndown_data_pending_request = false

            return

          @_burndown_data = burndown_data
          @_burndown_data_dep.changed()
          @_burndown_data_pending_request = false

          # Check if new members were added as a result of the burndown reload, if so, reload
          # the members availability proxy
          members_availability_proxy = Tracker.nonreactive => @getMembersAvailabilityProxy()
          known_members = _.map members_availability_proxy.members, (member) -> member.user_id
          if _.difference(@_burndown_data.involved_members, known_members).length > 0
            Tracker.nonreactive =>
              first = true

              # We can't call reloadMembersAvailabilityProxy right away, we need to wait the
              # server to update the list of involved members, we assume the next update
              # to the active item obj is the update for the involved members. 
              involved_members_update_comp = Tracker.autorun (c) =>
                APP.modules.project_page.activeItemObj(devPlanner()._getProjectRelevantFieldsProjection())

                if first
                  first = false
                  return

                reload_members_availability_proxy = @reloadMembersAvailabilityProxy()

                c.stop()

                return

              # If nothing happned, give up after a while
              setTimeout ->
                involved_members_update_comp.stop()
              , 1000 * 2

          return

      return

    getBurndownData: ->
      @_burndown_data_dep.depend()

      return @_burndown_data

    isBurndownDataReady: -> @getBurndownData()? and @_burndown_data_pending_request is false

    getChartData: ->
      if not (active_item_obj = APP.modules.project_page.activeItemObj(devPlanner()._getProjectRelevantFieldsProjection()))?
        return

      burndown_data = @getBurndownData()
      members_availability = active_item_obj[JustdoDeliveryPlanner.task_project_members_availability_field_name]
      project_base_workdays = active_item_obj[JustdoDeliveryPlanner.task_base_project_workdays_field_name]

      chart_data =
        burndown_data: burndown_data
        members_availability: members_availability
        project_base_workdays: project_base_workdays

      if (start_date = active_item_obj.start_date)?
        chart_data.start_date = start_date

      if (baseline = active_item_obj[JustdoDeliveryPlanner.task_baseline_projection_data_field_name])?
        chart_data.baseline = _.extend {}, baseline
        chart_data.baseline.series = _.map(chart_data.baseline.series, (data_point) => [new Date(data_point[0]).getTime(), data_point[1]])

      return chart_data

    sufficientDataForChart: ->
      if not @isBurndownDataReady()
        return false

      chart_data = @getChartData()

      for field_name, field_val of chart_data
        if _.isEmpty field_val
          return false

      return true

    refreshChart: ->
      if not @sufficientDataForChart()
        return

      chart_data = @getChartData()

      s_chart_start_date = new Date().toISOString().split("T")[0]
      if chart_data.start_date?
        s_chart_start_date = chart_data.start_date

      start_date_is_in_the_future = false
      if chart_data.start_date > new Date().toISOString().split("T")[0]
        start_date_is_in_the_future = true

      series = []
      sorted_dates = Object.keys(chart_data.burndown_data.burndown).sort()

      #can_project = true
      #calculating total to date
      actual = []
      running_total = 0
      projection_total = 0
      runningUsers = {}
      # WAS: members_avail = new ReactiveVar({})
      # WAS" members_map = members_avail.get()
      members_map = {}
      for s_date in sorted_dates

        # total calculation
        running_total += chart_data.burndown_data.burndown[s_date].total/3600

        if s_date >= s_chart_start_date #and (not start_date_is_in_the_future)
          date = new Date(s_date)
          actual.push [Date.UTC(date.getUTCFullYear(),date.getMonth(),date.getDate()), running_total]

        #per user calculation
        for u,t of chart_data.burndown_data.burndown[s_date].users
          if runningUsers[u]
            runningUsers[u]+= t / 3600
          else
            runningUsers[u] = t / 3600

      series.push
        name: "Actual"
        data: actual
        color: "blue"
        tooltip:
          pointFormatter: ->
            return "#{@series.name}: <b>#{dataTypeDef().formatter(@y * 3600)}</b>"

      ##############################
      # calculating projection
      ##############################

      projection_date = new Date()
      if chart_data.start_date
        if (new Date(chart_data.start_date)) > projection_date
          projection_date = new Date(chart_data.start_date)
      s_projection_date = projection_date.toISOString().split('T')[0]

      # transform members availability to map:
      availability = {}
      for a in chart_data.members_availability
        availability[a.user_id] = a

      g_projection = []
      unchanged_total_count = 0
      while running_total > 0 and g_projection.length < 365 #limiting the projection to a year...
        prev_total = running_total
        for user_id, hours_left of runningUsers
          hours_spent = 0
          if hours_left > 0
            if availability[user_id]?
              if availability[user_id].availability_type == "simple" and chart_data.project_base_workdays[projection_date.getDay()] == 1
                hours_spent = Math.min(availability[user_id].simple_daily_availability/3600,hours_left)
              else if availability[user_id].availability_type == "extended"
                on_vacation = false
                for vacation in availability[user_id].extended_daysoff_ranges
                  if vacation[0] <= s_projection_date and vacation[1] >= s_projection_date
                    on_vacation = true
                    break
                if not on_vacation
                  hours_spent = Math.min(availability[user_id].extended_daily_availability[projection_date.getDay()]/3600,hours_left)

          if hours_spent > 0
            runningUsers[user_id] -= hours_spent
            running_total -= hours_spent

        if prev_total == running_total
          unchanged_total_count++
        else
          unchanged_total_count=0
          g_projection.push [Date.UTC(projection_date.getUTCFullYear(),projection_date.getMonth(),projection_date.getDate()), running_total]

        if unchanged_total_count >= 30
          break

        projection_date.setDate(projection_date.getDate()+1)
        s_projection_date = projection_date.toISOString().split('T')[0]


      g_projection.push [
        Date.UTC(projection_date.getUTCFullYear(),
        projection_date.getMonth(),
        projection_date.getDate()),
        running_total
      ]
      series.push
        name: "Current Projection"
        data: g_projection
        dashStyle: "Dash"
        color: "blue"
        tooltip:
          pointFormatter: ->
            return "#{@series.name}: <b>#{dataTypeDef().formatter(@y * 3600)}</b>"

      devPlanner().setCurrentBurndownProjection g_projection

      ########################################
      # if there is a baseline - present it
      ########################################
      if (baseline = chart_data.baseline)?
        series.push
          name: "Baseline Projection"
          data: baseline.series
          dashStyle: "Dash"
          color: "red"
          tooltip:
            pointFormatter: ->
              return "#{@series.name}: <b>#{dataTypeDef().formatter(@y * 3600)}</b>"

      $("#burndown-chart").highcharts
        chart: {type: "spline"}
        plotOptions:
          series:
            animation: false
            marker:
              radius: 3

        title:
          text: "Burndown Plan"
        yAxis:
          title:
            text: "Hours Left"
        xAxis:
          type: "datetime"
          title: {text: "Date"}
          dateTimeLabelFormats: {day: "%e. %b", month: "%e. %b", year: "%b"}
        series: series

        exporting:
          buttons:
            contextButton:
              menuItems: ["printChart", "separator", "downloadPNG", "downloadJPEG", "downloadPDF", "downloadSVG", "separator", "downloadCSV", "downloadXLS"]

      return



  module = APP.modules.project_page

  curProj = -> module.curProj()

  devPlanner = -> APP.justdo_delivery_planner

  dataTypeDef = -> devPlanner().getTimeMinutesDataTypeDef()

  Template.delivery_planner_task_pane_main.onCreated ->
    @getCurrentTab = ->
      if (active_item_obj = module.activeItemObj())?
        if not devPlanner().isTaskObjProject(active_item_obj)
          return "assign" # no other choice

      return devPlanner().taskPaneSectionGetCurrentTab()

    @setTab = (tab_id) -> devPlanner().taskPaneSectionSetCurrentTab(tab_id)

  Template.delivery_planner_task_pane_main.helpers
    isProject: ->
      if not (active_item_obj = module.activeItemObj())?
        return false

      return devPlanner().isTaskObjProject(active_item_obj)

    isArchived: ->
      if not (active_item_obj = module.activeItemObj())?
        return false

      return devPlanner().isTaskObjArchivedProject(active_item_obj)

    currentTab: ->
      tpl = Template.instance()

      return tpl.getCurrentTab()

    isSmallLayout: ->
      module.invalidateOnWireframeStructureUpdates()

      return $(".task-pane-section").width() < 409

  Template.delivery_planner_task_pane_main.events
    "click .is-project-toggle": (e, tpl) ->
      if not (active_item_id = module.activeItemId())?
        return false

      devPlanner().toggleTaskIsProject active_item_id, (err, is_new_state_project) ->
        if not is_new_state_project
          tpl.setTab("assign")
        else
          tpl.setTab("project")

        return

      return

    "click .delivery-planner-tab": (e, tpl) ->
      e.preventDefault()

      tab_id = $(e.target).closest(".delivery-planner-tab").attr("tab-id")

      tpl.setTab(tab_id)

      return

    "click .open-in-sub-tree-tab": (e, tpl) ->
      APP.modules.project_page.performOp("zoomIn")

      return

  Template.delivery_planner_task_pane_project_tab.onCreated ->
    APP.justdo_highcharts.requireHighcharts()

    @autorun ->
      APP.modules.project_page.activeItemId() # On changes to active item id, reload the burndown data

      devPlanner().initBurndownData()
      devPlanner().reloadBurndownData()

    @autorun ->
      APP.modules.project_page.activeItemId() # On changes to active item id, reload the burndown data
      devPlanner().initMembersAvailabilityProxy()
      devPlanner().reloadMembersAvailabilityProxy()

      return

    return

  Template.delivery_planner_task_pane_project_tab.helpers
    resourcePlannerIsEnabled: ->
      return curProj().isCustomFeatureEnabled("resource_planner_module")

    sufficientDataForChart: -> devPlanner().sufficientDataForChart()

    isHighchartsReady: -> APP.justdo_highcharts.isHighchartLoaded()

    burndownDataPending: -> not devPlanner().isBurndownDataReady()

    isArchived: ->
      if not (active_item_obj = module.activeItemObj())?
        return false

      return devPlanner().isTaskObjArchivedProject(active_item_obj)

    isCommitted: ->
      if not (active_item_obj = module.activeItemObj())?
        return false

      return devPlanner().isTaskObjCommittedProject(active_item_obj)

    formattedCommitDate: ->
      if not (active_item_obj = module.activeItemObj())?
        return null
      return moment(new Date(active_item_obj[JustdoDeliveryPlanner.task_is_committed_field])).format('LLL')

    taskHasMembersAvailabilityRecords: ->
      if not (active_item_obj = module.activeItemObj())?
        return false

      return devPlanner().taskObjHasMembersAvailabilityRecords(active_item_obj)

    humanReadableProjectWorkdays: ->
      if not (active_item_obj = module.activeItemObj())?
        return ""

      workdays = active_item_obj[JustdoDeliveryPlanner.task_base_project_workdays_field_name]

      workdays = _.map workdays, (active, i) -> if active then human_readable_workdays_names[i] else null
      workdays.push(workdays.shift()) # Put sunday last
      workdays = _.filter workdays, (wd) -> wd?

      if workdays.length == 7
        return "Every day"
      else if workdays.length == 0
        return "None"
      else
        return workdays.join(" ")

    getWorkdaysEditorController: ->
      return {
        getCurrentWorkdays: ->
          if not (active_item_obj = module.activeItemObj())?
            return []

          return active_item_obj[JustdoDeliveryPlanner.task_base_project_workdays_field_name]

        setWorkdays: (new_workdays) ->
          if not (active_item_id = module.activeItemId())?
            return false

          updates = {
            "#{JustdoDeliveryPlanner.task_base_project_workdays_field_name}": new_workdays
          }

          # Todo, check whether really anything changed, before performing the update.
          APP.collections.Tasks.update active_item_id, {$set: updates}

          return
      }

  Template.delivery_planner_task_pane_project_tab.events
    "click .refresh": (e,tpl) ->
      devPlanner().reloadBurndownData()
      devPlanner().reloadMembersAvailabilityProxy()

      return

    "click .dp-archive-project": (e, tpl) ->
      if not (active_item_id = module.activeItemId())?
        return false

      return devPlanner().toggleTaskArchivedProjectState(active_item_id)

    "click .dp-commit-to-project-plan": (e, tpl) ->
      if not (active_item_id = module.activeItemId())?
        return false

      devPlanner().commitProjectPlan active_item_id, (err) ->
        if err?
          alert("Error: " + err.reason)

          return

        return
      
      return

    "click .dp-uncommit-to-project-plan": (e, tpl) ->
      bootbox.confirm
        message: "Are you sure you want to remove the commitment made for the project plan?"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false

        callback: (result) ->
          if result
            if not (active_item_id = module.activeItemId())?
              return false

            devPlanner().removeProjectPlanCommit active_item_id, (err) ->
              if err?
                alert("Error: " + err.reason)

                return

              return

          return

      return

  Template.delivery_planner_task_pane_project_tab_start_date_field_editor.onRendered ->
    parent_tpl = Template.closestInstance("task_pane_item_details_additional_field")

    field_id = "start_date"

    current_item_id = module.activeItemId()

    gc = APP.modules.project_page.gridControl()

    field_def = gc.getFieldDef(field_id)

    grid_column_editor = field_def.grid_column_editor

    field_editor = gc.generateFieldEditor(field_id, current_item_id)

    #
    # Editor specific modifications
    #
    if grid_column_editor == "SelectorEditor"
      field_editor.$dom_node.find("div.dropdown-menu").removeAttr("style")

    $firstNode = $(@firstNode)
    $firstNode.data("editor_field_id", field_id)    
    $firstNode.data("editor", field_editor)
    $(@firstNode).html(field_editor.$dom_node)

    $firstNode.find(".editor-unicode-date")
      .keydown (e) ->
        if e.which == 13
          field_editor.save()

          $(e.target).blur()

          return

        if e.which == 27
          field_editor.cancel()

          $(e.target).blur()

          return

      .blur (e) ->
        if not $("#ui-datepicker-div").is(":visible")
          field_editor.save()

        return

      .data().datepicker.settings.onSelect = ->
        field_editor.save()

        return

    @autorun ->
      start_date = APP.modules.project_page.activeItemObj({start_date: 1})?.start_date

      field_editor.editor.setInputValue(start_date)

      return

    $(window).trigger("resize.autosize")

    return

  Template.delivery_planner_task_pane_project_tab_members_avail_table.helpers
    membersAvailabilityProxy: ->
      return devPlanner().getMembersAvailabilityProxy()

  Template.delivery_planner_task_pane_project_tab_members_avail_table.events
    "click .dp-save-members-availability": (e, tpl) ->
      if not (active_item_id = module.activeItemId())?
        return false

      devPlanner().getMembersAvailabilityProxy().save()

      return

    "click .dp-cencel-members-availability": ->
      return devPlanner().reloadMembersAvailabilityProxy()

  Template.delivery_planner_task_pane_project_tab_member_availability.helpers
    placeholder: ->
      return dataTypeDef().empty_val_placeholder

    humanReadableExtendedDailyAvailability: ->
      workdays = @getExtendedDailyAvailability()

      workdays = _.map workdays, (val, i) -> [human_readable_workdays_names[i], parseInt(val, 10)]
      workdays.push(workdays.shift()) # Put sunday last
      workdays = _.filter workdays, (wd) -> wd[1] != 0

      result = ""
      if workdays.length == 0
        result = "None"
      else
        workdays = _.map workdays, (wd) -> "#{wd[0]}: #{dataTypeDef().formatter(wd[1])}"

        result = workdays.join(""" <span class="extended-days-avail-separator">&#8226;</span> """)

      return JustdoHelpers.xssGuard(result, {allow_html_parsing: true, enclosing_char: ''})

    getDaysoffRanges: ->
      if _.isEmpty(ranges = @getExtendedDaysoffRanges())
        return null

      ranges = _.map ranges, (range, i) -> {start: range[0], end: range[1], index: i}

      ranges = _.sortBy ranges, (range) -> range.start

      # Perform the replace after the sort and not before is important
      ranges = _.map ranges, (range, i) ->
        range.start = normalizeUserPreferenceDateFormatAndFormatToUnicodeDateString(range.start)
        range.end = normalizeUserPreferenceDateFormatAndFormatToUnicodeDateString(range.end)

        return range

      return ranges

  Template.delivery_planner_task_pane_project_tab_member_availability.events
    "change .simple-daily-availability,focusout .simple-daily-availability": (e, tpl) ->
      user_input_val = $(e.target).val().trim()

      if _.isEmpty(user_input_val)
        user_input_val = "0"

      new_val = dataTypeDef().userInputToValTranslator(user_input_val)
      if _.isString new_val
        # If remains string, parsing failed, use 0
        new_val = 0

      if new_val < 0
        new_val = 0

      new_formatted_val = dataTypeDef().formatter(new_val)

      # We need the new value to the dom, for case the user changed the value to a value
      # that translates to the same underlying value (think a change from 3:00 to 3), in
      # such case blaze won't update the dom
      $(e.target).val(new_formatted_val)

      @setSimpleDailyAvailability(new_val)

      return

    "click .customize-daily-availability": (e, tpl) ->
      @setAvailabilityType("extended")

      return

    "click .set-simple-daily-availability": (e, tpl) ->
      @setAvailabilityType("simple")

      return

    "click .daily-avail-extended-remove-daysoff": (e, tpl) ->
      index_to_remove = parseInt($(e.target).closest("li").attr("item-index"), 10)

      daysoff_ranges = tpl.data.getExtendedDaysoffRanges()

      daysoff_ranges.splice(index_to_remove, 1)
      tpl.data.setExtendedDaysoffRanges(daysoff_ranges)

      return

  Template.delivery_planner_task_pane_project_tab_burndown_chart.onRendered ->
    @autorun ->
      devPlanner().refreshChart() # refreshChart() calls getChartData() which is a reactive resource the invalidates on every change of the chart underlying data

      return

    return

  Template.delivery_planner_task_pane_project_tab_burndown_chart.helpers
    showBaselineSetting: ->
      if not (active_item_obj = APP.modules.project_page.activeItemObj())?
        return false

      return active_item_obj["#{JustdoDeliveryPlanner.task_baseline_projection_data_field_name}"]? or devPlanner().getChartHasProjection()

    hasBaselineProjection: ->
      if not (active_item_obj = APP.modules.project_page.activeItemObj())?
        return false

      return active_item_obj["#{JustdoDeliveryPlanner.task_baseline_projection_data_field_name}"]?

    hasProjection: ->
      return devPlanner().getChartHasProjection()

  Template.delivery_planner_task_pane_project_tab_burndown_chart.events
    "click .dp-save-baseline": (e, tpl) ->
      if not (active_item_id = module.activeItemId())?
        return false

      burndown_projection = devPlanner().getCurrentBurndownProjection()

      burndown_projection =
        _.map burndown_projection, (data_point) => [new Date(data_point[0]).toISOString().split("T")[0], data_point[1]]

      devPlanner().saveBaselineProjection active_item_id, {series: burndown_projection}, ->
        JustdoSnackbar.show
          text: "Baseline projection saved."
          duration: 3000

        return

      return

    "click .dp-remove-baseline": (e, tpl) ->
      if not (active_item_obj = APP.modules.project_page.activeItemObj())?
        return

      devPlanner().removeBaselineProjection active_item_obj._id, ->
        JustdoSnackbar.show
          text: "Baseline projection removed."
          duration: 3000

        return

      return

  Template.delivery_planner_task_pane_assign_tab.onCreated ->
    @getTaskAvailableAssignProjectList = =>
      current_project_id = curProj().id

      if not (active_item_obj = APP.modules.project_page.activeItemObj())?
        return

      exclude_tasks = [active_item_obj._id].concat(_.keys active_item_obj.parents)

      project_tasks = devPlanner().getKnownProjects(current_project_id, {active_only: true, exclude_tasks: exclude_tasks}, Meteor.userId())

      return devPlanner().excludeProjectsCauseCircularChain project_tasks, active_item_obj._id

    #
    # Select picker management
    #
    @setupSelectPicker = (setupCompletedCb) =>
      select_selector = ".project-select"

      setupPicker = ->
        $(select_selector)
          .selectpicker
            liveSearch: true
            dropupAuto: true
            size: 7 # Note, the actual height is being shorten a bit with !important in the sass
                    # file, to cut the last item, to ease recognition that there is more to the list
                    # in environments that doesn't show the scrollbar.
          .on "show.bs.select", (e) ->
            setTimeout ->
              $(e.target).focus()
            , 0

        return

      if $(select_selector).length == 0
        # Sometimes, @setupSelectPicker might be called before the <select> is actually
        # generated.
        # Even though we are operating from onRendered, post rendering, the autorun might
        # run before blaze actually updates the template in response to reactiev changes. 
        # In these cases, we defer the setup, assuming we'll have the select in the next
        # tick.
        Meteor.defer =>
          setupPicker()

          JustdoHelpers.callCb(setupCompletedCb)
      else
        setupPicker()

        JustdoHelpers.callCb(setupCompletedCb)

      return

    @closeSelectPickerIfOpen = =>
      if ($(".project-select.open").length > 0)
        $("div.project-select .dropdown-toggle").click()

      return

    @updateSelectPicker = =>
      if $("div.project-select").length > 0
        Meteor.defer ->
          $(".project-select").selectpicker("refresh")

          return
      else
        @setupSelectPicker ->
          return

      return

    @destroySelectPicker = =>
      $("div.resource-select").selectpicker("destroy")

      # .selectpicker("destroy") won't if the original <select> removed, so remove the component
      # directly to make sure its removed.
      $("div.resource-select").remove()

      return

  Template.delivery_planner_task_pane_assign_tab.onRendered ->
    @autorun =>
      # Note, @getTaskAvailableAssignProjectList is a reactive resource, that invalidates on:
      # changes of:
      # module.activeItemObj()
      # module.curProj()
      # changes to the paths of any of the tasks to which this project can be assigned.

      available_assign_project_list = @getTaskAvailableAssignProjectList()

      # To trigger invalidations when necessary
      if _.isEmpty available_assign_project_list
        @destroySelectPicker()
      else
        @updateSelectPicker()

      return

    @addNewParentToActiveItemId = (new_parent_id, cb) ->
      gc = module.gridControl()
      grid_data = gc?._grid_data

      if grid_data?
        gc?.saveAndExitActiveEditor() # Exit edit mode, if any, to make sure result will appear on tree (otherwise, will show only when exit edit mode)

        current_item_id = module.activeItemId()

        gc._performLockingOperation (releaseOpsLock, timedout) =>
          gc.addParent current_item_id, {parent: new_parent_id, order: 0}, (err) ->
            releaseOpsLock()

            cb?(err)
      else
        APP.logger.error "Context: couldn't retrieve grid_data object"

      return

    return

  Template.delivery_planner_task_pane_assign_tab.onDestroyed ->
    @destroySelectPicker()

    return

  Template.delivery_planner_task_pane_assign_tab.helpers
    availableProjects: ->
      tpl = Template.instance()

      return tpl.getTaskAvailableAssignProjectList()

    assignedProjects: ->
      if not (active_item_id = module.activeItemId())?
        return

      return devPlanner().getProjectsAssignedToTask(active_item_id, Meteor.userId())

    assignedProjectIsArchived: ->
      return @[JustdoDeliveryPlanner.task_is_archived_project_field_name] == true

  Template.delivery_planner_task_pane_assign_tab.events
    "click .add-project-btn": (e, tpl) ->
      tpl.addNewParentToActiveItemId $("select.project-select").val()

      return

    "click .dp-context-item" : (e) ->
      gcm = module.getCurrentGcm()
      gcm.activateTab("main")
      gc = gcm?.getAllTabs()?.main?.grid_control
      gc.activatePath("/#{@_id}/", 0, {smart_guess: true})

      APP.justdo_delivery_planner.taskPaneSectionSetCurrentTab("project")

      return

    "click .dp-task-context-delete": ->
      if not (active_item_id = module.activeItemId())?
        return

      if not (active_item_obj = APP.modules.project_page.activeItemObj())?
        return

      parents_ids = _.keys active_item_obj.parents
      existing_parents_count = APP.collections.Tasks.find({_id: {$in: parents_ids}}).count()

      if "0" in parents_ids
        existing_parents_count += 1

      if existing_parents_count < 2
        bootbox.alert
          message: "<p>Can't unassign the task from this project, since it has no other parent tasks.</p><p>Move the task outside of the project, or remove it completely.</p>"
          className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
          closeButton: false

        return

      project_id = @_id

      project_pseudo_path = "/#{project_id}/#{active_item_id}/"

      active_item_path = module.activeItemPath()

      if active_item_path.indexOf(project_pseudo_path) >= 0
        project_pseudo_path = active_item_path

      if not (gc = module.gridControl())?
        APP.logger.warn "Couldn't find grid control"

      bootbox.confirm
        message: "<b>Are you sure you want to unassign this project?</b>"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false

        callback: (result) =>
          if result
            # If we remove the active path, we want to use the regular remove
            # op to use its post remove logic (selecting next task, etc.)
            if module.activeItemPath() == project_pseudo_path
              return gc.removeActivePath()

            gc._performLockingOperation (releaseOpsLock, timedout) =>
              gc._grid_data?.removeParent project_pseudo_path, (err) =>
                releaseOpsLock()

                if err?
                  APP.logger.error "Error: #{err}"

      return