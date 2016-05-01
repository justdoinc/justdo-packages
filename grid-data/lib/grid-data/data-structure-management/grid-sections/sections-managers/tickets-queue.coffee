TicketsQueueSection = (grid_data_obj, section_root, section_obj, options) ->
  PACK.sections_managers.NaturalCollectionSubtreeSection.call @, grid_data_obj, section_root, section_obj, options

  return @

PACK.sections_managers.TicketsQueueSection = TicketsQueueSection

Util.inherits TicketsQueueSection, PACK.sections_managers.NaturalCollectionSubtreeSection

_.extend TicketsQueueSection.prototype,
  # fetch only the _id field so invalidation will occur only when items set changes
  rootItems: -> _.indexBy @grid_data.collection.find({is_tickets_queue: true}, {fields: {_id: 1}}).fetch(), "_id"
  yield_root_items: true