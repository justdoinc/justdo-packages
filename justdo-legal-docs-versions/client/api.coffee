_.extend JustdoLegalDocsVersionsApi,
  getLegalDocsReportForLoggedInUser: (cb) ->
    Meteor.call('getLegalDocsReportForLoggedInUser', cb)