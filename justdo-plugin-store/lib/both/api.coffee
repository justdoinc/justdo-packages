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
  
  getCategoryById: (category_id) -> _.find share.store_db.categories, (category_obj) -> category_obj.id is category_id
  isCategoryExists: (category_id) -> @getCategoryById(category_id)?

  getPluginById: (plugin_id) -> _.find share.store_db.plugins, (plugin_obj) -> plugin_obj.id is plugin_id
  isPluginExists: (plugin_id) -> @getPluginById(plugin_id)?

  getCategoryPageTitle: (category_id, lang) ->
    if not (title = @getCategoryById(category_id)?.metadata?.title)?
      title = @getCategoryById(JustdoPluginStore.default_category).metadata.title
    return TAPi18n.__ title, {}, lang
  getCategoryPageDescription: (category_id, lang) ->
    if not (description = @getCategoryById(category_id)?.metadata?.description)?
      description = @getCategoryById(JustdoPluginStore.default_category).metadata.description
    return TAPi18n.__ description, {}, lang
  
  getPluginPageTitle: (plugin_id, lang) ->
    if not lang?
      lang = JustdoI18n.default_lang
    title = @getPluginById(plugin_id)?.metadata?.title or ""
    return APP.justdo_i18n.getI18nTextOrFallback {i18n_key: title, fallback_text: APP.justdo_seo.getDefaultPageTitle(lang), lang}
  getPluginPageDescription: (plugin_id, lang) ->
    if not lang?
      lang = JustdoI18n.default_lang
    description = @getPluginById(plugin_id)?.metadata?.description or ""
    return APP.justdo_i18n.getI18nTextOrFallback {i18n_key: description, fallback_text: APP.justdo_seo.getDefaultPageDescription(lang), lang}
  getPluginPagePreviewImage: (plugin_id) ->
    if (image_url = @getPluginById(plugin_id)?.image_url)?
      return image_url
    return APP.justdo_seo?.getDefaultPagePreviewImageUrl()
  
  getCategoryOrPluginIdFromPath: (path_without_lang) ->
    path_without_lang = JustdoHelpers.getNormalisedUrlPathnameWithoutSearchPart path_without_lang
    path_without_lang_and_hrp = APP.justdo_i18n_routes?.getPathWithoutHumanReadablePart(path_without_lang) or path_without_lang
    category_or_plugin_url_prefix = /\/plugins\/[pc]\//
    return path_without_lang_and_hrp.replace(category_or_plugin_url_prefix, "").replace(/\//g, "")
