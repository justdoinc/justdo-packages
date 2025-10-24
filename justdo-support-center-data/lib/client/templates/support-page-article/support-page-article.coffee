Template.support_page_article.onCreated ->
  @parent_tpl = @data.parent_tpl

  @category = share.news_category
  if not (most_recent_news_id = APP.justdo_crm.getMostRecentItemObjUnderCategory(@category)?._id)?
    throw APP.justdo_crm._error "news-category-not-found"
  
  @active_news_id_rv = new ReactiveVar(@parent_tpl?.getActiveArticle?() or most_recent_news_id)
  @getActiveArticle = ->
    return @active_news_id_rv.get()
  @setActiveArticle = (news_id) ->
    @parent_tpl?.setActiveArticle? news_id
    @active_news_id_rv.set news_id
    return

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
      @parent_tpl?.setActiveArticle? news_id
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

Template.support_page_article.helpers 
  getActiveNewsTitle: ->
    tpl = Template.instance()
    active_news_id = tpl.getActiveArticle()
    return TAPi18n.__ APP.justdo_crm.getItemByIdOrAlias(tpl.category, active_news_id)?.news_doc?.title

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
    if @_id is Template.instance().getActiveArticle()
      return "active"
    return
  
  getActiveNewsId: ->
    tpl = Template.instance()
    active_news_id = tpl.getActiveArticle()
    return active_news_id

  getActiveNewsTemplate: ->
    tpl = Template.instance()
    active_news_id = tpl.getActiveArticle()
    news_doc = APP.justdo_crm.getItemByIdOrAlias(tpl.category, active_news_id)?.news_doc
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
  
  activeTag: ->
    tpl = Template.instance()
    active_tag_id = tpl.parent_tpl?.getActiveTag?()

    # If the active tag is share.default_tag, we don't need to show it in the breadcrumb.
    if active_tag_id is share.default_tag
      return
    
    active_tag = share.supported_tags.find((category) -> category._id is active_tag_id)

    return active_tag

  currentRouteName: ->
    return APP.justdo_i18n_routes.getCurrentRouteName()

Template.support_page_article.events
  "click .dropdown-item": (e, tpl) ->
    news_id = $(e.target).closest(".dropdown-item").data("news_id")

    # If router navigation is enabled, the href will take care of showing the correct content.
    if not tpl.isRouterNavigation()
      tpl.parent_tpl?.setActiveArticle news_id

    return

  "click .breadcrumb-item": (e, tpl) ->
    $target = $(e.currentTarget)
    if $target.hasClass("back")
      history.back()
    else if $target.hasClass("home")
      tpl.parent_tpl?.setActiveTag? share.default_tag
      tpl.parent_tpl?.setActiveArticle? null
    else if $target.hasClass("active-tag")
      tpl.parent_tpl?.setActiveArticle? null

    return
