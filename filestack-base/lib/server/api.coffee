# I believe that crypto is not available in all versions of node
# however it's available in the meteor shell, so I'm assuming that the version
# of node shipped with meteor 1.3 has crypto.
crypto = Npm.require('crypto')
# If we need to switch to a different crypto engine, this is the only function
# which needs updating
getHmac = (secret, message) ->
  hmacEngine = crypto.createHmac('sha256', secret)
  hmacEngine.update(message, 'utf8')
  return hmacEngine.digest('hex')

_.extend FilestackBase.prototype,
  signPolicy: (policy) ->
    policy = JSON.stringify policy

    # The url-safe base64 format is specified by filestack which simply
    # replaces two chars which are url-unsafe with two chars which are url-safe
    encodedPolicy = new Buffer(policy + '', 'utf8').toString('base64').replace(/\+/g, '-').replace(/\//g, '_')
    hmac = getHmac @options.secret, encodedPolicy

    return {
      policy: policy
      encoded_policy: encodedPolicy
      hmac: hmac
    }

  getHandle: (url) ->
    check(url, String)

    if url.match(/^https?:\/\/[^\\\/]+\.s3\.amazonaws\.com\//)
      regex = /([^\\\/_]+)_[^\\\/]+$/
      match = url.match(regex)
      return match?[1]
    else
      regex = /[^\\\/]+$/
      match = url.match(regex)
      return match?[0]

  _cleanupRemovedFileOptionsSchema: new SimpleSchema
    cleanup_from_task_document:
      # cleanup_from_task_document is optional
      #
      # Should be the task document of the task from which we should remove stored information about the file.
      #
      # We ask for the document and not the task_id since:
      #
      #   * The relevant task document might have been removed from the db already, and we just need to
      #   clean associated resources (such as remove converted files from filestack).
      #   * Save another call to the db to fetch it, in case we got it already.
      #
      # If provided, we:
      # 
      #   1. Will remove the file reference from the provided task's .files array.
      #   2. Will look for stored converted files of the provided file, if found:
      #     2.1 We will assume that the file also have data about its dimension stored, and will remove it
      #         from the db as well (if task hasn't been removed altogether).
      #         The file dimension is stored under: cleanup_from_task_document._secret.files_dimensions[file.id]
      #     2.2 We will remove converted files stored for file from filestack, and (if task hasn't been
      #         removed altogether), we will update the db accordingly.
      #         References to the converted files are under: 
      #           cleanup_from_task_document._secret.files_previews[file.id] # (file is the file
      #           object provided to cleanupRemovedFile())
      #
      # As mentioned above, by the time cleanupRemovedFile() with cleanup_from_task_document, the task might
      # had been removed from the db, our cleanups in such case are mostly critical to remove associated
      # information stored outside of the db.
      #
      # Learn more on comment left on @getPreviewDownloadLink() of tasks-file-manager/lib/server/api.coffee

      type: Object
      blackbox: true
      optional: true
  cleanupRemovedFile: (file, options) ->
    if not options?
      options = {}

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_cleanupRemovedFileOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if _.isString file
      file =
        id: @getHandle file

    if not Match.test file, Object
      throw @_error "expected-object", "File should be an object or file id (string)."

    # We're generating a policy for each request.
    # (Since we're on the server side, we could just as well generate a single
    # policy which gives full access to filestack, but then we'd have to manage
    # that key, this is simpler and fits with the way we're doing things
    # elsewhere.)
    policy =
      handle: file.id,
      expiry: Date.now() / (1000 + 60) * 30 # 30 minutes (to account for any clock mismatches)
      call: "remove"

    signed_policy = @signPolicy policy

    url = "https://www.filestackapi.com/api/file/#{file.id}?key=#{@options.api_key}&policy=#{signed_policy.encoded_policy}&signature=#{signed_policy.hmac}"
    try
      HTTP.del url
    catch e
      if not (e?.response?.statusCode == 404)
        throw e

    if (task_doc = options.cleanup_from_task_document)?
      # See comment above!

      #
      # Remove the file from the files array.
      #
      # Note, this one isn't done on the @rawCollection() we want regular update here, with updates to unmerged-publications
      # raw fields!
      #
      APP.collections.Tasks.update
        _id: task_doc._id
      ,
        $pull:
          "files":
            id: file.id

      #
      # Cleanup all the file's previews and associated data
      #
      any_found = false
      for file_preview_id, file_preview_def of task_doc._secret.files_previews[file.id]
        @cleanupRemovedFile(file_preview_def)

        any_found = true

      if any_found
        query = {_id: task_doc._id}
        update = 
          $unset:
            "_secret.files_previews.#{file.id}": ""
            "_secret.files_dimensions.#{file.id}": ""

        # We don't want the unmerged publications raw field, nor any other hook to trigger as a result
        # of that update, hence the use of the rawCollection()
        #
        # Note that by now the task document might had been removed already, but that will have no
        # effect on the following operation, that in such a case will do nothing.
        APP.justdo_analytics.logMongoRawConnectionOp(APP.collections.Tasks._name, "update", query, update)
        APP.collections.Tasks.rawCollection().update query, update, Meteor.bindEnvironment (err) ->
          if err?
            console.error(err)

            return

          return

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
