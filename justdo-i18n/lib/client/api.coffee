_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @forced_runtime_lang_rv = new ReactiveVar amplify.store JustdoI18n.amplify_lang_key

    @force_ltr_routes = new Set()
    @force_ltr_routes_dep = new Tracker.Dependency()

    # Use of new Map() instead of {} because it maintains the order of insertion
    @cur_page_i18n_keys = new Map()
    prev_path = Iron.Location.get().path
    # This tracker is to clear cur_page_i18n_keys from the previous page when the page changes.
    @cur_page_i18n_keys_tracker = Tracker.autorun =>
      cur_path = Iron.Location.get().path
      if prev_path isnt cur_path
        @_clearCurPageI18nKeys()
        prev_path = cur_path  
      return
    @onDestroy =>
      @cur_page_i18n_keys_tracker?.stop?()
      return

    # XXX The APP.executeAfterAppClientCode wrap is necessary because on the first page load,
    # XXX TAPi18n's list of supported languages may not be fully initialized as specified in project-tap.i18n.
    # XXX Therefore we wrap the tracker with APP.executeAfterAppClientCode to give extra time for TAPi18n to be fully initialized.
    # XXX Once that issue is resolved, we can remove the APP.executeAfterAppClientCode wrap.
    APP.executeAfterAppClientCode =>
      @tap_i18n_set_lang_tracker = Tracker.autorun =>
        lang = @getLang()
        
        TAPi18n.setLanguage lang
        i18n?.setLanguage lang

        # On the initial load, bootbox might not be loaded yet, try to set it again after app accounts are ready
        # (which is quite late in the init process)
        # The hooks will be called in the order they were added, so don't worry
        # about later changes to lang being overriden by prior calls where lang
        # isn't determined yet
        
        # Bootbox will fallback to en if the language is not supported
        bootbox.setLocale lang.replaceAll("-", "_")

        # Datepicker doesn't have a fallback mechanism, so we need to check if the language is supported
        # and use the default language if it's not
        if (datepicker = jQuery.datepicker)?
          locale_config = jQuery.datepicker.regional[lang] or jQuery.datepicker.regional[JustdoI18n.default_lang]
          datepicker.setDefaults locale_config

        # Moment.js doesn't have a fallback mechanism, so we need to check if the language is supported
        # and use the default language if it's not
        moment_lang = lang.toLowerCase()
        if moment_lang in moment.locales()
          moment.locale moment_lang
        else
          moment.locale JustdoI18n.default_lang

        $("html").attr "lang", lang
        return
      @onDestroy =>
        @tap_i18n_set_lang_tracker?.stop?()
        return

      return

    @_setupBeforeUserSignUpHook()

    @_setupPlaceholderItems()
    @_registerGlobalTemplateHelpers()
    @_overrideTapI18nHelper()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  _setupBeforeUserSignUpHook: ->
    APP.once "app-accounts-ready", =>
      APP.accounts.on "user-signup", (options) =>
        if (lang = @getLang())?
          options.profile.lang = lang
        return
      return
    return

  _setupPlaceholderItems: ->
    APP.getEnv (env) ->
      if not (JustdoHelpers.getClientType(env) is "web-app")
        return

      APP.modules.main.user_config_ui.registerConfigSection "langs-selector",
        title: "Languages"
        priority: 50

      APP.modules.main.user_config_ui.registerConfigTemplate "langs-selector-dropdown",
        section: "langs-selector"
        template: "user_preference_lang_dropdown"
        priority: 100

      return

    return

  _registerGlobalTemplateHelpers: ->
    Template.registerHelper "getI18nTextOrFallback", (options) =>
      return @getI18nTextOrFallback options
    
    Template.registerHelper "isRtl", (route_name) => @isRtl route_name

  _overrideTapI18nHelper: ->
    # This is to override TAPi18n.__ and the {{_}} helpers to gather all the i18n keys used in the page, and which template uses the key, to @cur_page_i18n_keys.
    # @cur_page_i18n_keys is used in getProofreaderDoc.
    self = @

    # This is a hack to allow us overriding the "_" helper in templates, 
    # so that we can gather all the i18n keys used in the current page by the order they are used,
    # and which template uses the key.
    # Blaze.de/registerHelper cannot be used because TAPi18n will register the helper again and override our override.
    originalRegisterHelper = Blaze.registerHelper
    Blaze.registerHelper = (name, func) ->
      if name is "_"
        overriden_func = (key, ...args) ->
          template = Template.instance().view.name
          self._addCurPageI18nKeys key, template

          return func key, ...args 
          
        return originalRegisterHelper name, overriden_func
      
      return originalRegisterHelper name, func
    
    # This override is to allow us to gather all the i18n keys used in the current page with TAPi18n.__ by the order they are used,
    # and potentially which template uses the key.
    originalTapI18nHelper = TAPi18n.__
    TAPi18n.__ = (key, options, lang_tag) ->
      # If TAPi18n.__ is called inside a template helper, we can get the template name from the template instance.
      template = Template.instance()?.view?.name
      self._addCurPageI18nKeys key, template

      return originalTapI18nHelper key, options, lang_tag

  _addCurPageI18nKeys: (i18n_key, template) -> 
    is_i18n_key_logged = @cur_page_i18n_keys.has i18n_key
    is_logged_i18n_key_has_template = @cur_page_i18n_keys.get(i18n_key)?
    
    # If the key is not logged, log it
    if not is_i18n_key_logged
      @cur_page_i18n_keys.set i18n_key, template
      return
    
    # If the key is logged but the template is not, log the template
    if template? and not is_logged_i18n_key_has_template
      @cur_page_i18n_keys.set i18n_key, template
      return

    return
    
  _getCurPageI18nKeys: -> @cur_page_i18n_keys

  _clearCurPageI18nKeys: -> @cur_page_i18n_keys.clear()

  setLang: (lang, options) ->
    # options:
    #   skip_set_user_lang: Boolean (optional) - Do not set user's lang. Only has effect if it's true.

    @setForcedRuntimeLang(lang)

    if Meteor.user()? and (options?.skip_set_user_lang isnt true)
      @setUserLang lang
    else
      amplify.store JustdoI18n.amplify_lang_key, lang
    return

  setForcedRuntimeLang: (lang) ->
    @forced_runtime_lang_rv.set lang

    return

  clearForcedRuntimeLang: ->
    @forced_runtime_lang_rv.set null

    return

  _getForcedRuntimeLang: ->
    return @forced_runtime_lang_rv.get()

  getLang: ->
    if (runtime_lang = @_getForcedRuntimeLang())?
      return runtime_lang

    if Meteor.user({fields: {"profile.lang": 1}})?
      return @getUserLang() or JustdoI18n.default_lang

    if (campaign_lang = APP.justdo_promoters_campaigns?.getCampaignDoc()?.lang)?
      return campaign_lang
        
    return JustdoI18n.default_lang
    
  generateI18nModalButtonLabel: (label) ->
    return JustdoHelpers.renderTemplateInNewNode("modal_button_label", {label}).node
  
  getVimeoLangTag: (lang_tag) ->
    if not lang_tag?
      lang_tag = @getLang()

    if (vimeo_lang_tag = JustdoI18n.vimeo_lang_tags[lang_tag])?
      return vimeo_lang_tag
      
    return lang_tag
  
  isRtl: (route_name) ->
    @force_ltr_routes_dep.depend()
    if @force_ltr_routes.has route_name
      return false

    return @isLangRtl @getLang()

    # Generates a CSV document for proofreading translations.

    # The document includes translations based on the current language, suggested fixes,
    # original English text, and unique identifiers for each translation key.

    # @param {Object} [options] - Optional parameters for customizing the output.
    # @param {Array<string>} [options.exclude_templates] - An array of template names to exclude from the output.
    # @param {Array<string|RegExp>} [options.include_keys] - An array of strings or regular expressions to filter the keys included in the output.

    # @example
    #   Download a proofreading document for all translations used in current page.
    #   APP.justdo_i18n.getProofreaderDoc()

    # @example
    #   Download a proofreading document excluding translations used from the header, footer, and main_menu templates.
    #   APP.justdo_i18n.getProofreaderDoc exclude_templates: ["header", "footer", "main_menu"]

    # @example
    #   Download a proofreading document including translations with keys matching specific patterns, on top of all translations used in current page
    #   APP.justdo_i18n.getProofreaderDoc include_keys: ["ai_wizard_input_examples", /main_page.*/]
  getProofreaderDoc: (options) ->
    cur_route_name = APP.justdo_i18n_routes?.getCurrentRouteName() or Router.current().route.getName()

    default_lang = JustdoI18n.default_lang
    default_lang_name = TAPi18n.getLanguages()[default_lang].name

    lang = @getLang()
    lang_name = TAPi18n.getLanguages()[lang].name

    file_name = "#{cur_route_name}-#{lang}.csv"

    header_row = ["Translation", default_lang_name, "Key"]
    csv_rows = [header_row]

    pushKeyToCsvRows = (key, template) ->
      if options?.excluded_templates? and (template.replace("Template.", "") in options.excluded_templates)
        return

      default_lang_string = TAPi18n.__ key, {}, default_lang
      translated_string = TAPi18n.__ key, {}, lang

      # Values inside i18n files can be an array. 
      # If it is, default_lang_string and translated_string will be a string of the array joined by "\n".
      # Therefore to check whether the original value is an array, 
      # we'll have to access the original value from the i18n files directly via TAPi18next.options.resStore. 
      if _.isArray (default_lang_array = TAPi18next.options.resStore[default_lang].project[key])
        translated_array = TAPi18next.options.resStore[lang].project[key]
        for default_lang_array_element, i in default_lang_array
          translated_array_element = translated_array[i]
          csv_rows.push [translated_array_element, default_lang_array_element, key + "[" + i + "]"]
      else
        csv_rows.push [translated_string, default_lang_string, key]

      return

    # Include i18n keys that are used in the current page without those used by templates in the list of excluded_templates
    @_getCurPageI18nKeys().forEach (template, key) -> pushKeyToCsvRows key, template
    
    if _.isArray options?.include_keys
      for include_key in options.include_keys
        if _.isString include_key
          pushKeyToCsvRows include_key
        else if _.isRegExp include_key
          for key of TAPi18next.options.resStore[lang].project
            if include_key.test key
              pushKeyToCsvRows key
    
    # Below are heavily influenced by exportCSV under justdo-print-grid package.
    # universalBOM needs to force Excel use UTF-8 for CSV
    universalBOM = "\uFEFF"
    csv_string = universalBOM
    new_line = "\u000d\n"
    for row in csv_rows
      csv_string += _.map(row, (val) -> "\"" + String(val or "").replace(/"/g, "\"\"") + "\"").join(",") + new_line
  
    if window.Blob && window.navigator.msSaveOrOpenBlob
      csv_blob_obj = new Blob([csv_string])

      window.navigator.msSaveOrOpenBlob(csv_blob_obj, file_name)
    else
      # Create invisible link to set file name
      encoded_uri = "data:text/csv;charset=utf-8," + encodeURIComponent(csv_string)
      download_link = document.createElement("a")
      download_link.target = '_blank'
      download_link.href = encoded_uri
      download_link.download = file_name

      document.body.appendChild(download_link)
      download_link.click()
      document.body.removeChild(download_link)

    return