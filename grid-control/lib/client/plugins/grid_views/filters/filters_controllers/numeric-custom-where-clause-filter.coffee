columnFilterStateToQuery = (column_filter_state, context) ->
  ranges_query = GridControl.NumericFilterControllerColumnFilterStateToQuery(column_filter_state, context)
  ranges = []
  if _.isArray(ranges_query?.$or)
    for query in ranges_query.$or
      start = query[context.column_id]?.$gte or null
      end = query[context.column_id]?.$lte or null
      ranges.push([start, end])

  query = {
    _id: {$ne: Math.random()} # EJSONing the query with the $where clause only will result in an empty object, since functions aren't being EJSONified.
                              # We add this _id as a hack to force the eventual reactive var that we are setting down the road to trigger
                              # invalidation.
    $where: context.column_schema_definition?.grid_column_filter_settings?.options?.numberRangeToWhereClauseFunction(ranges)
  }

  return query

GridControl.installFilterType "numeric-custom-where-clause-filter",
  controller_constructor: GridControl.NumericFilterControllerConstructor
  getSelectAllFilterState: GridControl.NumericFilterControllerGetSelectAllFilterState
  column_filter_state_to_query: columnFilterStateToQuery
