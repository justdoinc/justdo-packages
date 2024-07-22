_.extend JustdoPluginStore.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return
  
  isCategoryExists: (category_id) -> _.find share.store_db.categories, (category_obj) -> category_obj.id is category_id
  isPluginExists: (plugin_id) -> _.find share.store_db.plugins, (plugin_obj) -> plugin_obj.id is plugin_id