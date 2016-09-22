QuerySection = (grid_data_obj, section_root, section_obj, options) ->
  options = @_prepareOptions(options)

  PACK.sections_managers.NaturalCollectionSubtreeSection.call @, grid_data_obj, section_root, section_obj, options

  return @

PACK.sections_managers.QuerySection = QuerySection

Util.inherits QuerySection, PACK.sections_managers.NaturalCollectionSubtreeSection

_.extend QuerySection.prototype,
  yield_root_items: true

  _prepareOptions: (options) ->
    options = _.extend {}, options

    # We allow users of QuerySection to use the following options
    # aliases:

    # options.query -> options.rootItems 
    if (query = options.query)?
      options.rootItems = query
      delete options.query

    # options.sortBy -> options.root_items_sort_by 
    if (sortBy = options.sortBy)?
      options.root_items_sort_by = sortBy
      delete options.root_items_sort_by

    return options