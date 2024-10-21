Template.support_page_article.onCreated ->
  @category = "support"
  if not (most_recent_news_id = APP.justdo_crm.getMostRecentItemObjUnderCategory(@category)?._id)?
    throw APP.justdo_crm._error "news-category-not-found"

  @active_news_id_rv = new ReactiveVar(@data?.news_id or most_recent_news_id)

  @active_news_tab_rv = new ReactiveVar(@data?.tab_id or JustdoNews.default_news_template)

  @show_navigation_bar = @data?.show_navigation_bar
  if not @show_navigation_bar?
    @show_navigation_bar = true

  @show_dropdown_button = @data?.show_dropdown_button
  if not @show_dropdown_button?
    @show_dropdown_button = true

  @show_dropdown = @data?.show_dropdown
  if not @show_dropdown?
    @show_dropdown = true

  # If router_navigation and register_news_routes is true, the content of template will react to the active route,
  # and will redirect user to the corresponding route upon clicking.
  @register_news_routes = APP.justdo_crm.register_news_routes
  @router_navigation = @data?.router_navigation
  if not @router_navigation?
    @router_navigation = @register_news_routes

  if @router_navigation and @register_news_routes
    @autorun =>
      if not (params = Router.current()?.params)?
        return
      {news_id, news_template} = params
      if APP.justdo_seo?
        news_id = APP.justdo_seo.getPathWithoutHumanReadableParts news_id
        news_template = APP.justdo_seo.getPathWithoutHumanReadableParts news_template
      @active_news_id_rv.set news_id
      @active_news_tab_rv.set news_template or JustdoNews.default_news_template

      return

  @isRouterNavigation = -> @router_navigation and @register_news_routes

  @getNewsPath = (template_name, template_data) ->
    # If the news_template is the default template, we don't need to include it in the path.
    if APP.justdo_crm.isDefaultItemTemplate template_data.news_template
      template_name = template_name.replace "_with_news_id_and_template", "_with_news_id"

    news_path = Router.path template_name, template_data
    news_path = APP.justdo_i18n_routes?.i18nPathAndHrp(news_path) or news_path

    return news_path

  return

Template.support_page_article.onRendered ->
  # This tracker is responsible for converting links in articles to i18n + HRP links,
  # since we can't hard-code this in the i18n file, 
  # and calling template helpers won't work from i18n files either.
  @autorun =>
    # Reactive to current route
    Router?.current()

    # Find links that doesn't include the .dropdown-item class (which are navigation items that has i18n + HRP already)
    $(@firstNode).find("a:not(.dropdown-item)").each (i, el) ->
      path = $(el).attr("href")
      i18n_path_with_hrp = APP.justdo_i18n_routes.i18nPathAndHrp path
      $(el).attr "href", i18n_path_with_hrp
      return 
      
    return

  return

Template.support_page_article.helpers 
  getActiveNewsTitle: ->
    tpl = Template.instance()
    return TAPi18n.__ APP.justdo_crm.getItemByIdOrAlias(tpl.category, tpl.active_news_id_rv.get())?.news_doc?.title

  showNavigationBar: ->
    tpl = Template.instance()
    return tpl.show_navigation_bar

  showDropdownButton: ->
    tpl = Template.instance()
    return tpl.show_dropdown_button

  showDropdown: ->
    tpl = Template.instance()
    if tpl.show_dropdown
      return "dropdown"
    return

  otherNews: ->
    tpl = Template.instance()
    return APP.justdo_crm.getAllItemsByCategory(tpl.category)

  isNewsActive: ->
    if @_id is Template.instance().active_news_id_rv.get()
      return "active"
    return

  activeNews: ->
    tpl = Template.instance()
    return APP.justdo_crm.getItemByIdOrAlias(tpl.category, tpl.active_news_id_rv.get())?.news_doc

  isTabActive: (tab_id) ->
    active_tab_id = Template.instance().active_news_tab_rv.get()
    if tab_id is active_tab_id
      return "active"
    return

  getActiveNewsTemplate: ->
    tpl = Template.instance()
    news_doc = APP.justdo_crm.getItemByIdOrAlias(tpl.category, tpl.active_news_id_rv.get())?.news_doc
    active_tab = tpl.active_news_tab_rv.get()

    template = _.find news_doc.templates, (template_obj) -> template_obj._id is active_tab
    
    if not template.template_data?
      template.template_data = {}
    
    _.extend template.template_data,
      date: news_doc.date
      page_title: template.page_title
      page_description: template.page_description
      h1: template.h1

    return template

  getNewsPath: ->
    tpl = Template.instance()
    if not tpl.isRouterNavigation()
      return
    
    active_category = tpl.category
    template_name = "#{active_category.replaceAll "-", "_"}_page_with_news_id"
    news_id = @_id

    return tpl.getNewsPath template_name, {news_category: active_category, news_id: news_id}
  
  getNewsTabPath: ->
    tpl = Template.instance()
    if not tpl.isRouterNavigation()
      return

    active_category = tpl.category
    template_name = "#{active_category.replaceAll "-", "_"}_page_with_news_id_and_template"
    news_id = tpl.active_news_id_rv.get()
    news_template = @_id

    return tpl.getNewsPath template_name, {news_category: active_category, news_id: news_id, news_template: news_template}

Template.support_page_article.events
  "click .news-navigation-item": (e, tpl) ->
    tab_id = $(e.target).closest(".support-navigation-item").data "tab_id"

    # If router navigation is enabled, the href will take care of showing the correct content.
    if not tpl.isRouterNavigation()
      tpl.active_news_tab_rv.set tab_id

    return

  "click .dropdown-item": (e, tpl) ->
    news_id = $(e.target).closest(".dropdown-item").data("news_id")

    # If router navigation is enabled, the href will take care of showing the correct content.
    if not tpl.isRouterNavigation()
      tpl.active_news_id_rv.set news_id

    return
