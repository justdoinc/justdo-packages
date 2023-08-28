Template.demo_html_template.helpers
  tasks: ->
    return Array.from @demo_html_template 
  
  i18nTitle: ->
    if _.isFunction @title_i18n
      return @title_i18n()
    if _.isObject @title_i18n
      return TAPi18n.__ @title_i18n.key, @title_i18n.options
    return TAPi18n.__ @title_i18n
    
  levelArray: ->
    return Array(@level).fill(0)

  showHierarchy: ->
    return @level > 0

  showExpandLine: ->
    return @expand_state == "minus"

  addExtraPadding: ->
    return not @expand_state? and @level > 0

  randomAvatarIndex: ->
    return _.random(1, 21)
