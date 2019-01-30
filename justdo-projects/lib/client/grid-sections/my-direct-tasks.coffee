MyDirectTasksSection = (grid_data_obj, section_root, section_obj, options) ->
  GridData.sections_managers.NaturalCollectionSubtreeSection.call @, grid_data_obj, section_root, section_obj, options

  return @

Util.inherits MyDirectTasksSection, GridData.sections_managers.NaturalCollectionSubtreeSection

_.extend MyDirectTasksSection.prototype,
  rootItems: ->
    direct_tasks = @grid_data.tree_structure["direct:#{Meteor.userId()}"]

    # _.invert() returns empty array for undefined input, so no need
    # to worry from situations no direct tasks exists (cases where
    # @grid_data.tree_structure["direct:#{Meteor.userId()}"] is 
    # undefined)
    direct_tasks = _.invert(direct_tasks)

    return direct_tasks

  root_items_sort_by: (item) ->
    # Sort by seqId DESC
    return -1 * item.seqId

  yield_root_items: true

GridData.installSectionManager("MyDirectTasksSection", MyDirectTasksSection)