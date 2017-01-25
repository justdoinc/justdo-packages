share.installCalculatedFieldFunction "sum",
  (function_options, grid_control, field_id, path, item_obj) ->
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

    # count_of_traversed_items = 0
    sum = 0
    grid_control._grid_data.each path, each_options, (section, item_type, item_obj, item_path) =>
      # count_of_traversed_items += 1
      value = @calculatePathCalculatedFieldValue(grid_control, field_id, item_path, item_obj)

      if (error = value.err)?
        # Report error fields to logger, but ignore them
        grid_control.logger.debug "Failed to calculate calculated field value for field #{field_id} of path #{item_path}, error: #{error}"

        return iteratee_return_value

      if (cval = value.cval)?
        value = cval # If value is output of calculated value field, just take the returned value

      if not value? or value is ""
        return iteratee_return_value

      float_val = parseFloat(value)

      if not _.isNaN float_val
        sum += float_val

      return iteratee_return_value # Don't traverse item children (if any)

    # return "#{sum}|#{count_of_traversed_items}" # useful for debugging

    return "" + sum # XXX Important! the only reason we return this value as string is because print feature currently doesn't show 0 (int) vals, should be fixed.  