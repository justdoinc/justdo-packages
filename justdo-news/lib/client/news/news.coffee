news = [
  {
    "title": "New landing page"
    "subtitle": "Energistically productivate orthogonal partnerships via economically sound leadership skills"
    "media_url": "/layout/images/news/2023_03_10_1.jpg"
  },
  {
    "title": "Custom states"
    "subtitle": "Dynamically recaptiualize process-centric infrastructures before future-proof opportunities. Proactively pontificate economically sound innovation"
    "media_url": "/layout/images/news/2023_03_10_3.jpg"
  },
  {
    "title": "On-grid unread emails indicator"
    "subtitle": "Load more button long emails improvements"
    "media_url": "/layout/images/news/2023_03_10_5.jpg"
  },
  {
    "title": "Add filter to the quick add bootbox destination selector and owner selector"
    "subtitle": "Load more button long emails improvements"
    "media_url": "/layout/images/news/2023_03_10_6.jpg"
  }
]

updates = [
  {
    "title": "Improvements"
    "date": "10 March 2023"
    "update_items": [
      "1. Performance improvement for operations that involves updates to more than 1k tasks, in particular, changing tasks members of a sub-tree bigger than 1k users.",
      "2. Activity tab: Fix activity log not showing correctly if it is a parent-add and the parent is removed <a href='https://drive.google.com/file/d/1StWLN86xWT2hlafgyG8pdwB2aBPJipD6/view?usp=share_link' target='blank'>video</a>.",
      "3. Upload avatars for environments that use JustDo files.",
      "4. Introduced the Organizations concept: an optional logic unit above JustDos.",
      "5. MailDo: When an email is received, the task owner is now automatically unmuted in the chat."
    ]
  }
]

Template.news.onCreated ->
  @show_updates = new ReactiveVar false

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

  news: ->
    return news

  updates: ->
    return updates

  showUpdates: ->
    return Template.instance().show_updates.get()

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
