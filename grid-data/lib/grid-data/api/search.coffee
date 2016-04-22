default_options =
  fields: null # Search only specific fields
  exclude_filtered_paths: true # If true, and there's an active filters, search will be limited to filtered tree
  exclude_typed_items: true # Look only in @collection's items, XXX false isn't implemented

_.extend GridData.prototype,
  search: (term, options) ->
    # term should be a regex
    # fields should be array of fields names or null.
    # If fields is null we'll look for term in all fields.

    options = _.extend({}, default_options, options)
    fields = options.fields

    if not _.isRegExp(term)
      throw @_error "wrong-input", "search() supports only regular expressions as term argument"

    if fields? and not _.isArray(fields)
      throw @_error "wrong-input", "search() `fields` option must be array or null"

    each_options =
      expand_only: false
      filtered_tree: options.exclude_filtered_paths and @isActiveFilterNonReactive()

    paths = []
    @_each "/", each_options, (section, item_type, item_obj, path, expand_state) ->
      if item_type? and options.exclude_typed_items
        # Typed item, skip
        return

      if fields?
        for field in fields
          if item_obj[field]? and term.test(item_obj[field])
            paths.push path

            break
      else
        for field, value of item_obj
          if term.test(value)
            paths.push path

            break

    return paths