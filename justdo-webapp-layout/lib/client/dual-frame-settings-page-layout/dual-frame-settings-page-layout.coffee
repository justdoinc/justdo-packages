Template.dual_frame_settings_page_layout.helpers
  leftDrawerItems: ->
    tpl = Template.instance()
    items = _.map JD.getPlaceholderItems(tpl.data.menu_domain), (item) ->
      return item
    return items

  menuTitle: -> Template.instance().data.menu_title

  pageTitle: -> Template.instance().data.page_title

  pageTemplate: -> Template.instance().data.page_template

Template.dual_frame_settings_page_layout.events
  "click .site-admins-menu-item": (e, tpl) ->
    target = $(e.target.closest(".site-admins-menu-item")).attr "target"
    tpl.current_view.set target
    Router.go "justdo_site_admins_page_#{target.replaceAll "-", "_"}"
    return
