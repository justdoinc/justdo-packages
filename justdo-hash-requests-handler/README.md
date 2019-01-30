# Hash Requests Handler

## Quick start:

1. Init

```
APP.hash_requests_handler = new HashRequestsHandler
  prefix: "hr" # All args in the hash that should be detected by the handler
               # will have to be prefixed with this prefix.
```

2. Assign requests handlers:

```
# "unsubscribe-projects" will be used as the handler id.
# In order to call this handler use: 
APP.hash_requests_handler.addRequestHandler "unsubscribe-projects", (args) =>
  if not (projects = args.projects)?
    @logger.warn "Hash request: unsubscribe-projects: received with no projects argument, ignoring request"

    return

  projects = projects.split(",")

  @configureEmailUpdatesSubscriptions projects, false, (err) ->
    common_message = "Successfully unsubscribed you from daily email updates for"
    if projects[0] == "*"
      bootbox.alert("#{common_message} all projects.")
    else if projects.length > 1 
      bootbox.alert("#{common_message} all requested projects.")
    else
      bootbox.alert("#{common_message} the requested project.")

    return

  return
```

3. Run

```
APP.hash_requests_handler.run()
```

4. Call in any route: #?hr-id=unsubscribe-projects&hr-projects=*

The hash request handler added above will be called with args: {projects: "*"}

Note, the args values are being decodeURIComponent() before we serve them
to the handler

## More

Stop the hash requests handler:

APP.hash_requests_handler.stop()