symbols_regex = /^[a-z0-9-]+$/

take_control_loop_interval = 1000 * 4 # 4 seconds
keep_control_loop_interval = 1000 * 3 # 3 seconds
control_taken_ensure_delay = 300 # 0.3 seconds

_.extend JustdoJobsProcessor.prototype,
  _immediateInit: ->
    if not (configuration_string = @options.configuration_string)?
      @logger.info "No (or empty) configuration string, no job will be initiated"

      @destroy()

      return

    @registered_jobs = {}

    @jobs_under_responsibility = {}
    for job_conf_string in configuration_string.split(";")
      [job_id, job_args] = job_conf_string.split(":")

      @jobs_under_responsibility[job_id] = {args: []}

      if job_args?
        job_args = job_args.split(",")

        @jobs_under_responsibility[job_id].args = job_args

    if not (group_id = @options.group_id)? or group_id == ""
      throw @_error "wrong-conf", "@options.group_id (JUSTDO_JOBS_PROCESSOR_GROUP_ID) must be set if, @options.configuration_string (JUSTDO_JOBS_PROCESSOR_CONF) is set"

    if not (res = /^(.+?)::(\d{3}?)$/g.exec(group_id))?
      throw @_error "wrong-conf", "@options.group_id (JUSTDO_JOBS_PROCESSOR_GROUP_ID) format is invalid use: `<unique-id>::<version>`"

    group_uid = res[1]
    group_version = parseInt(res[2], 10)

    if (forced_responsibility = JustdoJobsProcessor?.forced_responsibility?["#{group_uid}::#{group_version}"])?
      for job_id, job_def of forced_responsibility
        job_args = job_def.args or []

        @jobs_under_responsibility[job_id] = {args: job_args}

    our_recent_flag = null
    recent_flag_found = null
    we_in_control = false
    contorl_taken_due_to_new_version = false

    takeControl = =>
      our_recent_flag = Random.id()
      recent_flag_found = null

      APP.justdo_analytics.logServerRecord {cat: "jobs-processor", act: "take-control-attempt"}
      JustdoJobsProcessor.jobs_processor_collection.update group_uid,
        {
          $set:
            group_version: group_version
            owner_flag: our_recent_flag
          $currentDate:
            updated: true
        },
        {upsert: true}

      ensureControlTaken()

      return

    ensureControlTaken = =>
      Meteor.setTimeout =>
        JustdoJobsProcessor.jobs_processor_collection.findOne({_id: group_uid}, {jd_analytics_skip_logging: true})

        APP.justdo_analytics.logServerRecord {cat: "jobs-processor", act: "control-taken"}

        we_in_control = true

        return
      , control_taken_ensure_delay

      if contorl_taken_due_to_new_version
        # If control taken due to new version, we need to wait the max time it might take
        # the instance from which control was taken, to recognize control was taken.
        Meteor.setTimeout =>
          @runJobs()
        , keep_control_loop_interval - control_taken_ensure_delay
      else
        @runJobs()

      return

    loseControl = =>
      our_recent_flag = null
      we_in_control = false

      APP.justdo_analytics.logServerRecord {cat: "jobs-processor", act: "control-lost"}

      @stopJobs()

      return

    #
    # Ensure control interval
    #
    Meteor.setInterval =>
      if not we_in_control
        return

      # @logger.debug "Ensure control interval (in control)"

      if not (processor_group_doc = JustdoJobsProcessor.jobs_processor_collection.findOne({_id: group_uid}, {jd_analytics_skip_logging: true}))?
        loseControl()

        return
      else if processor_group_doc.owner_flag == our_recent_flag
        our_recent_flag = Random.id()

        JustdoJobsProcessor.jobs_processor_collection.update group_uid,
          {
            $set:
              owner_flag: our_recent_flag
            $currentDate:
              updated: true
          },
          {upsert: true, jd_analytics_skip_logging: true}

        return
      else
        loseControl()

        return

      return
    , keep_control_loop_interval

    #
    # Take control interval
    #
    Meteor.setInterval =>
      if we_in_control
        return

      # @logger.debug "Take control interval (not in control)"

      if not (processor_group_doc = JustdoJobsProcessor.jobs_processor_collection.findOne({_id: group_uid}))?
        contorl_taken_due_to_new_version = false

        takeControl()

        return
      else if processor_group_doc.group_version < group_version
        contorl_taken_due_to_new_version = true

        takeControl()

        return
      else if not recent_flag_found?
        recent_flag_found = processor_group_doc.owner_flag

        return
      else if recent_flag_found == processor_group_doc.owner_flag
        contorl_taken_due_to_new_version = false

        takeControl()

        return
      else
        recent_flag_found = processor_group_doc.owner_flag

      return
    , take_control_loop_interval

    return

  runJobs: ->
    for job_id, job_def of @registered_jobs
      if job_id of @jobs_under_responsibility
        @logger.info "Running job: #{job_id}"

        job_def.jobInit.apply(@, @jobs_under_responsibility[job_id].args)

    return

  stopJobs: ->
    for job_id, job_def of @registered_jobs
      if job_id of @jobs_under_responsibility
        @logger.info "Stopping job: #{job_id}"

        job_def.jobStop.apply(@, @jobs_under_responsibility[job_id].args)

    return

  registerCronJob: (job_id, jobInit, jobStop) ->
    if @destroyed
      return

    if not symbols_regex.test(job_id)
      throw @_error "invalid-argument", "registerCronJob: job_id must be dash separated all-lower cased"

    if not _.isFunction(jobInit)
      throw @_error "invalid-argument", "registerCronJob: jobInit must be a function"

    @registered_jobs[job_id] = {jobInit, jobStop}

    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

