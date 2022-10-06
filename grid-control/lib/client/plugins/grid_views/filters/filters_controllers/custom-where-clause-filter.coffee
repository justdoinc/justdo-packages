CustomWhereClauseFilterControllerConstructor = (context) ->
  GridControl.FilterController.call this

  @grid_control = context.grid_control
  @column_settings = context.column_settings
  @column_filter_state_ops = context.column_filter_state_ops

  filter_settings_options = @column_settings?.filter_settings?.options

  @filter_settings_options = _.extend {}, default_filter_options, filter_settings_options

  @controller = $("""<div class="custom-where-clause-filter-controller">NOTHING TO SEE HERE</div>""")

  @refresh_state()

  return @

Util.inherits CustomWhereClauseFilterControllerConstructor, GridControl.FilterController

_.extend CustomWhereClauseFilterControllerConstructor.prototype,
  refresh_state: ->
    return

  destroy: ->
    return
#
# stateToQuery
#
columnFilterStateToQuery = (column_filter_state, context) ->
  query = {
    _id: {$ne: Math.random()} # EJSONing the query with the $where clause only will result in an empty object, since functions aren't being EJSONified.
                              # We add this _id as a hack to force the eventual reactive var that we are setting down the road to trigger
                              # invalidation.
    $where: context.column_schema_definition?.grid_column_filter_settings?.options?.filterStateToWhereClauseFunction(column_filter_state)
  }

  return query

getSelectAllFilterState = (context) ->
  result = {relative_ranges: []} # At the moment, only relative-range filter options are supported.

  filter_options = context.column_schema_definition.grid_column_filter_settings.options.filter_options
  for filter_option in filter_options
    if filter_option.type != "relative-range"
      console.error "Unknown filter_option type: filter_option.type"

      return

    result.relative_ranges.push filter_option.id

  return result

GridControl.installFilterType "custom-where-clause-filter",
  controller_constructor: CustomWhereClauseFilterControllerConstructor
  column_filter_state_to_query: columnFilterStateToQuery
  getSelectAllFilterState: getSelectAllFilterState
