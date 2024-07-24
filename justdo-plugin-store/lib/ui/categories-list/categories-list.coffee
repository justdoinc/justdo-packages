Template.justdo_plugins_store_categories_list.onCreated ->
  @store_manager = @data.store_manager

  return

Template.justdo_plugins_store_categories_list.helpers
  categories: ->
    tpl = Template.instance()

    return tpl.store_manager.listCategories()

  isActiveCategory: ->
    tpl = Template.instance()

    return @id == tpl.store_manager.getActiveCategory()
  
  isDefaultCategory: ->
    return @id == JustdoPluginStore.default_category

Template.justdo_plugins_store_categories_list.events
  "click .plugins-category": (e, tpl) ->
    tpl.store_manager.clearActivePluginPage()
    tpl.store_manager.setActiveCategory @id

    $(".store-front").scrollTop(0)
    $(document).scrollTop(0)

    return