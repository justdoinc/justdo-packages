Template.tasks_list_widget.onCreated ->
  tpl = @

  tpl.search_input_rv = new ReactiveVar ""

Template.tasks_list_widget.onRendered ->
  tpl = @

  tpl.$(".tasks-list-widget").on "shown.bs.dropdown", ->
    tpl.$(".tasks-list-widget-search").focus()
    return

  tpl.$(".tasks-list-widget").on "hidden.bs.dropdown", ->
    tpl.search_input_rv.set ""
    tpl.$(".tasks-list-widget-search").val null
    return

Template.tasks_list_widget.helpers
  filterTasks: ->
    tpl = Template.instance()

    if not (search_input = tpl.search_input_rv.get())?
      @filtered_tasks = @tasks
      return @

    filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(search_input)}", "i")
    @filtered_tasks = _.filter @tasks, (doc) ->  filter_regexp.test(doc.title)

    return @

Template.tasks_list_widget.events
  "keyup .tasks-list-widget-search": (e, tpl) ->
    value = $(e.target).val().trim()

    if _.isEmpty value
      tpl.search_input_rv.set null

    tpl.search_input_rv.set value

    return
  
  "keydown .tasks-list-widget .dropdown-menu": (e, tpl) ->
    $dropdown_item = $(e.target).closest(".tasks-list-widget-search, .dropdown-item")

    if e.which == 38 # Up
      e.preventDefault()

      if ($prev_item = $dropdown_item.prevAll(".dropdown-item").first()).length > 0
        $prev_item.focus()
      else
        tpl.$(".tasks-list-widget-search", $dropdown_item.closest(".tasks-list-widget")).focus()

    if e.which == 40 # Down
      e.preventDefault()
      $dropdown_item.nextAll(".dropdown-item").first().focus()

    if e.which == 27 # Escape
      tpl.$(".tasks-list-widget button").dropdown "hide"

    return
  
  "click .js-kanban-selected-task": (e, tpl) ->
    e.preventDefault()
    if tpl.data.onItemClick?
      tpl.data.onItemClick @_id
    return