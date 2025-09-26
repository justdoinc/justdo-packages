Template.version_release_news.helpers
  date: ->
    date = moment(@date, "YYYY-MM-DD")
    format_string = JustdoHelpers.getUserPreferredDateFormat("L")
    return date.format format_string
  
  newsItemListingCondition: ->
    if @listingCondition?
      return @listingCondition()
    return true

Template.updates_card.helpers
  updateItems: ->
    update_items = TAPi18n.__ @update_items
    if _.isString update_items
      update_items = update_items.split("\n")

    return update_items

Template.news_card.helpers
  isVideo: (url) ->
    return false unless url
    videoExtensions = ['.mp4', '.mov', '.webm']
    ext = url.toLowerCase()
    videoExtensions.some (e) -> ext.endsWith(e)
