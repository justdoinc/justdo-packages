Template.justdo_site_admins_page_menu_item.helpers
  page_id: -> Template.instance().data.id

  title: -> Template.instance().data.title

  isActive: ->
    tpl_data = Template.instance().data
    return tpl_data.current_view?.get() is tpl_data.id
