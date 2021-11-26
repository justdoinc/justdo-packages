_.extend JustdoHelpers,
  getFieldsByUpdateType: (collection, fields_arr) ->
    if Meteor.isClient
      # Client side special case, for the tasks collection, if we are on the client, under a page
      # where the grid is presented, take the extended schema, including custom fields.
      if collection._name == "tasks"
        if (gc = APP.modules.project_page.mainGridControl())?
          schema = gc.getSchemaExtendedWithCustomFields()

    if not schema?
      if not (schema = JustdoHelpers.getCollectionSchema(collection)?._schema)?
        return {regular: [], client_only: []}

    regular = []
    client_only = []

    for field_id in fields_arr
      if not (field_def = schema[field_id])?
        # first, try to look for exact match for the field def, in the schema/(only if client side and the above req worked extended schema)
        # if we failed to find def with exact matching, look to see if we got a case of a key that has a :: prefix definition
        if field_id?.indexOf("::") > -1
          field_def = collection._c2?._simpleSchema?.getDefinition(field_id)

      if field_def?.client_only is true
        client_only.push field_id
      else 
        regular.push field_id

    return {regular, client_only}

  getFieldsByUpdateTypeFromModifier: (collection, modifier) ->
    # Will return an object of the form: {regular: [], client_only: []}

    all_fields_involved = CollectionHooks.getFields(modifier)

    return JustdoHelpers.getFieldsByUpdateType(collection, all_fields_involved)