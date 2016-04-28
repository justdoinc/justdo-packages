DetachedDataSubTreesSection = (grid_data_obj, section_root, section_obj, options) ->
  PACK.sections_managers.NaturalCollectionSubtreeSection.call @, grid_data_obj, section_root, section_obj, options

  return @

PACK.sections_managers.DetachedDataSubTreesSection = DetachedDataSubTreesSection

Util.inherits DetachedDataSubTreesSection, PACK.sections_managers.NaturalCollectionSubtreeSection

_.extend DetachedDataSubTreesSection.prototype,
  rootItems: -> @grid_data.detaching_items_ids
  yield_root_items: false