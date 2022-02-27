_.extend JustdoJobsProcessor,
  jobs_processor_collection: new Mongo.Collection "jobs_processor"
  # Example for forcing responsibility onto main::1
  # forced_responsibility:
  #   "main::1":
  #     "justdo-chat-email-notifications": {args: []}
  forced_responsibility:
    "main::1":
      "db-migrations": {args: []}