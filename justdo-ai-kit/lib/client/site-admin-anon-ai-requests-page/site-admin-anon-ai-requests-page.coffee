DEFAULT_PERIOD_IN_DAYS = 7

Template.justdo_site_admin_ai_requests.onCreated ->
  @default_start_date = moment().startOf("day").subtract(DEFAULT_PERIOD_IN_DAYS, "days")
  @default_end_date = moment().endOf("day")
  @start_date_timestamp_rv = new ReactiveVar @default_start_date.valueOf()
  @end_date_timestamp_rv = new ReactiveVar @default_end_date.valueOf()

  @refresh_all_dep = new Tracker.Dependency()
  @active_checkbox = ["anon_only"]
  @active_checkbox_dep = new Tracker.Dependency()
  @toggleFilterCheckbox = (filter_type) ->
    if _.contains @active_checkbox, filter_type
      @active_checkbox = _.without @active_checkbox, filter_type
    else
      @active_checkbox.push filter_type

    @active_checkbox_dep.changed()

    return
  @isFilterChecked = (type) ->
    @active_checkbox_dep.depend()
    return _.contains @active_checkbox, type
  @mapActiveCheckboxToOptions = (options) ->
    @active_checkbox_dep.depend()

    for filter_type in @active_checkbox
      if filter_type in ["anon_only", "aborted", "has_error"]
        options[filter_type] = true

      if filter_type in ["accepted", "partial_accepted", "declined"]
        if not _.isArray options.choice
          options.choice = []
        options.choice.push filter_type[0]

    return options

  @ai_query_logs_rv = new ReactiveVar []
  @all_sorted_filtered_logs_rv = new ReactiveVar []
  @autorun =>
    @refresh_all_dep.depend()
    @active_checkbox_dep.depend()
    
    starting_ts = @start_date_timestamp_rv.get()
    ending_ts = @end_date_timestamp_rv.get()
    if (not _.isNumber(starting_ts)) or (not _.isNumber(ending_ts))
      return

    options = 
      starting_ts: starting_ts
      ending_ts: ending_ts
    options = @mapActiveCheckboxToOptions options
    APP.justdo_ai_kit.getAIRequestsLog options, (err, res) =>
      if err?
        JustdoSnackbar.show
          text: err.reason or err
        return

      @ai_query_logs_rv.set res
      return

    return

  @pseudo_fields =
    createdAt: (log) -> log.createdAt
    performedBy: (log) -> log.performed_by
    performedByDisplayName: (log) -> JustdoHelpers.displayName log.performed_by
    preRegisterId: (log) -> log.pre_register_id
    templateId: (log) -> log.req.template_id
    templateData: (log) -> EJSON.stringify log.req.data
    response: (log) -> 
      if not (res = log.res)?
        return

      return EJSON.stringify log.res.choices[0]?.message?.content
    choice: (log) -> log.choice
    error: (log) -> log.error
    aborted: (log) -> log.aborted
    remarks: (log) ->
      remarks = []

      if log.error
        remarks.push """<span class="badge badge-danger rounded-0 mr-1">Error</span>"""

      if log.aborted
        remarks.push """<span class="badge badge-warning rounded-0 mr-1">Aborted</span>"""

      return remarks.join(" ")

  @filter_term_rv = new ReactiveVar(null)
  @order_by_field_rv = new ReactiveVar("createdAt")
  @order_by_field_desc_rv = new ReactiveVar(true)
  @autorun =>
    ai_query_logs = @ai_query_logs_rv.get()

    if (filter_term = @filter_term_rv.get())?
      filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(filter_term)}", "i")

      ai_query_logs = _.filter ai_query_logs, (log) =>
        for pseudo_field_id, pseudo_field_def of @pseudo_fields
          if filter_regexp.test(pseudo_field_def.call @pseudo_fields, log)
            return true

        return false

    if (order_by_field = @order_by_field_rv.get())?
      if order_by_field is "performedByDisplayName"
        ai_query_logs = JustdoHelpers.localeAwareSortCaseInsensitive ai_query_logs, (doc) =>
          return @pseudo_fields[order_by_field](doc)
      else
        ai_query_logs = _.sortBy ai_query_logs, (doc) =>
          return @pseudo_fields[order_by_field](doc)

      if (order_by_field_desc = @order_by_field_desc_rv.get())
        ai_query_logs.reverse()

    @all_sorted_filtered_logs_rv.set(ai_query_logs)

    return

  LogsFiltersDropdownConstructor = JustdoHelpers.generateNewTemplateDropdown "site-admin-ai-query-logs-filter-dropdown", "site_admin_ai_requests_filter_dropdown",
    custom_bound_element_options:
      close_button_html: null
    template_data:
      parent_tpl: @

    updateDropdownPosition: ($connected_element) ->
      @$dropdown
        .position
          of: $connected_element
          my: "right top"
          at: "right bottom"
          collision: "fit fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element
            element.element.addClass "animate slideIn shadow-lg"
            element.element.css
              top: new_position.top - 10
              left: new_position.left + 6
            return

        $(".dropdown-menu.show").removeClass("show") # Hide active dropdown

      return

  @logs_filter_dropdown = new LogsFiltersDropdownConstructor()

  return

Template.justdo_site_admin_ai_requests.onDestroyed ->
  @logs_filter_dropdown.destroy()

  return

Template.justdo_site_admin_ai_requests.helpers
  activeFilterCount: -> 
    tpl = Template.instance()
    tpl.active_checkbox_dep.depend()
    return _.size tpl.active_checkbox

  filterIsActive: ->
    return Template.instance().filter_term_rv.get()?

  filteredLogsCount: ->
    search_term = Template.instance().filter_term_rv.get()
    filtered_logs_count = 0

    if search_term?
      filtered_logs_count = Template.instance().all_sorted_filtered_logs_rv.get().length

    return filtered_logs_count

  defaultStartDate: ->
    # For init only, this helper is expected to run only once.
    tpl = Template.instance()
    return tpl.default_start_date.format("YYYY-MM-DD")

  getStartDate: ->
    tpl = Template.instance()
    start_date = tpl.start_date_timestamp_rv.get()
    return moment(start_date).format "YYYY-MM-DD"

  defaultEndDate: ->
    # For init only, this helper is expected to run only once.
    tpl = Template.instance()
    return tpl.default_end_date.format "YYYY-MM-DD"

  getEndDate: ->
    tpl = Template.instance()
    end_date = tpl.end_date_timestamp_rv.get()
    return moment(end_date).format "YYYY-MM-DD"

  orderByFieldDesc: ->
    return Template.instance().order_by_field_desc_rv.get()

  activeFilter: ->
    return Template.instance().order_by_field_rv.get()

  isUserSuperSiteAdmin: ->
    return APP.justdo_site_admins?.isUserSuperSiteAdmin Meteor.userId()

  logs: ->
    return Template.instance().all_sorted_filtered_logs_rv.get()

  rowClassByUserChoice: ->
    choice = Template.instance().pseudo_fields.choice @

    if choice is "a"
      return "success"
    
    if choice is "p"
      return "warning"
    
    if choice is "d"
      return "danger"
    
    return "default"

  detailedHumanReadableCreatedAt: ->
    created_at = Template.instance().pseudo_fields.createdAt @
    return moment(created_at).format("#{JustdoHelpers.getUserPreferredDateFormat()} h:mm:ss a")

  humanReadableCreatedAt: ->
    created_at = Template.instance().pseudo_fields.createdAt @
    return moment(created_at).format JustdoHelpers.getUserPreferredDateFormat()

  performedBy: ->
    tpl = Template.instance()
    if (performed_by = tpl.pseudo_fields.performedBy @)?
      return tpl.pseudo_fields.performedByDisplayName @
    return tpl.pseudo_fields.preRegisterId @

  preRegisterId: ->
    return Template.instance().pseudo_fields.preRegisterId @
  
  templateId: ->
    return Template.instance().pseudo_fields.templateId @
  
  stringifiedTemplateData: (max_length) ->
    data = Template.instance().pseudo_fields.templateData @ 
    if max_length?
      data = JustdoHelpers.ellipsis data, max_length
    return data
  
  stringifiedResponse: (max_length) ->
    data = Template.instance().pseudo_fields.response @
    if max_length?
      data = JustdoHelpers.ellipsis data, max_length
    return data
  
  choice: ->
    return Template.instance().pseudo_fields.choice @
  
  getPseudoRemarksVal: ->
    return Template.instance().pseudo_fields["remarks"](@)

Template.justdo_site_admin_ai_requests.events
  "keyup .filter": (e, tpl) ->
    $input = $(e.target).closest(".filter")

    if not _.isEmpty(filter_term = $input.val().trim())
      tpl.filter_term_rv.set filter_term
    else
      tpl.filter_term_rv.set null

    $(".site-admins-content").animate { scrollTop: 0 }, "fast"

    return

  "click .filter-clear": (e, tpl) ->
    tpl.filter_term_rv.set null
    $(".filter").val ""

    return

  "click .sort-by": (e, tpl) ->
    sort_by = $(e.target).closest(".sort-by").attr("sort-by")

    tpl.order_by_field_rv.set(sort_by)

    if tpl.order_by_field_desc_rv.get() == true
      tpl.order_by_field_desc_rv.set(false)
    else
      tpl.order_by_field_desc_rv.set(true)

    return
  
  "click .filter-icon": (e, tpl) ->
    e.stopPropagation()
    tpl.logs_filter_dropdown.$connected_element = $(e.currentTarget)
    tpl.logs_filter_dropdown.template_data = {dropdown: tpl.logs_filter_dropdown, parent_tpl: tpl}
    tpl.logs_filter_dropdown.openDropdown()
    return

  "click .refresh-all": (e, tpl) ->
    tpl.refresh_all_dep.changed()
    return

  "change .date-controller": (e, tpl) ->
    $e = $(e.target).closest(".date-controller")
    if not (timestamp = $e?.get(0)?.valueAsNumber)
      return

    if $e.hasClass "start-date"
      tpl.start_date_timestamp_rv.set timestamp
    if $e.hasClass "end-date"
      tpl.end_date_timestamp_rv.set timestamp

    return
  
  "click .req-data": (e, tpl) ->
    if not (clipboard_data = tpl.pseudo_fields.templateData @)
      return
    
    clipboard.copy
      "text/plain": EJSON.stringify clipboard_data
    JustdoSnackbar.show 
      text: "Data copied to clipboard"

    return

  "click .res-data": (e, tpl) ->
    if not (clipboard_data = tpl.pseudo_fields.response @)
      return
    
    clipboard.copy
      "text/plain": EJSON.stringify clipboard_data
    JustdoSnackbar.show 
      text: "Data copied to clipboard"

    return
  
  "click .copy-full-log": (e, tpl) ->
    clipboard.copy
      "text/plain": EJSON.stringify @
    JustdoSnackbar.show 
      text: "Full log copied to clipboard"

    return
  
  "click .log-performed-by": (e, tpl) ->
    performed_by_id = tpl.pseudo_fields.performedBy @
    pre_register_id = tpl.pseudo_fields.preRegisterId @
    
    clipboard.copy
      "text/plain": EJSON.stringify {performed_by_id, pre_register_id}
    JustdoSnackbar.show 
      text: "Performed By ID and pre-register ID copied to clipboard"
    
    return