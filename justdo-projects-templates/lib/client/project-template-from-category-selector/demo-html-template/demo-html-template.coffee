Template.demo_html_template.helpers
  tasks: ->
    return @demo_html_template 

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
