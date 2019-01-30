# JustDo Jobs Processor

## Configuring server to process jobs

### Processor group conf

The jobs that should be processed by each server are configured using the `JUSTDO_JOBS_PROCESSOR_CONF` environmental variable.

JUSTDO_JOBS_PROCESSOR_CONF value should be of the following form:

```bash
JUSTDO_JOBS_PROCESSOR_CONF="job-id:comma-separated-args;job-id:comma-separated-args"
```

Only jobs ids that are specified in the JUSTDO_JOBS_PROCESSOR_CONF environmental variable will be initiated.

The args part is optional.

Hypothetical Example:

```bash
JUSTDO_JOBS_PROCESSOR_CONF="justdo-chat-email-notifications:1,a-h;daily-due-list"
```

Will init the daily-due-list and the justdo-chat-email-notifications passing to its
jobInit() (see below Registering Jobs) the value 1 as the first argument.

Notes:

* Unknown Jobs ids are ignored silently. All initiated jobs will be logged, so you can use
that as an indicator for your configuration correctness.

### Processor group id

Every server that has a non-empty JUSTDO_JOBS_PROCESSOR_CONF *must* have its
JUSTDO_JOBS_PROCESSOR_GROUP_ID configured to a unique ID.

Unique ID should be of the following format: "<unique-id>::<version>" .

<unique-id> can be any unique id that doesn't have the sequence '::' (it is case sensitive).
<version> should be a 3 digit zero-padded number, when you use a <unique-id> for the first time,
use: "001" (000 is also ok!).

When multiple instances of the app will use a JUSTDO_JOBS_PROCESSOR_GROUP_ID with
the same <unique-id> and same <version>, only one of them will be automatically elected
to serve as the jobs processor that will perform the jobs asigned to that group id.

If instances with different versions are running, the jobs performing instance will be elected
from the ones with the highest version.

Increase the version by 1 when changing the JUSTDO_JOBS_PROCESSOR_CONF ! (that's its purpose).

## Registering Jobs

A job can be registered by a package, or by the app, by calling the api:

APP.justdo_jobs_processor.registerCronJob(job_id, jobInit, jobStop)

Arguments:

* job_id: should be the unique, dash separated, id of the job.
* jobInit: should be a function that initiates the job.
* jobStop: should be a function that stops the job created by jobInit.

jobInit will be called only if it is specified in the JUSTDO_JOBS_PROCESSOR_CONF, and if the current
instance is elected to be the job processor. It will get as its arguments the args specified for it in
the JUSTDO_JOBS_PROCESSOR_CONF env var, if any were specified.

jobStop will be called when, for whatever reason, the instace loses its job processor capacity for the
processor group id. It will be called with the same args provided to jobInit.

Notes:

* Expect all args to have a String data type.

## Splitting a Job Work to Multiple Instances

One use-case the jobInit args can be used for is to design the job in a way that its work can be shared by multiple servers for scaling purposes.

For example, *assuming uniform distribution of the first character of users ids in the system*, a job that should do some processing for every user, can configure accept an argument that sets the range of users ids that
should be handled by it (example "a-m", "n-z", case insensitive, inclusive range).

Then, two instances can be configured in the following way:

```bash
# Server A
JUSTDO_JOBS_PROCESSOR_CONF="justdo-chat-email-notifications:a-m"

# Server B
JUSTDO_JOBS_PROCESSOR_CONF="justdo-chat-email-notifications:n-z"
```

Similarly, if further splitting is needed, more instances can share that job's work, in a similar way.
