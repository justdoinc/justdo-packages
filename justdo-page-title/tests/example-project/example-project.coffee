if Meteor.isClient

  titleManager = new JustdoPageTitle.PageTitleManager {suffix:'JustDo', init_now:true}

#  Template.test.onCreated ->

#  Template.test.helpers


  Template.test.events

    "keyup #page-name": ->
      titleManager.setPageName $("#page-name").val()
      $("#section-name").val ''

    "keyup #section-name": ->
      titleManager.setSectionName $("#section-name").val()

    "click #clearTitle": ->
      $("#page-name").val ''
      $("#section-name").val ''
      titleManager.clear()
