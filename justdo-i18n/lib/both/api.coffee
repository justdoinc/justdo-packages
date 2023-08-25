_.extend JustdoI18n.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  getUserLang: (user) ->
    # For non logged-in users, we'll return undefined.
    # In most cases, you should use getLang() on client side.
    if Meteor.isClient
      if not user?
        user = Meteor.user()
    else
      if _.isString user
        user = Meteor.users.findOne(user, {fields: {"profile.lang": 1}})
    
    return user?.profile?.lang
  
  setUserLang: (lang, user_id) ->
    # This api only updates lang in user_doc without updating local storage
    # In most cases, you should use setLang() on client side.
    check lang, Match.Maybe String

    if Meteor.isClient
      user_id = Meteor.userId()
    else
      if not user_id?
        throw @_error "missing-argument"
    
    if @getUserLang(user_id) is lang
      @logger.info "setUserLang: #{lang} is already the user's lang"
      return

    update = 
      $set:
        "profile.lang": lang

    Meteor.users.update user_id, update

    return

  getSupportedLanguages: ->
    return TAPi18n.getLanguages()
  
  getI18nTranslatedSchemaLabelOrFallback: (field_id, schema, i18n_key_prefix="") ->
    if not _.isObject schema
      throw new Meteor.Error "invalid-argument", "Schema obj required"

    schema = schema._schema or schema
    if not (field_def = schema[field_id])?
      throw new Meteor.Error "invalid-argument", "Provided schema doesn't contain definition of #{field_id}"
    if not (fallback_label = field_def.label)?
      console.warn "Provided schema doesn't contain label for #{field_id}. If no i18n text is found, the retuned text is likely to not be human friendly."

    field_id = field_id.replace /:/g, "_"
    i18n_key = "#{i18n_key_prefix}#{field_id}"
    i18n_label = TAPi18n.__ i18n_key

    # If i18n_label includes prefix, it means the field label isn't i18n ready. In this case we return the fallback label if available.
    i18n_label_not_found = i18n_label is i18n_key
    if i18n_label_not_found and fallback_label?
      return fallback_label

    return i18n_label