generateMinMaxNewValueModifier = (field_sort) ->
  return (item_id, field_id, existing_value, new_value) ->
    if not existing_value? or not _.isString(existing_value) or _.isEmpty(existing_value)
      return {$set: {"#{field_id}": new_value}}

    # Find whether any of item_id's children has a value for field_id, if not, set to
    # null. Otherwise, set to 
    query = 
      "parents.#{item_id}": {$exists: true}
      $and: [
        {"#{field_id}": {$ne: null}},
        {"#{field_id}": {$ne: ""}}
      ]

    options =
      fields: {"#{field_id}": 1}
      sort: {"#{field_id}": field_sort}

    if not (res = APP.collections.Tasks.findOne(query, options))?
      return {$set: {"#{field_id}": null}}

    return {$set: {"#{field_id}": res[field_id]}}

APP.justdo_custom_plugins.installCustomPlugin
  # SETTINGS BEGIN
  #
  # The following properties should be defined by all custom plugins
  custom_plugin_id: "custom_start_date_end_date_auto_setter"

  custom_plugin_readable_name: "Start Date/End Date Auto Setter"

  show_in_extensions_list: false
  #
  # / SETTINGS END

  behaviours:
    start_date:
      getNewValueModifier: generateMinMaxNewValueModifier(1)
    end_date:
      getNewValueModifier: generateMinMaxNewValueModifier(-1)

  installer: ->
    @collection_hook = APP.collections.Tasks.after.update (user_id, doc, field_names, modifier, options) =>
      for field_id, behaviour of @behaviours
        do (field_id) =>
          if (new_value = modifier["$set"]?[field_id])? or new_value == null
            parents_ids = _.keys(doc.parents)
            APP.collections.Tasks.find({_id: {$in: parents_ids}}, {fields: {_id: 1, "#{field_id}": 1}}).forEach (parent_doc) =>
              if (new_value_modifier = @behaviours[field_id].getNewValueModifier(parent_doc._id, field_id, parent_doc[field_id], new_value))?
                APP.collections.Tasks.update(parent_doc._id, new_value_modifier)

              return

          return

      return

    return

  destroyer: ->
    @collection_hook.remove()

    return
