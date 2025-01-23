share.SearchDropdown = JustdoHelpers.generateNewTemplateDropdown "grid-control-search-dropdown", "grid_control_search_dropdown",
  custom_bound_element_options:
    close_button_html: null
    container: "#project-search-comp-container"

  updateDropdownPosition: ($connected_element) ->
    @$dropdown
      .position
        of: $connected_element
        my: "#{APP.justdo_i18n.getRtlAwareDirection "left"} top"
        at: "#{APP.justdo_i18n.getRtlAwareDirection "left"} bottom"
        collision: "fit fit"
        using: (new_position, details) =>
          target = details.target
          element = details.element
          element.element.addClass "animate slideIn shadow-lg bg-white"
          element.element.css
            top: 20
            [APP.justdo_i18n.getRtlAwareDirection "left"]: 0

    return

highlight = (text, search_val, type) ->
  if text
    text = text.toString()
    index = text.toUpperCase().indexOf search_val.toUpperCase()

    if index >= 0
      pre_highlight_part = text.substring(0, index)
      highlighted_part = text.substring(index, index + search_val.length)
      post_highlight_part = text.substring(index + search_val.length)
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

  @grid_control_search = tpl.data.grid_control_search
  @search_dropdown_comp = @grid_control_search.search_dropdown

  tpl.result_count_step = 20
  tpl.result_count = new ReactiveVar tpl.result_count_step
  tpl.show_context_rv = new ReactiveVar false

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

  @prev_search_val = ""
  @autorun =>
    # if _.size(paths) <= GridControlSearch.dropdown_results_limit
    paths = @grid_control_search.getPaths()

    search_val = @grid_control_search.getCurrentTerm()

    if search_val == "" or _.isEmpty(paths)
      tpl.result_count.set tpl.result_count_step
      @search_dropdown_comp.closeDropdown()
    else if search_val isnt @prev_search_val
      @prev_search_val = search_val
      @search_dropdown_comp.ensureOpenDropdown()

    return

  return

Template.grid_control_search_dropdown.helpers
  resultTasks: ->
    tpl = Template.instance()

    search_val = tpl.grid_control_search.getCurrentTerm()
    paths = tpl.grid_control_search.getPaths()
    tasks = []

    task_ids = _.map paths, (path) -> GridData.helpers.getPathItemId path
    result_count = tpl.result_count.get()
    tasks = APP.collections.Tasks.find({_id: {$in: task_ids}}, {limit: result_count}).map (task_doc, i) ->
      corresponding_path = paths[i]
      task_obj = {
        task_id: task_doc._id
        seqId: highlight(task_doc.seqId, search_val, "seqId")
        title: highlight(task_doc.title, search_val, "title")
        state: highlight(stateFormatter(task_doc.state), search_val, "state")
        note: highlight(task_doc.status, search_val, "status")
        path: corresponding_path
        ancestors: []
      }

      if not _.isEmpty corresponding_path
        parent_ids = GridData.helpers.getPathArray corresponding_path
        parent_ids.pop() # Remove the last id, which is the result item
        task_obj.ancestors = APP.collections.Tasks.find({_id: {$in: parent_ids}}, {fields: {seqId: 1, title: 1}}).map (ancestor_doc) ->
          ancestor_doc.title = JustdoHelpers.taskCommonName ancestor_doc
          return ancestor_doc

      return task_obj

    return tasks

  resultTasksCount: ->
    tpl = Template.instance()

    paths = tpl.grid_control_search.getPaths()

    return paths.length

  filters: ->
    return Template.instance().filters.get()

  showFullContext: ->
    return Template.instance().show_context_rv.get()
  
  immediateParent: -> _.last @ancestors

  taskHasMoreThanXAncestors: -> @ancestors.length > GridControlSearch.max_result_ancestors_to_show

  lastXAncestors: -> 
    max_ancestors_to_show = GridControlSearch.max_result_ancestors_to_show

    if max_ancestors_to_show >= @ancestors.length
      return @ancestors

    return @ancestors.slice -max_ancestors_to_show

  getParentMargin: (index, is_task_has_more_ancestors) -> 
    indent_px = GridControlSearch.search_result_indent_px

    margin = index * indent_px
    if is_task_has_more_ancestors
      margin += indent_px
    
    return margin

  getTaskMargin: -> 
    tpl = Template.instance()
    show_full_context = tpl.show_context_rv.get()
    indent_px = GridControlSearch.search_result_indent_px
    if not show_full_context
      return indent_px

    max_ancestors_to_show = GridControlSearch.max_result_ancestors_to_show
    return Math.min(@ancestors.length, max_ancestors_to_show) * indent_px

Template.grid_control_search_dropdown.events
  "click .search-dropdown-nav-link": (e, tpl) ->
    $(".search-dropdown-nav-link").removeClass "active"
    $(e.target).closest(".search-dropdown-nav-link").addClass "active"

    return

  "click .search-result-item": (e, tpl) ->
    APP.modules.project_page.gridControl().activatePath @path 

    return

  "click .filter-item-remove": (e, tpl) ->
    filter_title = @title
    filters_array = tpl.filters.get()
    filters_array = _.filter filters_array, (filter) -> filter.title isnt filter_title
    tpl.filters.set filters_array

    return

  "scroll .search-result-list": (e, tpl) ->
    $list = $(e.target).closest ".search-result-list"

    if Math.round($list.scrollTop() + $list.innerHeight()) >= $list[0].scrollHeight
      tpl.result_count.set tpl.result_count.get() + tpl.result_count_step

    return

  "click .search-show-context-toggle": (e, tpl) ->
    tpl.show_context_rv.set not tpl.show_context_rv.get()

    return
