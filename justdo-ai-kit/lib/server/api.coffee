_.extend JustdoAiKit.prototype,
  _immediateInit: ->
    @apis = {}
    @request_templates = {}

    if @secret_conf.vendors?.openai?
      # Defined in verdor-api/openai.coffee
      @_setupOpenAI()
    
    @_registerRequestTemplates()

    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    @_setupEventHooks()

    return
  
  _setupEventHooks: ->
    self = @

    if @app_type is "web-app"
      APP.projects.on "pre-create-first-project-for-new-user", (new_user_doc, create_new_project_options) =>
        user_campaign_id = new_user_doc.promoters?.referring_campaign_id
        if self._isUserCampaignAllowFirstProjectTemplateGeneratorToShow user_campaign_id
          create_new_project_options.init_first_task = false
        return
      
      APP.projects.on "post-handle-jd-creation-request", (jd_creation_req, project_id, user_id) ->
        if jd_creation_req?.source isnt "ai"
          return
        
        if not jd_creation_req.justdo_title?
          # Setup first justdo title
          if (cache_token = jd_creation_req.ai_cache_token)? and (template = APP.justdo_projects_templates?.getTemplateById cache_token)?
            project_title = APP.justdo_i18n?.tr template.label_i18n, null, user
          else if not _.isEmpty(jd_creation_req.ai_prompt)
            res = await self.generateProjectTitle jd_creation_req.ai_prompt, user_id
            project_title = res.title
            self.logResponseUsage res.req_id, "a", project_title, user_id

          self.projects_collection.update project_id, {$set: {title: project_title}}

        # Find all logs with pre_register_id and update it with actual user_id
        if (pre_register_id = jd_creation_req.pre_register_id)?
          self.associatePreRegisterIdWithUserId pre_register_id, user_id
        
        return

    return

  _registerRequestTemplateOptionsSchema: new SimpleSchema
    api_provider:
      type: String
    template_id:
      type: String
    requestGeneratorOptionsSchema:
      type: SimpleSchema
      blackbox: true
      optional: true
    requestGenerator:
      type: Function
    cachedResponseCondition: 
      type: Function
      optional: true
    cachedResponsePublisher:
      type: Function
      optional: true
    streamed_response_format:
      type: String
      allowedValues: _.keys JustdoAiKit.supported_streamed_response_types
      optional: true
    streamedResponseParser:
      type: Function
      optional: true
    # Whether the template allows anonymous user to use
    allow_anon:
      type: Boolean
      optional: true
  registerRequestTemplate: (options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerRequestTemplateOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    @requireApiProvider options.api_provider
    
    @request_templates[options.template_id] = options
    return

  getRequestTemplate: (template_id) ->
    if not (request_template = @request_templates[template_id])?
      return 
    
    return _.extend {}, request_template
    
  requireRequestTemplate: (template_id) ->
    if not (request_template = @getRequestTemplate template_id)?
      throw @_error "invalid-argument", "Request template #{template_id} not found"

    return request_template
  
  _registerRequestTemplates: ->
    for template_id, req_template_def of JustdoAiKit.request_templates
      options = _.extend {template_id: template_id}, req_template_def
      @registerRequestTemplate options
    return

  requireApiProvider: (api_provider) ->
    if not (vendor_apis = @[api_provider])?
      throw @_error "invalid-argument", "API provider #{api_provider} not found"
    return vendor_apis

  _logRequestOptionsSchema: new SimpleSchema
    resource:
      type: String
    template:
      type: Object
      blackbox: true
    template_data:
      type: Object
      blackbox: true
    req_id:
      type: String
    pre_register_id:
      type: String
      optional: true
    simplify_response:
      type: Boolean
      optional: true
  _logRequest: (options, user_id) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_logRequestOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val
    resource = options.resource
    template = options.template
    template_data = options.template_data
    req_id = options.req_id
    pre_register_id = options.pre_register_id
    simplify_response = options.simplify_response
    
    app_type = JustdoHelpers.getClientType() # "web-app" or "landing-app"
    version = JustdoHelpers.getAppVersion false # pass false to obtain app version even if it's not exposed to client side
    jdv = "#{app_type[0]}-#{version}"
    # Create and insert query request, and other metadata
    query_log = 
      provider: template.api_provider
      resource: resource
      req_id: req_id
      req: 
        template_id: template.template_id
        data: template_data
        jdv: jdv
      simplify_response: simplify_response
      performed_by: user_id
      pre_register_id: pre_register_id
    return @query_collection.insert query_log

  _newStream: ->
    # To be implemented per Vendor API

    throw @_error "not-implemented"

    return

  _newStreamOptionsSchema: new SimpleSchema
    template:
      type: Match.OneOf(String, Object)
      blackbox: true
    template_data:
      type: Object
      blackbox: true
    req_id:
      type: String
    pre_register_id:
      type: String
      optional: true
    simplify_response:
      type: Boolean
      optional: true
  newStream: (options, user_id) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_newStreamOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if _.isString options.template
      template = @requireRequestTemplate options.template
    else
      template = options.template

    pre_register_id = options.pre_register_id
    if (not user_id?) and (not pre_register_id?)
      throw @_error "missing-argument", "Either user_id or pre_register_id must be provided"
    
    if (not user_id?) and (template.allow_anon isnt true)
      throw @_error "login-required"

    stream_type = template.streamed_response_format
    vendor_apis = @requireApiProvider template.api_provider

    {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
      template.requestGeneratorOptionsSchema,
      options.template_data,
      {self: @, throw_on_error: true}
    )
    template_data = cleaned_val

    log_request_options = 
      resource: "chat.completions"
      template: template
      template_data: template_data
      req_id: options.req_id
      pre_register_id: pre_register_id
      simplify_response: options.simplify_response
    log_id = @_logRequest log_request_options, user_id

    await return vendor_apis._newStream(stream_type, template, template_data, log_id, user_id)

  _newChatCompletion: ->
    # To be implemented per Vendor API

    throw @_error "not-implemented"

    return

  _newChatCompletionOptionsSchema: new SimpleSchema
    template:
      type: Match.OneOf(String, Object)
      blackbox: true
    template_data:
      type: Object
      blackbox: true
    pre_register_id:
      type: String
      optional: true
  newChatCompletion: (options, user_id) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_newChatCompletionOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val
    {template, template_data, pre_register_id} = options

    if _.isString template
      template = @requireRequestTemplate template

    if (not user_id?) and (not pre_register_id?)
      throw @_error "missing-argument", "Either user_id or pre_register_id must be provided"
    
    if (not user_id?) and (template.allow_anon isnt true)
      throw @_error "login-required"

    vendor_apis = @requireApiProvider template.api_provider

    {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
      template.requestGeneratorOptionsSchema,
      template_data,
      {self: @, throw_on_error: true}
    )
    template_data = cleaned_val

    req_id = Random.id()
    log_request_options = 
      resource: "chat.completions"
      template: template
      template_data: template_data
      req_id: req_id
      pre_register_id: pre_register_id
    log_id = @_logRequest log_request_options, user_id

    res = await vendor_apis._newChatCompletion(template, template_data, log_id, user_id)

    ret = {res, req_id}

    return ret

  _getAIRequestsLogOptionsSchema: new SimpleSchema
    user_id:
      type: String
      optional: true
    vendor:
      type: String
      optional: true
    resource:
      type: String
      optional: true
    choice:
      type: Array
      optional: true
    "choice.$":
      type: String
      allowedValues: ["a", "p", "d"]
    anon_only:
      type: Boolean
      optional: true
    aborted:
      type: Boolean
      optional: true
    has_error:
      type: Boolean
      optional: true
    starting_ts:
      type: Number
      optional: true
    ending_ts:
      type: Number
      optional: true
    fields:
      type: Object
      blackbox: true
      optional: true
  getAIRequestsLog: (options, performing_user_id) ->
    if not APP.justdo_site_admins?
      # In case site admins is not enabled when it's called with performing_user_id, we don't return any value.
      throw @_error "site-admin-required"
    else
      APP.justdo_site_admins.requireUserIsSuperSiteAdmin performing_user_id
    
    {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
      @_getAIRequestsLogOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )
    options = cleaned_val
    
    query = {}
    if (user_id = options.user_id)? and options.anon_only
      throw @_error "not-supported", "Cannot query for both user_id and anon_only"

    if user_id?
      query.performed_by = options.user_id
    if options.anon_only
      query.performed_by = null
      query.pre_register_id = {$ne: null}
    if options.vendor?
      query.provider = options.vendor
    if options.resource?
      query.resource = resource
    if options.starting_ts?
      if not query.createdAt?
        query.createdAt = {}
      query.createdAt.$gte = new Date(options.starting_ts)
    if options.ending_ts?
      if not query.createdAt?
        query.createdAt = {}
      query.createdAt.$lte = new Date(options.ending_ts)
    if options.choice?
      query.choice = {$in: options.choice}
    if options.aborted
      query.aborted = {$ne: null}
    if options.has_error
      query.error = {$ne: null}

    query_options = 
      sort:
        createdAt: -1
    return @query_collection.find(query, query_options).fetch()

  generateProjectTitle: (msg, user_id) ->
    check msg, String
    check user_id, String
    
    template_id = "generate_project_title"
    template_data = 
      msg: msg

    options = 
      template: template_id
      template_data: template_data
    response = await @newChatCompletion options, user_id

    response.title = response.res.choices?[0]?.message?.content
    delete response.res

    return response

  generateTaskTitle: (msg, user_id) ->
    check msg, String
    check user_id, String
    
    template_id = "generate_task_title"
    template_data = 
      msg: msg

    options = 
      template: template_id
      template_data: template_data
    response = await @newChatCompletion options, user_id

    response.title = response.res.choices?[0]?.message?.content
    delete response.res

    return response
  
  logResponseUsage: (req_id, choice, choice_data, user_id) ->
    query = 
      req_id: req_id
    if not _.isEmpty user_id
      query.performed_by = user_id
    
    modifier =
      $set:
        choice: choice
        choice_data: choice_data
        choice_ts: new Date()
    
    return @query_collection.update query, modifier
  
  associatePreRegisterIdWithUserId: (pre_register_id, user_id) ->
    query = 
      pre_register_id: pre_register_id
      performed_by: null
    modifier =
      $set:
        performed_by: user_id
    return @query_collection.update query, modifier, {multi: true}
  
  callChatAssistant: (context, user_id) ->
    check user_id, String

    options = 
      template: "chat_assistant"
      template_data: context

    {res} = await @newChatCompletion options, user_id
    res_content = res?.choices?[0]?.message?.content

    return res_content
