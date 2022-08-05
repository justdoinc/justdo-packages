helpers = share.helpers

GridData.sections_managers = {} # Expose sections_managers through GridData to make it available to external uses

GridData.installSectionManager = (section_manager_id, constructor) ->
  GridData.sections_managers[section_manager_id] = constructor

  return

forbidden_section_names = ["global"] # global is forbidden since it is used under _sections_state to store global state vars

hyphen_separated_name_regex = /^[a-z0-9-]+$/i
lowercase_hyphen_separated_name_regex = /^[a-z0-9-]+$/

_.extend GridData.prototype,
  _initGridSections: ->
    if not @options.sections?
      throw @_error "required-option-missing", "Can't find sections configuration in @options.sections"

    # @options.sections can be an array of sections definitinos of the form defined
    # under: grid-data/lib/grid-data/data-structure-management/grid-sections/README.md
    # Or a reactive resource that returns such an array.
    if _.isArray @options.sections
      @sections_def = @options.sections
    else if _.isFunction @options.sections
      initiated = false
      @sections_def_comp = Tracker.autorun =>
        @sections_def = @options.sections()

        if initiated
          # On the first run, no need to call @_rebuildSections(), only
          # on invalidations
          @_loadSectionsOption()

          @_rebuildGridTree()
        else
          initiated = true

        return

      @onDestroy =>
        @sections_def_comp.stop()

        return
    else
      throw @_error "wrong-type", "Wrong type provided to options.sections, should be a function or an array"

    # Sections state is a framework  that provides a session-
    # persistent and reactive mechanism to maintain a state of
    # variables that affect the operation of a section.
    #
    # Sections states can be specific to a section or global to all
    # the section of the current grid-data.
    #
    # By using the exportSectionsState() and setSectionsState() tools
    # can be implemented, in levels higher than GridData, to maintain
    # sections state across sessions.
    #
    # Structure:
    # {
    #   "section-id": {
    #     "state-var": ReactiveVar()
    #   }, ...
    # }
    #
    # Notes:
    #   * At the moment, state-vars values can only of Strings
    #   * All state vars are reactive vars that uses the default
    #   equalsFunc (for simplicity of implementation) 
    #   * Global sections state are stored under "global" prop, note
    #   a section can't be given the id "global", so no risk of
    #   collision 
    @_sections_state = {}
    # this dependency will change on any change to @_sections_state
    # without it we can only be reactive to changes to existing sections
    # state vars, but not to new vars/removed vars.
    # Important! doesn't reactive to changes in the reactive vars
    # values, only to the @_sections_state structure
    @_sections_state_structure_dep = new Tracker.Dependency()

    @_loadSectionsOption()

    @_registerSectionsMetadataGenerator()

    return

  _requireValidSectionId: (section_id) ->
    if not hyphen_separated_name_regex.test(section_id)
      throw @_error "invalid-section-id"

  _loadSectionsOption: ->
    sections_configuration = []

    for section in @sections_def
      #
      # Deep copy
      #
      section = _.clone section

      for prop in ["section_manager_options", "options"]
        if (prop_val = section[prop])?
          section[prop] = _.clone prop_val

      #
      # validate
      #
      for prop in ["id", "section_manager"]
        if not section[prop]?
          throw @_error "invalid-option", "Each section defintion must have section.#{prop} defined"

      if section.id in forbidden_section_names
        throw @_error "forbidden-section-id", "`#{section.id}' is not allowed as section id"

      @_requireValidSectionId(section.id)

      #
      # normalize
      #
      for prop in ["section_manager_options", "options"]
        if not section[prop]?
          section[prop] = {}

      # set section path - Note getPathSection rely on the assumption that sections paths
      # level is 1 or 0 (main), take into account efficiency of getPathSection if you want
      # to change this behavior (profile _.each with filtered_tree: true option well)
      section.path = if section.id == "main" then "/" else "/#{section.id}/"

      #
      # defaults optins
      #
      default_options =
        section_item_title: JustdoHelpers.ucFirst(JustdoHelpers.dashSepTo(" ", section.id))
        permitted_depth: -1 # refer to README for more details  
        expanded_on_init: false

      section.options = _.extend {}, default_options, section.options

      # if section_manager is a string, see if we have a corresponding built-in, otherwise
      # make sure it is a function (constructor)
      section_manager = section.section_manager
      if _.isString section_manager
        if GridData.sections_managers[section_manager]?
          section.section_manager = GridData.sections_managers[section_manager]
        else
          throw @_error "unknown-section-manager-type"
      else if not _.isFunction section_manager
        throw @_error "unknown-section-manager-type"

      if section.options.expanded_on_init
        @expandPath(section.path, true)

      section.options?.sectionInit?.call(@, section)

      sections_configuration.push section

    @sections_configuration = sections_configuration

    return

  _registerSectionsMetadataGenerator: ->
    @registerMetadataGenerator (item, ext, index) =>
      # Add a class with the item's section id and the movable class, if movable
      classes = ["section-#{ext[4].id}"]

      if @getItemIsMovable(index) >= 0
        classes.push "movable"

      return {cssClasses: classes}

    return

  stateVarExist: (section_id, var_name) ->
    return @_sections_state[section_id]?[var_name]?

  setStateVar: (section_id, var_name, new_val, regard_as_default_value=false) ->
    # Use section_id = "global" for global sections state
    #
    # All state vars are reactive vars that uses the default
    # equalsFunc (for simplicity of implementation)
    #
    # Setting a state var to null will undefine it:
    # * We will set the reactive var to null - to trigger
    # reactivity for resources that were depending on
    # it, and then
    # * Remove its reference from @_sections_state and trigger
    # @_sections_state_structure_dep.change() to notify
    # the structure change.

    if not section_id? or not var_name?
      throw @_error "missing-argument", "Provide section_id and var_name"

      return

    # validations
    @_requireValidSectionId(section_id)

    if not lowercase_hyphen_separated_name_regex.test(var_name)
      throw @_error "invalid-section-var-name"

    if new_val == null
      # Unset section_id, var_name

      if not @stateVarExist(section_id, var_name)
        @logger.debug "Section's #{section_id} var #{var_name} is already undefined"

        return
      else
        # First set var value to null to invalidate
        # computations that uses its value
        @_sections_state[section_id][var_name].set(null) 

        # Second, update structure
        delete @_sections_state[section_id][var_name]
        if _.isEmpty @_sections_state[section_id]
          delete @_sections_state[section_id]
        @_sections_state_structure_dep.changed()

        return

    if typeof new_val != "string"
      throw @_error "wrong-type", "At the moment, state variables can hold only Strings"

      return

    if not @stateVarExist(section_id, var_name)
      Meteor._ensure @_sections_state, section_id

      @_sections_state[section_id][var_name] = new ReactiveVar(new_val)

      @_sections_state_structure_dep.changed()
    else
      @_sections_state[section_id][var_name].set(new_val)

    @emit "section-state-var-set", section_id, var_name, new_val, regard_as_default_value

    return

  unsetStateVar: (section_id, var_name, regard_as_default_value=false) ->
    @setStateVar section_id, var_name, null, regard_as_default_value

  getStateVar: (section_id, var_name, default_val) ->
    # If var_name doesn't exist, we init it with default_val
    # if default_val isn't provided, we will return undefined
    #
    # Reactivity:
    # If var_name doesn't exist for the section, we depend
    # on _sections_state_structure_dep
    # Otherwise reactivity depends only on changes to the
    # var_name's value.

    if not @stateVarExist(section_id, var_name)
      if not default_val?
        # Depend on @_sections_state_structure_dep
        # so if later state var will be created, we will
        # load it
        @_sections_state_structure_dep.depend()

        return undefined
      else # default_val provided, use it as init value
        @setStateVar(section_id, var_name, default_val, true)

    return @_sections_state[section_id][var_name].get()

  globalStateVarExist: (var_name) ->
    return @stateVarExist("global", var_name)

  setGlobalStateVar: (var_name, new_val) ->
    return @setStateVar("global", var_name, new_val)

  unsetGlobalStateVar: (var_name) ->
    return @setGlobalStateVar(var_name, null)

  getGlobalStateVar: (var_name, default_val) ->
    return @getStateVar("global", var_name, default_val)

  exportSectionsState: ->
    # Note, reactive to all sections state reactive var!
    # you might want to run in a nonreactive context.
    @_sections_state_structure_dep.depend()

    export_obj = {}

    for section_id, section_state of @_sections_state
      section_export = export_obj[section_id] = {}

      for var_name, var_reactive_var of section_state
        section_export[var_name] = var_reactive_var.get()

    return export_obj

  setSectionsState: (state_obj, replace=true, regard_as_default_value=false) ->
    # If replace is true, the new_sections_state will be used instead of the
    # current sections state.
    # If replace is false, only listed sections state vars will
    # be affected. (similar to _.expand() operation on current state)

    if replace
      # begin from removing state vars that are not
      # present in the new state_obj
      for section_id, section_state of @_sections_state
        for var_name, var_value of section_state
          if not state_obj[section_id]?[var_name]?
            # If a current section var is no longer listed
            # in the new state_obj, remove it.
            @unsetStateVar section_id, var_name, regard_as_default_value

    # Update new sections state values
    for section_id, section_state of state_obj
      for var_name, var_value of section_state
        @setStateVar section_id, var_name, var_value, regard_as_default_value

    return

  _addItem: (item_obj, absolute_path, expand_state, section) ->
    # adds an item to @grid_tree, returns the item index
    item_entry = [
      item_obj,
      helpers.getPathLevel(absolute_path),
      absolute_path,
      expand_state,
      section
    ]

    return @grid_tree.push(item_entry) - 1

  _registerCollectionItemIndex: (index, item_id) ->
    if not @_items_ids_map_to_grid_tree_indices[item_id]?
      @_items_ids_map_to_grid_tree_indices[item_id] = []
    @_items_ids_map_to_grid_tree_indices[item_id].push(index)

  _addCollectionItem: (item_obj, absolute_path, expand_state, section) ->
    # adds a data item to @grid_tree
    index = @_addItem(item_obj, absolute_path, expand_state, section)

    @_registerCollectionItemIndex(index, item_obj._id)

    return index

  _addTypedItem: (type, item_obj, absolute_path, expand_state, section) ->
    # adds a typed item to @grid_tree

    # type should be dash separated

    if not _.isString(type)
      throw @_error "missing-argument", "Typed item must have a type"

    # Important! we rely on the js inheritence feature here in some situations.
    # For example, typed items that have the is_collection_item set to true:
    # When we update specific fields, we just update the original item_obj,
    # (event grid-item-changed) and do not trigger a rebuild. In such a case
    # we rely on the inheritence feature to keep the item up-to-date when
    # getItem() is call by slick grid.
    item_obj = Object.create(item_obj) # Add the "metadata layer" by inheriting provided obj
                                       # note: GridData's core-api implements @getItemExcludingMetadataLayer()
                                       # that returns the item_obj sans the metadata layer.

    if (getForcedItemFields = @items_types_settings[type].getForcedItemFields)?
      _.extend item_obj, getForcedItemFields(type, item_obj, absolute_path, expand_state, section)

    # Set after getForcedItemFields to prevent ability to override.
    item_obj._type = type

    index = @_addItem(item_obj, absolute_path, expand_state, section)

    @_typed_items_paths_map_to_grid_tree_indices[absolute_path] = index

    if @items_types_settings[type]?.is_collection_item
      @_registerCollectionItemIndex(index, item_obj._id)

    return index

  _addSectionItem: (section_obj) ->
    if section_obj.id == PACK.main_section_id
      # No section item for Main Section
      return null

    {show_if_empty} = section_obj.options

    if not show_if_empty? or not show_if_empty
      {section_manager} = section_obj

      has_items = false
      section_manager._each "/", {expand_only: false, filtered_tree: true}, (section, item_type, item_obj, absolute_path, expand_state) =>
        has_items = true

        return -2

      if not has_items
        # section_obj.id doesn't show if empty

        return

    item_obj =
      title: section_obj.options.section_item_title

    absolute_path = section_obj.path

    return @_addTypedItem "section-item", item_obj, absolute_path, section_obj.expand_state, section_obj

  _each: (absolute_path, options, iteratee, root_path_refers_to_main_section=false) ->
    # _each(absolute_path, options, iteratee)
    #
    # Traverse the section items in the given path
    #
    # absolute_path: If "/" is given, all items of all sections will be traversed
    #                unless root_path_refers_to_main_section is set to true, in which
    #                case only the main section's items will be yielded.
    #
    # options:
    #
    # * expand_only (default: false): if true the method will regard non-expanded paths as
    # leaves.
    # * filtered_tree (default: false): if true,
    #   the method won't yield paths that haven't passed the filter or doesn't have a descendant
    #   that passed the filter.
    #   Note: Non-reactive.
    #
    # Call iteratee for every item as follow:
    #
    #   iteratee(section, item_type, item_obj, path, expand_state)
    #
    #   section:      path's section obj
    #   item_type:    null or undefined if item_obj is a document of grid_data's
    #                 @collection. Otherwise will hold a string with
    #                 the item type.
    #   item_obj:     the item object
    #   path:         the item's path under the root tree
    #   expand_state: 
    #     * **Defined only if options are: `{expand_only: true, filtered_tree: false}` , in all
    #       other cases will be undefined.**
    #     * If options are: `{expand_only: true, filtered_tree: false}` will be:  -1 if item has
    #       no children, 0 if collapsed, 1 if expanded If filtered_tree option is set to true the
    #       state will be according to the filtered tree and not the regular tree. i.e. if item `a`
    #       passed the filter and is collapsed, if all `a`s items are filtered out its state will
    #       be -1.
    #
    #     Note: the reason we provide the expand_state only for the specified options is that this
    #     is the only case where finding the expand state is O(1) complexity , in all other cases,
    #     finding the expand state is CPU expensive, and should be done only if needed, using the
    #     `gc._grid_data. filterAwareGetPathExpandState(path)`.
    #
    #   if iteratee returns:
    #     -1: traversing won't attempt to step into item's under the
    #     current item
    #     -2: traversing will stop immediately
    #
    # IMPORTANT: You should ignore the value returned from _each, it has only internal
    #            meaning to control the stopping of the tree traverse

    # Note, we don't apply default options on input on purpose, as we want to keep
    # this method as efficient as possible.

    #
    # Traverse the filtered tree
    #
    if options.filtered_tree
      if not _.isArray @_grid_tree_filter_state
        # @logger.warn "_each: options.filtered_tree is true but no filter is set, ignoring"

        options.filtered_tree = false
      else
        # If filtered_tree option is true, replace received iteratee with a version
        # that takes care of skipping paths outside the filtered tree.
        original_iteratee = iteratee

        self = @ # Use self instead of `=>` for efficiency
        iteratee = (section, item_type, item_obj, path, expand_state) ->
          # due to optimizations done below, we know for sure that if this iteratee
          # and not the original got called, expand_only option is false.
          #
          # Because of that we know for sure that expand_state should be undefined
          expand_state = undefined

          if self.pathPassFilter(path) or (has_passing_filter_descendants = section.section_manager._hasPassingFilterDescendants(path))
            # Important! due to js nature has_passing_filter_descendants won't be set
            # if self.pathPassFilter(path) is true.
            #
            # This is desired by us, since the _hasPassingFilterDescendants,
            # is of higher complexity than self.pathPassFilter(path)'s O(1).
            #
            # !!! But, because of that, the existence of has_passing_filter_descendants must
            # be checked before using it, and in case it doesn't exist it need to
            # be calculated.
            #
            # Since optimization is very critical in _each, we sacrifice here code
            # simplicity in the effort to avoid calling _hasPassingFilterDescendants
            # more than once.


            # Note, we use here section_manager's _hasPassingFilterDescendants, since, if
            # we got to the point where we call this iteratee and not the original one,
            # it means we didn't have information about the current path ourself and we had
            # to call section.section_manager._each (otherwise, if we can optimize we use
            # the original iteratee, since we have information about _hasPassingFilterDescendants
            # without the need to check from @_grid_tree_filter_state).

            iteratee_ret = original_iteratee(section, item_type, item_obj, path, expand_state)

            if iteratee_ret != -2
              if not has_passing_filter_descendants?
                # If has_passing_filter_descendants hasn't been calculated yet, read !important note above
                has_passing_filter_descendants = section.section_manager._hasPassingFilterDescendants(path)
              
              if not has_passing_filter_descendants
                # iteratee didn't ask to stop traversing and no descendants passed
                # the filter, don't step into the path
                return -1

            return iteratee_ret

          # Return undefined, continue to next item
          return

    if absolute_path != "/" or root_path_refers_to_main_section
      # Forward to the path's each
      section = @getPathSection(absolute_path)

      relative_path = section.section_manager.relPath absolute_path

      # Instead of directly forwarding to the section's _each we begin by using
      # @grid_tree and @_grid_tree_filter_state
      # as cache for information we already have about the items presented
      # in the visible tree - for sake of efficiency

      # To test without optimization uncomment the following
      # return section.section_manager._each(relative_path, options, iteratee)

      #
      # First see whether path's section has any children/expanded
      #
      if section.empty or section.expand_state != 1
        # the visible tree has no items for this section - either empty or not
        # expanded.
        # Note both checks are needed, "main" section is special case, as it will
        # always have its section.expand_state == 1, but will never have section
        # item, so if section.empty is true, we know we have no children regardless
        # of expand state
        if section.expand_state == -1
          # even if options.expand_only is true, this section is empty - so nothing to do
          return true

        # Now we know section.expand_state == 0
        if options.expand_only
          # this section has nothing in the visible tree - nothing to do
          return true

        # Section has children and isn't expanded
        if options.filtered_tree and section.id != "main"
          # If the section item is filtered, no need to traverse it
          section_item_filter_state = @_grid_tree_filter_state[section.begin][0]

          if section_item_filter_state == 0 or section_item_filter_state == 3
            # if section item doesn't pass the filter or is a leaf (all children filtered,
            # or no children at all) - nothing to do
            return true

        # We can't use visible tree for optimizations, call section's _each
        return section.section_manager._each(relative_path, options, iteratee)

      # Section is expanded, not empty, we might be able to optimize

      # find whether absolute_path is in the visible tree, and if so what's its index
      # in @grid_tree, expand_state, and level

      # ap stands for absolute_path
      ap_grid_tree_index = ap_tree_level = ap_expand_state
      if absolute_path == "/"
        # special case, main section's path don't have a section item, use section's
        # details
        ap_grid_tree_index = section.begin
        ap_tree_level = -1
        ap_expand_state = 1 # always expanded
      else if (ap_grid_tree_index = @getPathGridTreeIndex(absolute_path))?
        # absolute_path is visible in the tree, get its details from @grid_tree
        # _ap_item and _ap_path are redundant prefixed with _
        [_ap_item, ap_tree_level, _ap_path, ap_expand_state] = @grid_tree[ap_grid_tree_index]

        # See whether ap_grid_tree_index is filtered, note we test it here and not later
        # since we want to be sure absolute_path isn't "/" which always pass the filter
        if options.filtered_tree
          ap_item_filter_state = @_grid_tree_filter_state[ap_grid_tree_index][0]

          if ap_item_filter_state == 0 or ap_item_filter_state == 3
            # if section item doesn't pass the filter or is a leaf (all children filtered or no children at all)
            return true
      else
        # not in visible tree
        if options.expand_only
          return true # absolute_path isn't in the expanded tree, nothing to do
        else
          # requrested item isn't in the visible tree, forward to the section's
          # _each() to handle, no way to optimize
          return section.section_manager._each(relative_path, options, iteratee)

      # absolute_path is in the visible tree under ap_grid_tree_index
      if ap_expand_state == -1
        # absolute_path has no children, nothing to do
        return true

      if ap_expand_state == 0
        if options.expand_only
          # absolute_path not expanded when options.expand_only is true, nothing to do
          return true
        else 
          # requrested item isn't in the visible tree, forward to the section's
          # _each() to handle, no way to optimize
          return section.section_manager._each(relative_path, options, iteratee)

      # ap_expand_state == 1
      # absolute_path is expanded, find its first child index in @grid_tree

      first_child_index = ap_grid_tree_index + 1
      if absolute_path == "/"
        first_child_index -= 1 # "main" is the only section without section item, so no need to + 1

      current_index = first_child_index

      # loop until we reach an item in the same level as absolute_path
      # or until the end of the section
      item_is_leaf_in_filtered_tree = last_item_in_filtered_tree = false
      optimizations_iteratee = if original_iteratee? then original_iteratee else iteratee
      # original_iteratee will be defined when filtered_tree is true, in which case we create
      # an wrapping iteratee, that takes care of making sure only items that should pass the
      # filter returned.
      # since for items that we can yield without calling the section manager's _each we know
      # already what is their filter state, we don't need to call the wrapping iteratee, but
      # we can call directly to the original
      while (current_index < section.end)
        [c_item, c_tree_level, c_path, c_expand_state] = @grid_tree[current_index]
        c_type = c_item._type

        if c_tree_level <= ap_tree_level
          # Loop over all expanded items completed

          return true

        c_expand_state_to_yield = if options.expand_only then c_expand_state else undefined
        if options.filtered_tree
          item_is_leaf_in_filtered_tree = false

          [c_filter_state, c_special_position] = @_grid_tree_filter_state[current_index]

          if c_filter_state == 0
            # Not part of tree, skip to next item
            current_index += 1
            continue

          if c_filter_state == 3 # leaf in filtered tree, skip descendents
            item_is_leaf_in_filtered_tree = true
            if c_expand_state_to_yield?
              c_expand_state_to_yield = -1 # if exist (if options.expand_only: true) override original with item's expand state in filtered tree 

          if c_special_position == 2 or c_special_position == 3 # last/only item, break run after yielding
            last_item_in_filtered_tree = true

        iteratee_ret = optimizations_iteratee(section, c_type, c_item, c_path, c_expand_state_to_yield)

        if item_is_leaf_in_filtered_tree and iteratee_ret != -2
          iteratee_ret = -1 # override iteratee_ret in a way that we will skip all the children that don't need to be yielded
        if options.expand_only and last_item_in_filtered_tree # if we print only expanded items and we reached the last visible item in filtered tree
          iteratee_ret = -2

        if iteratee_ret == -2
          # iteratee requested stop
          return false

        if iteratee_ret == -1
          # iteratee requested skip traversing this item descendents
          if c_expand_state == 1 # state of current item is open, skip all descendents
            current_index += 1
            while (current_index < section.end and @grid_tree[current_index][1] > c_tree_level)
              current_index += 1

            # found the item index we skip to, -1 so later the current_index += 1 will bring us
            # to same place
            current_index -= 1
        else
          # Iteratee didn't request skipping traversing this item descendents 
          if c_expand_state == 0 and not options.expand_only # item is closed and we traverse non-expanded
            # We loop over non-expanded paths, and we found a non expanded path
            # forward to section's each to handle
            c_relative_path = section.section_manager.relPath c_path
            _each_ret = section.section_manager._each(c_relative_path, options, iteratee)
            if _each_ret is false
              return false

        current_index += 1

      return true

    # else, yield all items
    if @sections? # Only if @sections are ready 
      for section in @sections
        expand_state = if options.expand_only then section.expand_state else undefined

        # If the section has a section_item, yield it
        step_in = true # By default we attempt to step into the current path, unless iteratee will tell us otherwise
        if (section_item_row_id = section.section_item_row_id)?
          section_item = @getItem(section_item_row_id)

          iteratee_ret = iteratee section, section_item._type, section_item, section.path, expand_state

          if iteratee_ret is -1
            step_in = false
          else if iteratee_ret is -2
            return false

        if step_in isnt false # only false means do not step in
          if not options.expand_only or expand_state == 1
            _each_res = @_each section.path, options, iteratee, true

            if _each_res is false
              # _each stopped due to iteratee returned -2 - stop traversing and return false
              return false

    return true

  _destroySectionManagers: ->
    if @sections?
      # Call the _destroy() method of all the current section managers
      for section in @sections
        section.section_manager._destroy()

    return

  _rebuildSections: ->
    @_destroySectionManagers()

    @sections = []
    @section_path_to_section = {} # maintained for optimization
    @grid_tree = []
    @_items_ids_map_to_grid_tree_indices = {}
    @_typed_items_paths_map_to_grid_tree_indices = {}

    last_item_id = 0

    for section_conf in @sections_configuration
      section_obj = {}

      _.extend section_obj,
        id: section_conf.id
        path: section_conf.path
        options: section_conf.options
        empty: false
        begin: @getLength()
        end: null

      section_manager =
        new section_conf.section_manager(@, section_conf.path, section_obj, section_conf.section_manager_options)

      #
      # Init section's section_obj and push to @sections
      #
      _.extend section_obj,
        expand_state: section_manager.expandState("/")
        section_manager: section_manager

      @section_path_to_section[section_obj.path] = section_obj

      # Add the section item
      section_obj.section_item_row_id = @_addSectionItem(section_obj) # will be null if section don't have

      @sections.push section_obj

      if section_obj.expand_state == 1
        # If section expanded, generate section's items

        section_manager._each "/", {expand_only: true}, (section, item_type, item_obj, absolute_path, expand_state) =>
          if not item_type?
            @_addCollectionItem(
              item_obj,
              absolute_path,
              expand_state,
              section_obj
            )
          else
            @_addTypedItem(
              item_type,
              item_obj,
              absolute_path,
              expand_state,
              section_obj
            )

      section_obj.end = @getLength()

      if section_obj.begin == section_obj.end
        section_obj.empty = true
        delete section_obj.begin
        delete section_obj.end

    return