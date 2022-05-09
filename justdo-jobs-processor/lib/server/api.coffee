symbols_regex = /^[a-z0-9-]+$/

_.extend JustdoJobsProcessor.prototype,
  take_control_loop_interval: 1000 * 4 # 4 seconds
  keep_control_loop_interval: 1000 * 3 # 3 seconds
  control_taken_ensure_delay: 300 # 0.3 seconds

  _immediateInit: ->
    @running_jobs = {}
    @our_recent_flag = null
    @in_take_control_process = false
    @flag_update_in_progress = false
    @our_recent_flag_being_replaced = null

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

    @group_uid = res[1]
    @group_version = parseInt(res[2], 10)

    if (forced_responsibility = JustdoJobsProcessor?.forced_responsibility?["#{@group_uid}::#{@group_version}"])?
      for job_id, job_def of forced_responsibility
        job_args = job_def.args or []

        @jobs_under_responsibility[job_id] = {args: job_args}

    @recent_flag_found = null
    @we_in_control = false
    @contorl_taken_due_to_new_version = false

    #
    # Ensure control interval
    #
    Meteor.setInterval =>
      if not @we_in_control
        return

      if @in_take_control_process is true
        @logger.info "In take control interval - Skip 'Ensure control interval' process"
        return

      @ensureStillInControl(true)

      return
    , @keep_control_loop_interval

    #
    # Take control interval
    #
    Meteor.setInterval =>
      if @we_in_control
        return

      if @in_take_control_process is true
        @logger.info "In take control interval - Skip 'Take control interval' process"
        return

      # @logger.debug "Take control interval (not in control)"

      if not (processor_group_doc = JustdoJobsProcessor.jobs_processor_collection.findOne({_id: @group_uid}))?
        @contorl_taken_due_to_new_version = false

        @takeControl()

        return
      else if processor_group_doc.group_version < @group_version
        @contorl_taken_due_to_new_version = true

        @takeControl()

        return
      else if not @recent_flag_found?
        @recent_flag_found = processor_group_doc.owner_flag

        return
      else if @recent_flag_found == processor_group_doc.owner_flag
        @contorl_taken_due_to_new_version = false

        @takeControl()

        return
      else
        @recent_flag_found = processor_group_doc.owner_flag

      return
    , @take_control_loop_interval

    return

  takeControl: ->
    if @in_take_control_process is true
      @logger.info "Already in the takeControl process"
      return

    @in_take_control_process = true
    @logger.info "Attempt to take control"

    @our_recent_flag = Random.id()
    @recent_flag_found = null

    APP.justdo_analytics.logServerRecord {cat: "jobs-processor", act: "take-control-attempt"}
    JustdoJobsProcessor.jobs_processor_collection.update @group_uid,
      {
        $set:
          group_version: @group_version
          owner_flag: @our_recent_flag
        $currentDate:
          updated: true
      },
      {upsert: true}

    doIfControlEnsured = (cb) =>
      if not @ensureStillInControl()
        @in_take_control_process = false

        @logger.info "Attempt to take control failed"
      else
        cb()

      return

    completeTakeControl = =>
      doIfControlEnsured =>
        @in_take_control_process = false
        @we_in_control = true
        @logger.info "Control received"
        APP.justdo_analytics.logServerRecord {cat: "jobs-processor", act: "control-taken"}

        @runJobs()

        return

      return

    Meteor.setTimeout =>
      doIfControlEnsured =>
        if @contorl_taken_due_to_new_version
          # If control taken due to new version, we need to wait the max time it might take
          # the instance from which control was taken, to recognize control was taken.
          Meteor.setTimeout =>
            completeTakeControl()
            return
          , @keep_control_loop_interval - @control_taken_ensure_delay
        else
          completeTakeControl()

        return
      return
    , @control_taken_ensure_delay

    return

  ensureStillInControl: (update_owner_flag=false) ->
    # @logger.debug "Ensure control interval (in control)"

    if not (processor_group_doc = JustdoJobsProcessor.jobs_processor_collection.findOne({_id: @group_uid}, {jd_analytics_skip_logging: true}))?
      @loseControl()

      return false
    else if processor_group_doc.owner_flag in [@our_recent_flag, @our_recent_flag_being_replaced]
      if not update_owner_flag
        return true
      else
        if @flag_update_in_progress
          @logger.warn "A request to ensureStillInControl with update_owner_flag=true received while already in the process of updating a flag - this should never happen!"

          # Consider as true in such a case, don't update flag while the update is in-progress
          return true
        
        @flag_update_in_progress = true
        @our_recent_flag_being_replaced = @our_recent_flag
        @our_recent_flag = Random.id()

        JustdoJobsProcessor.jobs_processor_collection.update @group_uid,
          {
            $set:
              owner_flag: @our_recent_flag
            $currentDate:
              updated: true
          },
          {upsert: true, jd_analytics_skip_logging: true}

        @flag_update_in_progress = false
        # Don't init @our_recent_flag_being_replaced to null ; to avoid race conditions in which the previous flag will be received from the db - even though we already out of @flag_update_in_progress

        return true
    else
      @loseControl()

      return false

    return

  runJobs: ->
    @logger.info "Run Jobs"

    for job_id, job_def of @registered_jobs
      if job_id of @jobs_under_responsibility
        @logger.info "Running job: #{job_id}"

        if @running_jobs[job_id]?
          @logger.info "runJob: #{job_id} is already running, skipping"
        else
          try
            @running_jobs[job_id] = true
            job_def.jobInit.apply(@, @jobs_under_responsibility[job_id].args)
          catch e
            @logger.info "Attempt to run job #{job_id} failed due to an error"
            console.error e

        if not @ensureStillInControl()
          @logger.info "runJob: control lost while in the loop! break the runJob loop"
          @logger.info "runJob: call stopJobs to ensure jobs that ran during the loop are stopped!"

          @stopJobs()

          return

    return

  loseControl: ->
    if not @we_in_control
      # We aren't in control, nothing to do
      return

    @our_recent_flag = null
    @we_in_control = false

    APP.justdo_analytics.logServerRecord {cat: "jobs-processor", act: "control-lost"}

    @stopJobs()

    return

  stopJobs: ->
    @logger.info "Stop Jobs"

    for job_id, job_def of @registered_jobs
      if job_id of @jobs_under_responsibility
        @logger.info "Stopping job: #{job_id}"

        delete @running_jobs[job_id]
        job_def.jobStop.apply(@, @jobs_under_responsibility[job_id].args)

        if @ensureStillInControl()
          @logger.info "stopJobs: control received while in the loop! break the stopJobs loop"
          @logger.info "stopJobs: call runJobs for jobs stopped during the loop that should actually run"
          @runJobs() # runJobs to run jobs we might stopped that are now should be running.

          return

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

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

