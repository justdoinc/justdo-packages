JustdoProjectsDetachedDataSubTreesSection = (grid_data_obj, section_root, section_obj, options) ->
  GridData.sections_managers.DetachedDataSubTreesSection.call @, grid_data_obj, section_root, section_obj, options

  return @

Util.inherits JustdoProjectsDetachedDataSubTreesSection, GridData.sections_managers.DetachedDataSubTreesSection

_.extend JustdoProjectsDetachedDataSubTreesSection.prototype,
  isPseudoParentId: (parent_id) ->
    #
    # Regard direct tasks parents (id prefixed with "direct:") as pseudo
    # parents 
    #
    if parent_id.substr(0, 7) == "direct:"
      return true

    if parent_id of APP.projects.modules.tickets_queues.getTicketsQueues()
      return true

    return false

GridData.installSectionManager("JustdoProjectsDetachedDataSubTreesSection", JustdoProjectsDetachedDataSubTreesSection)
