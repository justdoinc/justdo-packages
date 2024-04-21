generateCommonFilterAwareTreeOpCalculator = (options) ->
  # options is expected to have the following methods:
  #
  # options.memoInit(memo) will be called with an empty object that will be served as a
  # state maintainer for the calculation, you can store anything that will be useful
  # for producing the calculation result.
  #
  # options.iteratee(memo, value) will be called with memo and an encountered value
  #
  # options.resultProducer(memo) should return calculation result

  return (function_options, grid_control, field_id, path, item_obj) ->
    each_options = 
      expand_only: false
      filtered_tree: false

    if function_options?.direct_children_only == false
      iteratee_return_value = 0
    else
      iteratee_return_value = -1 # That's the default option

    if function_options?.filter_aware == true
      each_options.filtered_tree = true
    else
      each_options.filtered_tree = false # That's the default option

    memo = {}

    options.memoInit(memo)
    grid_control._grid_data.each path, each_options, (section, item_type, item_obj, item_path) =>
      value = @calculatePathCalculatedFieldValue(grid_control, field_id, item_path, item_obj)

      if (error = value.err)?
        # Report error fields to logger, but ignore them
        grid_control.logger.debug "Failed to calculate calculated field value for field #{field_id} of path #{item_path}, error: #{error}"

        return iteratee_return_value

      if (cval = value.cval)?
        value = cval # If value is output of calculated value field, just take the returned value

      options.iteratee(memo, value)

      return iteratee_return_value # Don't traverse item children (if any)

    return options.resultProducer(memo)

share.installCalculatedFieldFunction "sum",
  allow_tree_ops: true # Will let the user use the functions: treeXYZ() and childrenXYZ() where XYZ is the field function ID (e.g. treeSum()/childrenSum())
                       # If the 'childrenXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to true
                       # If the 'treeXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to false

  allow_filter_aware: true # Will let the user use the 'filtered' prefixed version of any function already existing: e.g filteredTreeSum()
                           # If the 'filtered' prefixed version is used, function_options will include the option: filter_aware set to true

  func: generateCommonFilterAwareTreeOpCalculator
    memoInit: (memo) ->
      memo.sum = 0

      return

    iteratee: (memo, value) ->
      if not value? or value is ""
        return

      float_val = parseFloat(value)

      if not _.isNaN float_val
        memo.sum += float_val

      return

    resultProducer: (memo) ->
      result = memo.sum

      return "" + result # XXX Important! the only reason we return this value as string is because print feature currently doesn't show 0 (int) vals, should be fixed.

share.installCalculatedFieldFunction "avg",
  allow_tree_ops: true # Will let the user use the functions: treeXYZ() and childrenXYZ() where XYZ is the field function ID (e.g. treeSum()/childrenSum())
                       # If the 'childrenXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to true
                       # If the 'treeXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to false

  allow_filter_aware: true # Will let the user use the 'filtered' prefixed version of any function already existing: e.g filteredTreeSum()
                           # If the 'filtered' prefixed version is used, function_options will include the option: filter_aware set to true

  func: generateCommonFilterAwareTreeOpCalculator
    memoInit: (memo) ->
      memo.sum = 0
      memo.count_of_non_empty_traversed_items = 0

      return

    iteratee: (memo, value) ->
      if not value? or value is ""
        return

      memo.count_of_non_empty_traversed_items += 1

      float_val = parseFloat(value)

      if not _.isNaN float_val
        memo.sum += float_val

      return

    resultProducer: (memo) ->
      if memo.count_of_non_empty_traversed_items == 0
        result = 0
      else
        result = (memo.sum / memo.count_of_non_empty_traversed_items)

      return "" + result # XXX Important! the only reason we return this value as string is because print feature currently doesn't show 0 (int) vals, should be fixed.

share.installCalculatedFieldFunction "median",
  allow_tree_ops: true # Will let the user use the functions: treeXYZ() and childrenXYZ() where XYZ is the field function ID (e.g. treeSum()/childrenSum())
                       # If the 'childrenXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to true
                       # If the 'treeXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to false

  allow_filter_aware: true # Will let the user use the 'filtered' prefixed version of any function already existing: e.g filteredTreeSum()
                           # If the 'filtered' prefixed version is used, function_options will include the option: filter_aware set to true

  func: generateCommonFilterAwareTreeOpCalculator
    memoInit: (memo) ->
      memo.results = []

      return

    iteratee: (memo, value) ->
      if not value? or value is ""
        return

      float_val = parseFloat(value)

      if not _.isNaN float_val
        memo.results.push(float_val)

      return

    resultProducer: (memo) ->
      results = memo.results
      results_length = results.length

      results.sort()

      if results_length == 0
        result = ""
      else if results_length % 2 == 1
        result = results[Math.floor(results_length / 2)]
      else
        result = (results[Math.floor(results_length / 2)] + results[Math.ceil(results_length / 2) - 1]) / 2

      return "" + result # XXX Important! the only reason we return this value as string is because print feature currently doesn't show 0 (int) vals, should be fixed.

share.installCalculatedFieldFunction "min",
  allow_tree_ops: true # Will let the user use the functions: treeXYZ() and childrenXYZ() where XYZ is the field function ID (e.g. treeSum()/childrenSum())
                       # If the 'childrenXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to true
                       # If the 'treeXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to false

  allow_filter_aware: true # Will let the user use the 'filtered' prefixed version of any function already existing: e.g filteredTreeSum()
                           # If the 'filtered' prefixed version is used, function_options will include the option: filter_aware set to true

  func: generateCommonFilterAwareTreeOpCalculator
    memoInit: (memo) ->
      memo.min = null

      return

    iteratee: (memo, value) ->
      if not value? or value is ""
        return

      float_val = parseFloat(value)

      if not _.isNaN float_val
        if not memo.min? or memo.min > float_val
          memo.min = float_val

      return

    resultProducer: (memo) ->
      if memo.min isnt null
        result = memo.min
      else
        result = ""

      return "" + result # XXX Important! the only reason we return this value as string is because print feature currently doesn't show 0 (int) vals, should be fixed.

share.installCalculatedFieldFunction "max",
  allow_tree_ops: true # Will let the user use the functions: treeXYZ() and childrenXYZ() where XYZ is the field function ID (e.g. treeSum()/childrenSum())
                       # If the 'childrenXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to true
                       # If the 'treeXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to false

  allow_filter_aware: true # Will let the user use the 'filtered' prefixed version of any function already existing: e.g filteredTreeSum()
                           # If the 'filtered' prefixed version is used, function_options will include the option: filter_aware set to true

  func: generateCommonFilterAwareTreeOpCalculator
    memoInit: (memo) ->
      memo.max = null

      return

    iteratee: (memo, value) ->
      if not value? or value is ""
        return

      float_val = parseFloat(value)

      if not _.isNaN float_val
        if not memo.max? or memo.max < float_val
          memo.max = float_val

      return

    resultProducer: (memo) ->
      if memo.max isnt null
        result = memo.max
      else
        result = ""

      return "" + result # XXX Important! the only reason we return this value as string is because print feature currently doesn't show 0 (int) vals, should be fixed.

share.installCalculatedFieldFunction "count",
  allow_tree_ops: true # Will let the user use the functions: treeXYZ() and childrenXYZ() where XYZ is the field function ID (e.g. treeSum()/childrenSum())
                       # If the 'childrenXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to true
                       # If the 'treeXYZ' is used function_options will include the options: process_sub_tree: true, direct_children_only set to false

  allow_filter_aware: true # Will let the user use the 'filtered' prefixed version of any function already existing: e.g filteredTreeSum()
                           # If the 'filtered' prefixed version is used, function_options will include the option: filter_aware set to true

  func: generateCommonFilterAwareTreeOpCalculator
    memoInit: (memo) ->
      memo.count = 0

      return

    iteratee: (memo, value) ->
      memo.count += 1

      return

    resultProducer: (memo) ->
      result = memo.count

      return "" + result # XXX Important! the only reason we return this value as string is because print feature currently doesn't show 0 (int) vals, should be fixed.
