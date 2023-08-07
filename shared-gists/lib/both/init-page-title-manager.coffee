if Meteor.isClient
  options = {}
  client_type = JustdoHelpers.getClientType env
  
  if client_type is "web-app"
    options = {suffix: "JustDo"}

  APP.page_title_manager = new PageTitleManager options
  