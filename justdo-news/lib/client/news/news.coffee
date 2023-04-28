Template.news.onCreated ->
  if (controller = @data?.controller)?
    @controller = controller
    @controller.setTemplateInstance @

  @active_category_rv = new ReactiveVar(@data?.category or APP.justdo_news.getActiveCategetoryByRootPath())
  if not (most_recent_news_id = APP.justdo_news.getMostRecentNewsIdUnderCategory @active_category_rv.get())
    throw APP.justdo_news._error "news-category-not-found"

  @active_news_id_rv = new ReactiveVar(@data?.news_id or most_recent_news_id)
  @controller.active_news_id_rv = @active_news_id_rv

  @active_news_tab_rv = new ReactiveVar(@data?.tab_id or "main")

  @show_dropdown = @data?.show_dropdown
  if not @show_dropdown?
    @show_dropdown = true

  # If router_navigation and register_news_routes is true, the content of template will react to the active route,
  # and will redirect user to the corresponding route upon clicking.
  @register_news_routes = APP.justdo_news.register_news_routes
  @router_navigation = @data?.router_navigation
  if not @router_navigation?
    @router_navigation = @register_news_routes

  if @router_navigation and @register_news_routes
    @autorun =>
      active_category = APP.justdo_news.getActiveCategetoryByRootPath()
      @active_category_rv.set active_category

      params = Router.current()?.params
      @active_news_id_rv.set params?.news_id
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

  if not @show_dropdown
    @$(".versions-dropdown-btn").css "cursor", "default"

  return

Template.news.helpers
  getActiveNewsTitle: ->
    tpl = Template.instance()
    return APP.justdo_news.getNewsByIdOrAlias(tpl.active_category_rv.get(), tpl.active_news_id_rv.get())?.title

  showDropdown: ->
    tpl = Template.instance()
    if tpl.show_dropdown
      return "dropdown"
    return

  otherNews: ->
    tpl = Template.instance()
    return APP.justdo_news.getAllNewsByCategory(tpl.active_category_rv.get())

  isNewsActive: ->
    if @_id is Template.instance().active_news_id_rv.get()
      return "text-secondary"
    return

  activeNews: ->
    tpl = Template.instance()
    return APP.justdo_news.getNewsByIdOrAlias tpl.active_category_rv.get(), tpl.active_news_id_rv.get()

  isTabActive: (tab_id) ->
    active_tab_id = Template.instance().active_news_tab_rv.get()
    if tab_id is active_tab_id
      return "active"
    return

  getActiveNewsTemplate: ->
    tpl = Template.instance()
    news_doc = APP.justdo_news.getNewsByIdOrAlias tpl.active_category_rv.get(), tpl.active_news_id_rv.get()
    active_tab = tpl.active_news_tab_rv.get()

    template = _.find news_doc.templates, (template_obj) -> template_obj._id is active_tab
    template.template_data.date = news_doc.date
    return template

Template.news.events
  "click .news-navigation-item": (e, tpl) ->
    active_category = tpl.active_category_rv.get()
    tab_id = $(e.target).closest(".news-navigation-item").data "tab_id"

    if tpl.router_navigation and tpl.register_news_routes
      Router.go "#{active_category.replaceAll "-", "_"}_page_with_news_id_and_template",
        news_category: active_category
        news_id: tpl.active_news_id_rv.get()
        news_template: tab_id
    else
      tpl.active_news_tab_rv.set tab_id

    return

  "click .dropdown-item": (e, tpl) ->
    active_category = tpl.active_category_rv.get()
    news_id = $(e.target).closest(".dropdown-item").data("news_id")

    if tpl.router_navigation and tpl.register_news_routes
      Router.go "#{active_category.replaceAll "-", "_"}_page_with_news_id",
        news_category: active_category
        news_id: news_id
    else
      tpl.active_news_id_rv.set news_id

    return
