_.extend JustdoGridVisualization.prototype,

  computeGridData: (root_path, root_item, grid_control) ->
    path_metadata = {}
    path_part_regex = /[^\/]+\/$/

    populatePathMetadata = (item, path, is_section, original_path) =>
      if not path_metadata[path]?
        path_metadata[path] = {}

      if is_section and not original_path?
        path_metadata[path].is_section = is_section

      if original_path?
        path_metadata[path].has_children = true

      if item.due_date?
        end_date = moment(item.due_date)
        if not original_path?
          path_metadata[path].end_date = end_date
          path_metadata[path].end_date_source = "original"
        else if not path_metadata[path].end_date?
          path_metadata[path].end_date = end_date
          path_metadata[path].end_date_source = "implied"
        else if path_metadata[path].end_date_source == "implied"
          path_metadata[path].end_date = moment.max(end_date, path_metadata[path].end_date)
          path_metadata[path].end_date_source = "implied"

      if path.match(path_part_regex)
        if not original_path?
          original_path = path
        path = path.replace(path_part_regex, "")

        populatePathMetadata(item, path, is_section, original_path)

    getPathMetadata = (path, field) =>
      if (result = path_metadata[path]?[field])?
        return result
      if path.match(path_part_regex)
        path = path.replace(path_part_regex, "")
        return getPathMetadata(path, field)

      return

    if root_item? and root_path?
      populatePathMetadata(root_item, root_path)

    grid_control.each root_path, { expand_only: false, filtered_tree: true }, (section, item_type, item_obj, path) =>
      populatePathMetadata(item_obj, path, item_type?)

    # If there are any end dates in the tree the root is guarenteed to have an
    # end date
    if not getPathMetadata("/", "end_date")
      return { errors: [ { message: "no-date" } ] }

    errors = []
    results = []
    root_is_section = _.findWhere(grid_control.sections, { path: root_path })?

    if (root_item_start_date = root_item?.start_date)?
      min_date = moment(root_item_start_date)
    else
      min_date = null
      
    if (root_item_due_date = root_item?.due_date)?
      max_date = moment(root_item_due_date)
    else
      max_date = null

    populateResultItem = (section, item_type, item_obj, path) =>
      title = (item_obj.title or "").substr(0, 80)
      end_date = getPathMetadata(path, "end_date")
      end_date_is_implied = path_metadata[path]?.end_date_source != "original"
      is_section = path_metadata[path]?.is_section or false
      has_children = path_metadata[path]?.has_children or false
      error = ''

      if is_section and not has_children
        return

      if not end_date?
        return

      if item_obj.seqId?
        title = "##{item_obj.seqId}: #{title}"

      # date_parts = []
      # if start_date?
      #   date_parts.push start_date.format("MM-DD-YYYY")
      # if end_date?
      #   date_parts.push end_date.format("MM-DD-YYYY")
      # if date_parts.length != 0
      #   title = "#{title} (#{date_parts.join(" - ")})"

      if (path_parts = path.match(/\//g))?
        # The root will return a length of 1 and items under the root will
        # return a length of 2. We want to add bullet characters only for
        # child items e.g. items with a parent other than the root
        depth = path_parts.length - 1
        root_depth = root_path.match(/\//g)?.length or 1
        while depth > root_depth
          depth = depth - 1
          title = "• #{title}"

      start_date_implied = true
      if item_obj.start_date?
        start_date = moment(item_obj.start_date)
        start_date_implied = false

      if start_date? and (not min_date? or start_date < min_date)
        min_date = start_date

      if end_date? and (not max_date? or end_date > max_date)
        max_date = end_date

      if not start_date?
        start_date = end_date
      if start_date > end_date
        start_date = end_date
        if not end_date_is_implied
          errors.push { task_id: item_obj._id, message: "start-end-dates-reversed" }


      if start_date?.isSame(end_date)
        # To make the task appear wider, just widen the window
        # start_date = end_date.clone().add(-24, 'hour')

        end_date = end_date.clone().add(1, 'hour')

      if not end_date.isValid()
        errors.push { task_id: item_obj._id, message: "invalid-end-date" }
      if not start_date.isValid()
        errors.push { task_id: item_obj._id, message: "invalid-start-date" }

      start = start_date?.clone().set('hours', 8).set('minutes', 0).toDate()
      if start_date_implied
        start = end_date?.clone().set('hours', 18).set('minutes', 59).toDate()

      results.push
        title: title
        error: error
        start_date: start
        end_date: end_date?.clone().set('hours', 19).set('minutes', 0).toDate()
        start_date_implied: start_date_implied
    grid_control.each root_path, { expand_only: true, filtered_tree: true }, populateResultItem

    if results.length == 0
      populateResultItem(null, null, root_item, root_path)

    results.min_date = min_date
    results.max_date = max_date

    if errors.length
      return { errors: errors }

    return results
