_.extend JustdoNews.prototype,
  _immediateInit: ->
    @news = []
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  registerNews: (news_obj) ->
    @news.push news_obj
    @news = _.sortBy(@news, "date").reverse() # Ensures the first element is the newest version
    return

  getAllNews: -> JSON.parse(JSON.stringify(@news))

  getNewsForVersion: (version) ->
    return _.find @news, (news) -> (news._id is version) or (news.title is version) or (version in news.aliases)

  getMostRecentVersion: -> @news[0]?._id

  getVersionUrlNameIfExists: (version) ->
    target_version = @getNewsForVersion version
    return target_version?._id

  getTemplateForVersionIfExists: (version, template_name) ->
    if not (target_version = @getNewsForVersion version)
      return
    return _.find target_version.templates, (template_obj) -> template_obj._id is template_name

  redirectToMostRecentVersionNewsPage: -> Router.current().redirect "/news/#{@getMostRecentVersion()}"
