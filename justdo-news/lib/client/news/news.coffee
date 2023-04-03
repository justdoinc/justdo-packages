Template.news.onCreated ->
  @active_category_rv = new ReactiveVar ""
  @active_news_id_rv = new ReactiveVar ""
  @active_news_tab_rv = new ReactiveVar ""
  @active_news_doc = new ReactiveVar {}
  @autorun =>
    active_category = APP.justdo_news.getActiveCategetoryByRootPath()
    @active_category_rv.set active_category

    params = Router.current()?.params
    @active_news_id_rv.set params?.news_id
    @active_news_tab_rv.set params?.news_template or "main"

    @active_news_doc.set APP.justdo_news.getNewsByIdOrAlias active_category, params?.news_id
    return

  return

Template.news.onRendered ->
  $(window).on "scroll", (e) ->
    $news = $(".news")
    $news_nav = $(".news-navigation")
    $navbar = $(".navbar")
    navbar_offset_top = $navbar.position().top
    navbar_position = navbar_offset_top - $(window).scrollTop()
    navbar_height = $navbar.outerHeight()

    if Math.abs(navbar_position) - 100 >= navbar_height
      $news.addClass "fixed-nav"
      $news.css "margin-top": $news_nav.outerHeight()
    else
      $news.removeClass "fixed-nav"
      $news.css "margin-top": 0

    return

  return

Template.news.helpers
  getActiveNewsTitle: -> Template.instance().active_news_doc.get()?.title

  otherNews: ->
    tpl = Template.instance()
    return APP.justdo_news.getAllNewsByCategory(tpl.active_category_rv.get())

  isNewsActive: ->
    if @_id is Template.instance().active_news_id_rv.get()
      return "text-secondary"
    return

  activeNews: ->
    tpl = Template.instance()
    return tpl.active_news_doc.get()

  isTabActive: (tab_id) ->
    active_tab_id = Template.instance().active_news_tab_rv.get()
    if tab_id is active_tab_id
      return "active"
    return

  getActiveNewsTemplate: ->
    tpl = Template.instance()
    news_doc = tpl.active_news_doc.get()
    active_tab = tpl.active_news_tab_rv.get()

    # Note that in the returned news_doc, news_doc.template is added to store the target template obj
    news_doc.template = _.find news_doc.templates, (template_obj) -> template_obj._id is active_tab
    return news_doc


Template.news.events
  "click .news-navigation-item": (e, tpl) ->
    active_category = tpl.active_category_rv.get()
    tab_id = $(e.target).closest(".news-navigation-item").data "tab_id"
    Router.go "#{active_category.replaceAll "-", "_"}_page_with_news_id_and_template",
      news_category: active_category
      news_id: tpl.active_news_id_rv.get()
      news_template: tab_id
    return

  "click .dropdown-item": (e, tpl) ->
    active_category = tpl.active_category_rv.get()
    news_id = $(e.target).closest(".dropdown-item").data("news_id")
    Router.go "#{active_category.replaceAll "-", "_"}_page_with_news_id",
      news_category: active_category
      news_id: news_id
    return
