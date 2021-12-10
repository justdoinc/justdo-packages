_.extend JustdoJobsProcessor,
  jobs_processor_collection: new Mongo.Collection "jobs_processor"
  forced_responsibility:
    "main::1":
      "justdo-db-migration":
        jobInit: -> return console.log "Job started"
        jobStop: -> return console.log "Job ended"
