# Tasks generator

lorem_arr = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum".split(" ")

items_added = 0

_.extend JustdoHelpers,
  tasksGenerator: (options) ->
    # Adds to each one of the items provided to it under parents_paths children
    # amounting to a random number between min_items_per_parent to max_items_per_parent.
    #
    # Then calls itself with all the children created and max_levels -= 1 (to create the next level)
    # 
    # As long as min_items_per_parent isn't 0, there will always be max_levels levels

    if not JustdoHelpers.isPocPermittedDomains()
      return

    module = APP.modules.project_page
    curProj = module.helpers.curProj
    gc = APP.modules.project_page.gridControl()

    default_options =
      max_levels: 10
      max_items_to_add: 1000 # If we add max_items_to_add tasks, we will stop adding more tasks immediately
      min_items_per_parent: 1
      max_items_per_parent: 10
      parents_paths: ["/"]
      max_words_in_title: 20 # 0 means no title will be set by us
      max_words_in_status: 20 # 0 means no status will be set by us
      fields: {}

    options = _.extend default_options, options

    if options.max_levels == 0
      # Our stop condition

      return

    if not options.original_max_levels?
      # We assume that if original_max_levels is not set, this is the top
      # level call to the recursion. So we do inits here as well
      options.original_max_levels = options.max_levels
      items_added = 0

    {original_max_levels, max_levels, min_items_per_parent, max_items_per_parent, parents_paths, fields} = options

    if not ("project_id" of fields)
      # Note, we don't change original fields
      fields = _.extend {}, fields, {project_id: curProj().id}
    
    addChildrentToParent = (parent_path, cb) ->
      addChildToParent = (n, subCb) ->
        child_fields = _.extend {}, fields # Create a copy

        for field_name in ["title", "status"]
          if not child_fields[field_name]? and options["max_words_in_#{field_name}"] != 0
            child_fields[field_name] = lodash.sampleSize(lorem_arr, lodash.random(1, options["max_words_in_#{field_name}"])).join(" ")

        if (items_added += 1) > options.max_items_to_add
          throw new Error("MAX ITEMS TO ADD LIMIT REACHED")

        gc._grid_data.addChild parent_path, child_fields, (err, new_item_id) ->
          if err?
            return subCb(err)
          return subCb(err, "#{parent_path}#{new_item_id}/")

      children_count = lodash.random(min_items_per_parent, max_items_per_parent)
      console.log("Adding #{children_count} to #{parent_path}")
      async.times(children_count, addChildToParent, cb)

    async.map parents_paths, addChildrentToParent, (err, new_childrens_paths) ->
      if err?
        throw Meteor.Error("error", err)

      merged_new_children_paths = []
      merged_new_children_paths = merged_new_children_paths.concat.apply(merged_new_children_paths, new_childrens_paths)

      next_level_options = _.extend {}, options
      next_level_options.parents_paths = merged_new_children_paths
      next_level_options.max_levels -= 1

      JustdoHelpers.tasksGenerator(next_level_options)

      console.log "Done building layer #{original_max_levels - max_levels} - items added so far #{items_added}"
