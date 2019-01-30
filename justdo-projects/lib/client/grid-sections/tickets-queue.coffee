TicketsQueueSection = (grid_data_obj, section_root, section_obj, options) ->
  GridData.sections_managers.NaturalCollectionSubtreeSection.call @, grid_data_obj, section_root, section_obj, options

  return @

Util.inherits TicketsQueueSection, GridData.sections_managers.NaturalCollectionSubtreeSection

_.extend TicketsQueueSection.prototype,
  # fetch only the _id field so invalidation will occur only when items set changes
  rootItems: -> APP.projects.modules.tickets_queues.getTicketsQueues()
  fallbackItemsDictionary: -> APP.projects.modules.tickets_queues.getTicketsQueues()
  yield_root_items: true
  itemsTypesAssigner: (item_obj, relative_path) ->
    if GridData.helpers.getPathLevel(relative_path) == 0
      return "ticket-queue-caption"

    return null

GridData.installSectionManager("TicketsQueueSection", TicketsQueueSection)
