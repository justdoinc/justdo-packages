Template.version_release_news.helpers
  date: ->
    tpl = Template.instance()
    APP.justdo_i18n.getLang() # For reactivity
    date = moment(@date, "YYYY-MM-DD")
    format_string = "L"
    if Meteor.user()?
      format_string = JustdoHelpers.getUserPreferredDateFormat()
    return date.format format_string
  
Template.updates_card.helpers
  updateItems: ->
    update_items = TAPi18n.__ @update_items
    if _.isString update_items
      update_items = update_items.split("\n")
    
    return update_items