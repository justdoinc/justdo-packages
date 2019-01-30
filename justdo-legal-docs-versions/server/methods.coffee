Meteor.publish null, ->
  publication_this = @

  if not publication_this.userId
    publication_this.ready()

    return

  user_tracker = Meteor.users.find({_id: @userId}, {fields: {signed_legal_docs: 1}})
    .observeChanges
      added: (id, fields) ->
        publication_this.added("JustdoSystem", "legal_docs", JustdoLegalDocsVersionsApi.getLegalDocsReportForUserDoc(fields))

        return

      changed: (id, fields) ->
        publication_this.changed("JustdoSystem", "legal_docs", JustdoLegalDocsVersionsApi.getLegalDocsReportForUserDoc(fields))

        return

      removed: (id) ->
        # Note, I doubt this will ever happen, kept for completness -Daniel
        publication_this.stop() # Stop the publication so Meteor will clean all documents
                                # sent by this publication

  publication_this.onStop ->
    user_tracker.stop()

  publication_this.ready()

  return

Meteor.methods
  getLegalDocsReportForLoggedInUser: ->
    return JustdoLegalDocsVersionsApi.getLegalDocsReportForUserDoc(Meteor.users.findOne({_id: @userId}, {fields: {signed_legal_docs: 1}}))