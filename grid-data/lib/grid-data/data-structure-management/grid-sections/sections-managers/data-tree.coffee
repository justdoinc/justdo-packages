DataTreeSection = (grid_data_obj, section_root, section_obj, options) ->
  GridData.sections_managers.NaturalCollectionSubtreeSection.call @, grid_data_obj, section_root, section_obj, options

  return @

Util.inherits DataTreeSection, GridData.sections_managers.NaturalCollectionSubtreeSection

GridData.installSectionManager("DataTreeSection", DataTreeSection)
