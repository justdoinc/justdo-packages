share.SearchDropdown = JustdoHelpers.generateNewTemplateDropdown "grid-control-search-dropdown", "grid_control_search_dropdown",
  custom_bound_element_options:
    close_button_html: null
    container: "#project-search-comp-container"

  updateDropdownPosition: ($connected_element) ->
    @$dropdown
      .position
        of: $connected_element
        my: "left top"
        at: "left bottom"
        collision: "fit fit"
        using: (new_position, details) =>
          target = details.target
          element = details.element
          element.element.addClass "animate slideIn shadow-lg bg-white"
          element.element.css
            top: 20
            left: 0

    return

highlight = (text, search_val, type) ->
  if text
    text = text.toString()
    index = text.toUpperCase().indexOf search_val.toUpperCase()

    if index >= 0
      pre_highlight_part = JustdoHelpers.xssGuard text.substring(0, index), {allow_html_parsing: true, enclosing_char: ""}
      highlighted_part = JustdoHelpers.xssGuard text.substring(index, index + search_val.length), {allow_html_parsing: true, enclosing_char: ""}
      post_highlight_part = JustdoHelpers.xssGuard text.substring(index + search_val.length), {allow_html_parsing: true, enclosing_char: ""}
      text = pre_highlight_part + "<span class='highlight'>" + highlighted_part + "</span>" + post_highlight_part
    else
      if type == "status" or type == "state"
        text = ""

  return text

stateFormatter = (state) ->
  gc = APP.modules.project_page.gridControl()
  state_txt = gc.getSchemaExtendedWithCustomFields()["state"].grid_values[state].txt

  return state_txt

Template.grid_control_search_dropdown.onCreated ->
  tpl = @
  tpl.result_count_step = 20
  tpl.result_count = new ReactiveVar tpl.result_count_step

  # Prototyping data - Start
  @filters = new ReactiveVar [
    {
      "title": "State"
      "value": "In progress"
    },
    {
      "title": "Created"
      "value": "Last 7 days"
    }
  ]
  # Prototyping data - End

  Tracker.autorun =>
    search_val = @data.search_val.get().trim()
    paths = share.search_dropdown.template_data.result_paths.get()

    if search_val == "" or _.isEmpty(paths)
      tpl.result_count.set tpl.result_count_step
      share.search_dropdown.$dropdown.removeClass "open"
    else
      share.search_dropdown.$dropdown.addClass "open"

  return

Template.grid_control_search_dropdown.helpers
  result_tasks: ->
    search_val = share.search_dropdown.template_data.search_val.get()
    paths = share.search_dropdown.template_data.result_paths.get()
    tasks = []

    for path in paths
      task_id = GridData.helpers.getPathItemId path

      if (task = APP.collections.Tasks.findOne(task_id))?
        task_obj = {
          task_id: task_id
          seqId: highlight(task.seqId, search_val, "seqId")
          title: highlight(task.title, search_val, "title")
          state: highlight(stateFormatter(task.state), search_val, "state")
          note: highlight(task.status, search_val, "status")
        }

        tasks.push task_obj

    return tasks.slice(0, Template.instance().result_count.get())

  resultTasksCount: ->
    paths = share.search_dropdown.template_data.result_paths.get()

    return paths.length

  filters: ->
    return Template.instance().filters.get()

Template.grid_control_search_dropdown.events
  "click .search-dropdown-nav-link": (e, tpl) ->
    $(".search-dropdown-nav-link").removeClass "active"
    $(e.target).closest(".search-dropdown-nav-link").addClass "active"

    return

  "click .search-result-item": (e, tpl) ->
    APP.modules.project_page.gridControl().activateCollectionItemId @task_id

    return

  "click .filter-item-remove": (e, tpl) ->
    filter_title = @title
    filters_array = tpl.filters.get()
    filters_array = _.filter filters_array, (filter) -> filter.title != filter_title
    tpl.filters.set filters_array

    return

  "scroll .search-result-list": (e, tpl) ->
    $list = $(e.target).closest ".search-result-list"

    if Math.round($list.scrollTop() + $list.innerHeight()) >= $list[0].scrollHeight
      tpl.result_count.set tpl.result_count.get() + tpl.result_count_step

    return
