_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @langs_to_preload_detectors = []
    @_registerDefaultLangsToPreloadDetectors()

    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    @_setupHandlebarsHelper()

    @_setupWebappConnectHandlers()

    return
  
  _setupHandlebarsHelper: ->
    OriginalHandlebars.registerHelper "_", (key, args...) ->
      options = args.pop().hash
      if not _.isEmpty args
        options.sprintf = args
      
      return TAPi18n.__ key, options
    return
  
  _registerDefaultLangsToPreloadDetectors: ->
    @registerLangsToPreloadDetector (req) =>
      if (user_lang = @getUserLangFromMeteorLoginTokenCookie req)?
        return user_lang
      return

    return

  _setupWebappConnectHandlers: ->
    WebApp.connectHandlers.use "/", (req, res, next) =>
      # If we don't get route_name, it means the req.url isn't a registered route in Iron Router (e.g. /tap-i18n/all.json, static asset requests, etc)
      # In that case we don't need to do anything.
      if not (route_name = JustdoHelpers.getRouteNameFromPath req.url)?
        next()
        return

      if _.isEmpty(langs_to_preload = @getLangsToPreload req)
        next()
        return
      
      req.dynamicHead = req.dynamicHead or ""

      req.dynamicHead += """
        <script>TAP_I18N_PRELOADED_LANGS = #{JSON.stringify langs_to_preload};</script>
      """

      next()

      return

  tr: (key, options, user) ->
    # If user isn't provided, we use Meteor.user().
    #
    # There are situations (outside methods/pubs) where Meteor.user() isn't available,
    # in those cases, you'll have to pass user, otherwise we will use the fallback language.
    #
    # If user is provided, it must be either:
    #
    #   1. An object with "profile.lang"
    #   2. A user id

    try
      if not user?
        user = Meteor.user({fields: {"profile.lang": 1}})
    catch e
      console.warn "JustdoI18n.__ called invoked outside of a method call or a publication, falling back to no-user."
      user = undefined

    lang_tag = @getUserLang(user) or JustdoI18n.default_lang

    options = _.extend {}, options
    return TAPi18n.__(key, options, lang_tag)

  defaultTr: (key, options) ->
    # Forcing translation of key to JustdoI18n.default_lang even if we have
    # Meteor.user() available
    return @tr(key, options, {profile: {lang: JustdoI18n.default_lang}})

  getUserLangFromMeteorLoginTokenCookie: (req) ->
    return JustdoHelpers.getUserObjFromMeteorLoginTokenCookie(req, {fields: {"profile.lang": 1}})?.profile?.lang
  
  registerLangsToPreloadDetector: (detector) ->
    @langs_to_preload_detectors.push detector
    return
  
  getLangsToPreload: (req) ->
    langs_to_preload = []

    for detector in @langs_to_preload_detectors
      langs = detector req
      if not _.isEmpty langs
        if _.isString langs
          langs_to_preload.push langs
        if _.isArray langs
          langs_to_preload = langs_to_preload.concat langs
    
    return _.uniq langs_to_preload
  
  _getProofreaderDocOptionsSchema: new SimpleSchema
    lang:
      type: String
    cur_page_i18n_keys:
      type: [Object]
    "cur_page_i18n_keys.$.key":
      type: String
    "cur_page_i18n_keys.$.templates":
      type: [String]
    exclude_keys:
      type: [Match.OneOf(String, RegExp)]
      optional: true
    include_keys:
      type: [Match.OneOf(String, RegExp)]
      optional: true
    excluded_templates:
      type: [String]
      optional: true
  getProofreaderDoc: (options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_getProofreaderDocOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    languages = TAPi18n.getLanguages()
    default_lang = JustdoI18n.default_lang
    default_lang_name = languages[default_lang].name
    lang = options.lang
    lang_name = languages[lang].name

    if not @xl?
      @xl = Npm.require "excel4node"

    workbook = new @xl.Workbook()
    worksheet = workbook.addWorksheet lang_name,
      sheetFormat:
        baseColWidth: 60
      sheetView:
        rightToLeft: @isLangRtl lang
        horizontal: if @isLangRtl(lang) then "right" else "left"
        zoomScale: 150
    
    row_i = 1
    # Create welcome message
    worksheet.cell row_i, 1, (row_i += 2), 3, true
      .string [
        "Please help us improve the translation, edit this file and send us back to: ",
        {
          bold: true
        }
        "info@justdo.com",
        {
          bold: false
        }
        "\nThank you for your effort!"
      ]
      .style 
        alignment:
          horizontal: "center"
          wrapText: true
          readingOrder: "leftToRight"
          vertical: "center"

    # Create header row
    header_style = workbook.createStyle 
      font:
        bold: true
    worksheet.cell (row_i += 1), 1
      .string "Translation"
      .style header_style
    worksheet.cell row_i, 2
      .string default_lang_name
      .style header_style
    worksheet.cell row_i, 3
      .string "Key"
      .style header_style
    # Always show the header
    worksheet.row(row_i).freeze()

    base_cell_style =
      alignment:
        wrapText: true
        vertical: "top"
    # Create cell style & write row
    cell_style = workbook.createStyle base_cell_style
    rtl_cell_style = workbook.createStyle _.extend {}, base_cell_style,
      alignment:
        horizontal: "right"

    _writeRow = (translated_string, default_lang_string, key) =>
      worksheet.cell (row_i += 1), 1
        .string translated_string
        .style if (@isLangRtl lang) then rtl_cell_style else cell_style
      worksheet.cell row_i, 2
        .string default_lang_string
        .style cell_style
      worksheet.cell row_i, 3
        .string key
        .style cell_style
      return

    added_keys = new Set()
    writeRow = (key, templates) ->
      # Note that we're adding the key to added_keys before checking whether it should be excluded, 
      # so that we don't add it again if it's excluded
      added_keys.add key

      # Check whether the key is excluded
      if options?.exclude_keys?
        should_key_be_excluded = false
        for exclude_key in options.exclude_keys
          if (exclude_key is key) or (exclude_key.test?(key))
            return
    
      # Check whether the key is used only by excluded templates
      if options?.excluded_templates? and not _.isEmpty(templates)
        templates = _.map templates, (template_name) -> template_name.replace "Template.", ""

        is_key_used_only_by_excluded_template = _.isEmpty _.difference templates, options.excluded_templates
        if is_key_used_only_by_excluded_template
          return

      default_lang_string = TAPi18n.__ key, {}, default_lang
      translated_string = TAPi18n.__ key, {}, lang

      # Values inside i18n files can be an array. 
      # If it is, default_lang_string and translated_string will be a string of the array joined by "\n".
      # Therefore to check whether the original value is an array, 
      # we'll have to access the original value from the i18n files directly via TAPi18next.options.resStore. 
      if _.isArray(default_lang_array = TAPi18next.options.resStore[default_lang].project[key])
        translated_array = TAPi18next.options.resStore[lang].project[key]
        for default_lang_array_element, i in default_lang_array
          translated_array_element = translated_array[i]
          _writeRow translated_array_element, default_lang_array_element, key + "[" + i + "]"
      else
        _writeRow translated_string, default_lang_string, key
      return

    for key_and_template in options.cur_page_i18n_keys
      key = key_and_template.key
      templates = key_and_template.templates

      writeRow key, templates
    
    isKeyAlreadyAdded = (key) => added_keys.has key
    if _.isArray options?.include_keys
      for include_key in options.include_keys
        if (not isKeyAlreadyAdded include_key) and (_.isString include_key)
          writeRow include_key
        else if _.isRegExp include_key
          for key of TAPi18next.options.resStore[default_lang].project
            if (not isKeyAlreadyAdded key) and (include_key.test key)
              writeRow key

    buffer = await workbook.writeToBuffer()
    return buffer
