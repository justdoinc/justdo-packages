Template.settings_page_menu_item.helpers
  isActive: ->
    tpl_data = Template.instance().data
    return Router.current().route.getName() is tpl_data.target_route

Template.settings_page_menu_item.events
 "click .settings-page-menu-item": (e, tpl) ->
   url_name = Router.current()?.getParams()?.url_name
   Router.go tpl.data.target_route, {url_name}
   return
