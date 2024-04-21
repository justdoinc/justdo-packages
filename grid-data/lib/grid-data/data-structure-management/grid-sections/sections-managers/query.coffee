QuerySection = (grid_data_obj, section_root, section_obj, options) ->
  options = @_prepareOptions(options)

  GridData.sections_managers.NaturalCollectionSubtreeSection.call @, grid_data_obj, section_root, section_obj, options

  return @

Util.inherits QuerySection, GridData.sections_managers.NaturalCollectionSubtreeSection

_.extend QuerySection.prototype,
  yield_root_items: true

  _prepareOptions: (options) ->
    options = _.extend {}, options

    # We allow users of QuerySection to use the following options
    # aliases:

    # options.query -> options.rootItems 
    if (query = options.query)?
      # Note: `this` in query will be the section's
      # obj, i.e. you can bind to the sections events
      options.rootItems = query
      delete options.query

    # options.sortBy -> options.root_items_sort_by 
    if (sortBy = options.sortBy)?
      options.root_items_sort_by = sortBy
      delete options.root_items_sort_by

    return options

GridData.installSectionManager("QuerySection", QuerySection)