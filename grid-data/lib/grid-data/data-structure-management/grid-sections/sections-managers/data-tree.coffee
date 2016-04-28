DataTreeSection = (grid_data_obj, section_root, section_obj, options) ->
  PACK.sections_managers.NaturalCollectionSubtreeSection.call @, grid_data_obj, section_root, section_obj, options

  return @

PACK.sections_managers.DataTreeSection = DataTreeSection

Util.inherits DataTreeSection, PACK.sections_managers.NaturalCollectionSubtreeSection