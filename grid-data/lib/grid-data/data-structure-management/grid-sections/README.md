grid-sections
=============

Each item in our GridData implementation is added by a `Grid Section`.

The GridData's Grid Sections are defined in an array under the GridData's
`sections` option.

Each section is formatted as follow:

  {
    id: "section-id"

    # Should be a unique dash-separated id for the section.

    # The path of each section item will be its path concatenated to the
    # `Section Path` ("/#{section-id}"), example: "/#{section-id}#{item_path}"

    # Section items will be listed under their section's a pseudo item called
    # the `Section Item` (the path of the Section Item is its section's
    # Section Path).

    # "main" is a special section id for the `Main Section`:
    #
    #   * The Main section's Section Path is simply "/" and its items.
    #   * Main Section has no Section Item - "main" item's will be listed
    #     directly under the grid root.

    type: "DataTreeSection"

    # The `Section Type`, the constructor that generates the sections items
    # and provide operations/information on them.

    # Can be either a string with the id of one of the built-ins types
    # or a custom constructor structured as described below.

    type_options: {}

    # Options that will be passed to the Section Type constructor

    options: {}

    # Other sections options

    options.section_item_title: ""

    # The title of the Section Item - html allowed

    options.expanded_on_init: false

    # If set to true the section item will be expanded
    # on the grid init
    # Relevant only for non "main" sections

    options.permitted_depth: -1

    # The section's relative depth on which the user can perform certain actions that
    # affects the @collection's items order or parent_id.
    # 
    # The actions (Depth Restricted Actions) that requires the items to be in a
    # relative level (depth) permitted by permitted_depth are: sorting, add
    # child, move up/down, in/outdent, remove item.
    #
    #   -1: no depth restricted actions allowd in this section
    #    0: depth restricted actions allowd in any level of this section
    #    1: depth restricted actions allowd only in relative level > 0
    #    2: XXX NOT IMPLEMENTED YET depth restricted actions allowd only in relative
    #       level > 0, only if they are bound to a single sub-tree of the section.
  }

Details and operations on each section can be done through the @sections
array that will have an object item for each section formatted as follow:

  {
    id: "section-id"  # the section id

    path: ""          # the path to the section's root: that is, the
                      # `Section Item`, will be "/" for the Main Section

    empty: true/false # If true, there are no items for this
                      # section

    begin: x          # If empty is false, will be the first item
                      # position in @grid_tree of this section
                      # If empty is true won't be defined.

    end: x            # If empty is false, will be the first item
                      # position in @grid_tree of the next
                      # section, or equal to @grid_tree.length,
                      # if the section continues to the end of
                      # the tree.
                      # If empty is true won't be defined.

    expand_state: bool # true if the section is expanded, false otherwise
                       # Main Path will always be expanded.
                       # If expanded will be true even if not visible (by
                       # filter for example)

    settings: {}      # Stores sections settings

    isPathExists: (absolute_path) -> ...
    # Gets an absolute path under this section.
    # Returns true if exists under this section (even if hidden due to
    # collapsed ancestor), false otherwise
  }

@sections_state will be updated during the rebuild process and will be ready
before "rebuild" event is emitted.

Sections Types
--------------

Section Type is a constructor that adds the section item and provide operations
and information on the section's item.

Sections types are called with the grid data object and the options provided
with the section type_options option. Example:

  DataTreeSection = (grid_data_obj, options) ->
    @grid_data = grid_data_obj
    @options = _.extend {}, default_options, options

    return @

Sections types need to define the following methods:

* itemsGenerator(iface)

  Items generators are called with the grid_control object as their @.

  iface (short for interface) will be an object with the following methods:

    * addItem(item_id, path, expand_state=-1)

      Adds an item to the tree.

      **item_id**: The item object
      **path**: The item path that will be concatenated to the Section Path
      **expand_state**: Pass -1 (default) if the item has no expand collapse toggle
                              0 if the item is collapsed
                              1 if the item is expanded
                              Note: the meaning of expand/collapse can be
                              different between items-generators.

    * isPathExpanded(path)

      Returns 1 is the provided path, relative to the section, is expanded
      Returns 0 otherwise

    * buildNode(item_id, target_path="/")

      A shortcut for printing item_id's tree (use item_id = "0" to print
      from root)
      target_path will prefix all the item's paths.

* hasChildren()

  Should return true if there are items under this section (even if hidden due
  to collapsed ancestor/filter), should return false otherwise

* isPathExists(path_relative_to_section)

  Should return true if path_relative_to_section exists under this
  section (even if hidden due to collapsed ancestor/filter), false
  otherwiseitemIdHasChildren