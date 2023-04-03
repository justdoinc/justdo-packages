Template.news.onCreated ->
  @active_version_rv = new ReactiveVar ""
  @active_news_tab_rv = new ReactiveVar ""
  @autorun =>
    params = Router.current()?.params
    @active_version_rv.set params?.news_version
    @active_news_tab_rv.set params?.news_template or "main"
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
  getActiveVersion: -> Template.instance().active_version_rv.get().replaceAll "-", "."

  versions: -> _.map APP.justdo_news.getAllNews(), (news) -> news.title

  activeVersionTemlates: ->
    active_version = Template.instance().active_version_rv.get()
    return APP.justdo_news.getNewsForVersion active_version



  isTabActive: (tab_id) ->
    active_tab_id = Template.instance().active_news_tab_rv.get()
    if tab_id is active_tab_id
      return "active"
    return

  getActiveTemplateForVersion: ->
    tpl = Template.instance()
    active_version = tpl.active_version_rv.get()
    active_tab = tpl.active_news_tab_rv.get()
    return APP.justdo_news.getTemplateForVersionIfExists(active_version, active_tab)?.template_name

Template.news.events
  "click .news-navigation-item": (e, tpl) ->
    tab_id = $(e.target).closest(".news-navigation-item").data "tab_id"
    Router.go "news_with_version_and_template", {news_version: tpl.active_version_rv.get(), news_template: tab_id}
    return

  "click .dropdown-item": (e, tpl) ->
    version = $(e.target).closest(".dropdown-item").text()
    version = version.replace ".", "-"
    Router.go "news_with_version_and_template", {news_version: version, news_template: tpl.active_news_tab_rv.get()}
    return
