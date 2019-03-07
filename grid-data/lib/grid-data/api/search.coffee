default_options =
  fields: null # Search only specific fields
  exclude_filtered_paths: true # If true, and there's an active filters, search will be limited to filtered tree

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

    fields_schema = @grid_control.getSchemaExtendedWithCustomFields()
    testVal = (field, val) ->
      if (human_readable_val = fields_schema[field]?.grid_values?[val]?.txt)?
        # Options

        val = human_readable_val

      if fields_schema[field].type == Date and _.isDate(val)
        # Dates

        val = JustdoHelpers.getDateTimeStringInUserPreferenceFormatNonReactive(val)

      if fields_schema[field].grid_column_formatter == "unicodeDateFormatter" and _.isString(val) and not _.isEmpty(val)
        # Unicode date strings

        val = JustdoHelpers.normalizeUnicodeDateStringAndFormatToUserPreference(val)

      return term.test(val)

    each_options =
      expand_only: false
      filtered_tree: options.exclude_filtered_paths and @isActiveFilterNonReactive()

    paths = []
    @_each "/", each_options, (section, item_type, item_obj, path, expand_state) =>
      if item_type?
        if not (searchable = @items_types_settings[item_type]?.searchable)? or searchable == false
          # If this item type isn't searchable, skip
          return

      if fields?
        for field in fields
          if item_obj[field]? and testVal(field, item_obj[field])
            paths.push path

            break
      else
        for field, value of item_obj
          if testVal(field, value)
            paths.push path

            break

      return

    return paths