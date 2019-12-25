# During late 2019 we detected a rare issue where a ddp server can randomly stop sending the
# 'result' message for methods invocations, resulting in clients malfunction.
#
# The code below is an attempt to detect that malfunction and report it, in an effort to learn
# more about the issue and deal with the servers in which it happens.

init_method_result_malfunction_detector_after_ms = 5 * 1000
echo_interval_ms = 10 * 1000
timeout_detector_interval_ms = echo_interval_ms * 2

setTimeout ->
  last_response_received_time = new Date()

  reportDDPMethodResultMalfunctionIssue = _.once ->
    console.error "DDP MONITOR: DDP Method Result Malfunction"

    APP.justdo_analytics?.JAReportClientSideError("ddp-method-result-failure", JSON.stringify({"net-if-ips": APP.collections.JustdoSystem?.findOne("net-if")?.ips}))

    return

  echo_interval = setInterval ->
    Meteor.call "echo", (err, echo) ->
      if echo == "echo"
        last_response_received_time = new Date()

      return
  , echo_interval_ms

  echo_timeout_detector_interval = setInterval ->
    if Meteor.connection.status().status != "connected"
      # As long as we are disconnected, we are unable to tell whether or not the ddp server has
      # any defect, so we just pretent like valid results received
      last_response_received_time = new Date()
    else
      if (new Date() - last_response_received_time) > timeout_detector_interval_ms
        clearInterval(echo_interval)
        clearInterval(echo_timeout_detector_interval)

        reportDDPMethodResultMalfunctionIssue()

    return
  , timeout_detector_interval_ms

  return
, init_method_result_malfunction_detector_after_ms