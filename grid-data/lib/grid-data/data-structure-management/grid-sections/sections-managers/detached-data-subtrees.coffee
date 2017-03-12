default_options =
  # Note additional default options are defined in the NaturalCollectionSubtreeSection
  # level

  # If your project has pseudo parents (read about pseudo parents below
  # under @_isPseudoParentId()) other than "0", you can use the 
  # isPseudoParentId option to set a method that gets as a parameter
  # a parent id and should return true if it's a pseudo parent id
  # false otherwise.
  #
  # the method will be called with @ set to the section manager object.
  isPseudoParentId: null

DetachedDataSubTreesSection = (grid_data_obj, section_root, section_obj, options) ->
  @options = _.extend {}, default_options, options

  @isPseudoParentId = @options.isPseudoParentId

  PACK.sections_managers.NaturalCollectionSubtreeSection.call @, grid_data_obj, section_root, section_obj, options

  return @

PACK.sections_managers.DetachedDataSubTreesSection = DetachedDataSubTreesSection

Util.inherits DetachedDataSubTreesSection, PACK.sections_managers.NaturalCollectionSubtreeSection

_.extend DetachedDataSubTreesSection.prototype,
  rootItems: ->
    # Note, we don't need to worry about triggering reactivity here,
    # since any change to the core grid data structures (that are in
    # charge of updating @grid_data.detaching_items_ids) will trigger
    # grid data's @_rebuildSections() which will rebuild the entire
    # tree.
    return @grid_data.detaching_items_ids

  _isPseudoParentId: (parent_id) ->
    # Pseudo parent id is a parent that is not existing in the DB
    # (hence "pseudo") but its logic is implemented by us examples are:
    # the root item "0" and JustDo projects' implementation of direct
    # task where a direct task is a task with a parent of the form:
    # "direct:{project user id}"
    #
    # We don't regard pseudo parents as detaching items
    #
    # When inheriting from this constructor, you can set a method to @isPseudoParentId()
    # to add more logic for pseudo parents ids recognition in accordance with your
    # project needs - avoid changing this one (as it is very unlikely you'd want to regard
    # "0" as a non-pseudo item).
    #
    # You can also set @isPseudoParentId without inheriting by passing it as parameter
    # to the constructor, see default_options above.
    #
    # In the justdo project, we use the isPseudoParentId option to define direct tasks
    # parents as pseudo parents, you can use it as an example.
    #
    # Returns true if parent_id is pseudo parent, false otherwise
    if parent_id == "0"
      return true

    if @isPseudoParentId?
      if @isPseudoParentId(parent_id)
        return true

    return false

  itemObjHasKnownParents: (item_obj) ->
    # Called by top_level_items_filter methods
    # returns true if any of item_obj parents is a known item (exists
    # in @grid_data.items_by_id) or a pseudo item that should be
    # regarded as existing (as defined by @_isPseudoParentId())
    for parent_id, order of item_obj.parents
      if parent_id of @grid_data.items_by_id or @_isPseudoParentId(parent_id)
        return true
    return false

  rootItemsFilter: (detaching_items_ids) ->
    # Documented in NaturalCollectionSubtreeSection source

    #
    # implement the logic to avoid regarding pseudo parents as detaching items
    # (even though, from the grid data perspective they are part of
    # @grid_data.detaching_items_ids).
    #

    # Copy
    detaching_items_ids = _.extend {}, detaching_items_ids

    for item_id, val of detaching_items_ids
      # Note, val has no meaning in this implementation

      if @_isPseudoParentId(item_id)
        delete detaching_items_ids[item_id]

    return detaching_items_ids

  # Documented in NaturalCollectionSubtreeSection source
  top_level_items_filter:
    singleItem: (item_id) ->
      if not (item_obj = @grid_data.items_by_id[item_id])?
        # This case shouldn't happen in normal use.
        console.error "DetachedDataSubTreesSection: Couldn't find item #{item_id}"

        return false

      if @itemObjHasKnownParents(item_obj)
        # If we know any of item's parents, it shouldn't be regarded
        # as detached.
        return false
      return true

    allItems: (top_level_items_objs) ->
      top_level_items_objs = _.filter top_level_items_objs, (item_obj) =>
        if @itemObjHasKnownParents(item_obj)
          # If we know any of item's parents, it shouldn't be regarded
          # as detached.
          return false
        return true

      return top_level_items_objs

  yield_root_items: false