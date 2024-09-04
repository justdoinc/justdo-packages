_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @forced_runtime_lang_rv = new ReactiveVar amplify.store JustdoI18n.amplify_lang_key

    @force_ltr_routes = new Set()
    @force_ltr_routes_dep = new Tracker.Dependency()

    # Use of new Map() instead of {} because it maintains the order of insertion
    @cur_page_i18n_keys = new Map()

    # XXX The APP.executeAfterAppClientCode wrap is necessary because on the first page load,
    # XXX TAPi18n's list of supported languages may not be fully initialized as specified in project-tap.i18n.
    # XXX Therefore we wrap the tracker with APP.executeAfterAppClientCode to give extra time for TAPi18n to be fully initialized.
    # XXX Once that issue is resolved, we can remove the APP.executeAfterAppClientCode wrap.
    APP.executeAfterAppClientCode =>
      @tap_i18n_set_lang_tracker = Tracker.autorun =>
        lang = @getLang()
        
        TAPi18n.setLanguage lang

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
        title: "languages_title"
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

    Template.registerHelper "getRtlAwareDirection", (direction) => @getRtlAwareDirection direction

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
    
    # If the key is not logged, log it
    if not is_i18n_key_logged
      @cur_page_i18n_keys.set i18n_key, new Set()

    # If template exists, add it to the set of templates that use the key
    if template?
      templates_set = @cur_page_i18n_keys.get i18n_key
      templates_set.add template
      @cur_page_i18n_keys.set i18n_key, templates_set

    return
    
  _getCurPageI18nKeys: -> @cur_page_i18n_keys

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

  getRouteProofreadingScope: (route_name) ->
    if (route_proofreading_scope = Router.routes[route_name]?.options?.proofreading_scope)?
      return route_proofreading_scope

    # Note that we're explicitly NOT using API from justdo_i18n_routes to determine if the current route is i18nable
    # because justdo_i18n_routes may not be available in all environments.
    is_route_i18nable = @isRouteTranslatable route_name

    if is_route_i18nable
      return JustdoI18n.default_i18n_route_proofreading_scope

    return JustdoI18n.default_non_i18n_route_proofreading_scope

  # Generates a XLSX document for proofreading translations.

  # The document includes translations based on the current language, suggested fixes,
  # original English text, and unique identifiers for each translation key.

  # @param {Object} [options] - Optional parameters for customizing the output.
  # @param {Array<string>} [options.exclude_templates] - An array of template names to exclude from the output.
  # @param {Array<string|RegExp>} [options.include_keys] - An array of strings or regular expressions to filter the keys included in the output.
  # @param {Array<string|RegExp>} [options.exclude_keys] - An array of translation keys to exclude from the output.
  # @param {boolean} [options.all_keys=false] - If true, includes all translation keys in the output, regardless of other filtering options.

  # @example
  #   Download a proofreading document for all translations used in current page.
  #   APP.justdo_i18n.getProofreaderDoc()

  # @example
  #   Download a proofreading document excluding translations used from the header, footer, and main_menu templates.
  #   APP.justdo_i18n.getProofreaderDoc exclude_templates: ["header", "footer", "main_menu"]

  # @example
  #   Download a proofreading document including translations with keys matching specific patterns, on top of all translations used in current page
  #   APP.justdo_i18n.getProofreaderDoc include_keys: ["ai_wizard_input_examples", /main_page.*/]

  # @example
  #   Download a proofreading document excluding translations with specific keys.
  #   APP.justdo_i18n.getProofreaderDoc exclude_keys: ["key1", "key2"]

  # @example
  #   Download a proofreading document including all translation keys under the current lang, regardless of other filtering options.
  #   APP.justdo_i18n.getProofreaderDoc all_keys: true
  getProofreaderDoc: (options) ->
    default_options = 
      exclude_templates: []
      include_keys: []
      exclude_keys: []
      all_keys: false
    options = _.extend default_options, options

    lang = @getLang()
    method_call_options = 
      lang: lang
    
    if options.all_keys
      method_call_options.all_keys = true
    else
      for key, value of options
        # Ensure that the array values are not empty
        if _.isArray(value)
          options[key] = _.compact value

      cur_page_i18n_keys = @_getCurPageI18nKeys()
      i18n_keys_and_depending_templates = []
      cur_page_i18n_keys.forEach (templates_set, key) -> i18n_keys_and_depending_templates.push {key: key, templates: Array.from(templates_set)}

      # Add include_keys to i18n_keys_and_depending_templates
      for include_key in options.include_keys
        # If key already exists in cur_page_i18n_keys, skip it
        if cur_page_i18n_keys.has include_key
          continue
        
        if _.isString include_key
          i18n_keys_and_depending_templates.push {key: include_key, templates: []}
        # If include_key is a RegExp, add all keys that match the RegExp
        else if _.isRegExp include_key
          for key of TAPi18next.options.resStore[JustdoI18n.default_lang].project
            if include_key.test key
              i18n_keys_and_depending_templates.push {key: key, templates: []}
        
      # Filter i18n_keys_and_depending_templates based on exclude_templates and exclude_keys
      i18n_keys_and_depending_templates = _.filter i18n_keys_and_depending_templates, (data) ->
        {key, templates} = data
        
        if options?.exclude_templates? and not _.isEmpty(templates)
          templates = _.map templates, (template_name) -> template_name.replace "Template.", ""

          is_key_used_only_by_excluded_template = _.isEmpty _.difference templates, options.exclude_templates
          if is_key_used_only_by_excluded_template
            return false
        
        if options?.exclude_keys?
          for exclude_key in options.exclude_keys
            if (exclude_key is key) or (exclude_key.test?(key))
              return false
        
        return true

      method_call_options.i18n_keys = _.map i18n_keys_and_depending_templates, (data) -> data.key

    Meteor.call "getProofreaderDoc", method_call_options, (err, csv_string) ->
      if err
        console.error err
        return
      
      cur_route_name = APP.justdo_i18n_routes?.getCurrentRouteName() or Router.current().route.getName()
      file_name = "#{lang}.#{cur_route_name}.xlsx"

      blob_obj = new Blob [csv_string], {type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"}
      download_link = document.createElement("a")
      download_link.href = window.URL.createObjectURL(blob_obj);
      download_link.target = '_blank'
      download_link.download = file_name

      document.body.appendChild(download_link)
      download_link.click()
      document.body.removeChild(download_link)

      return
    
    return

  # Returns direction as-is if current dir is LTR,
  # otherwise returns the opposite direction.
  # Note that input value is case insensitive,
  # and the return value is always lowercase.
  getRtlAwareDirection: (direction) ->
    direction = direction.toLowerCase()
    direction_map = 
      left: "right"
      right: "left"
      l: "r"
      r: "l"
    if direction not of direction_map
      throw @_error "invalid-argument", "Direction must be either \"left\", \"right\" or \"l\", \"r\"."

    is_rtl = @isRtl()
    if is_rtl
      return direction_map[direction]
    
    return direction