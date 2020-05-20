_.extend TasksFileManager.prototype,
  _immediateInit: ->
    @filestack_secret = @options.secret or throw @_error "api-secret-required"
    @filestack_api_key = @options.api_key or throw @_error "api-key-required"

  _deferredInit: ->
    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    @_setupFileDownloadRoute()

    return
  
  _setupFileDownloadRoute: ->
    self = @

    Router.route TasksFileManager.file_download_route, ->
      req = @request
      res = @response

      task_id = req.query.task_id
      file_id = req.query.file_id

      try 
        check task_id, String
        check file_id, String
      catch e
        res.statusCode = 400
        res.end "INVALID PARAMETERS"
        
        return

      if not (user_doc = JustdoHelpers.getUserObjFromMeteorLoginTokenCookie(req))?
        res.statusCode = 403
        res.end "AUTH FAILED"

        return
        
      try
        download_link = self.getDownloadLink task_id, file_id, user_doc._id
      catch e
        self.logger.debug e 
        res.statusCode = 500
        res.end()

        return

      res.writeHead 301,
        Location: "#{download_link}&dl=true"
      res.end()

      return
    ,
      where: "server"
