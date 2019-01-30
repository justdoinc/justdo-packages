counter = 0

ConsoleDriver = ->
  JustdoAnalytics.StorageDriverPrototype.call this

  return @

Util.inherits ConsoleDriver, JustdoAnalytics.StorageDriverPrototype

_.extend ConsoleDriver.prototype,
  init: (done, fail) ->
    # Gets 2 callbacks as parameter:
    # done() should be called upon sucessful connection to the storage driver
    # fail() should be called if connection couldn't be established.

    # Keep for testing of pre-driver ready logs
    #
    # Meteor.setTimeout ->
    #   console.log "HERE"
    #   done()
    # , 20000

    done()

    return @

  writeState: (state) ->
    # We take care of queueing for you write requests until init calls done(),
    # don't worry about that aspect, assume writeState is called only after
    # init completed.

    args = [
      "JA::STA".magenta
      JustdoHelpers.padString(counter++, 3)
      "#{state.CType}".green
      "A=" + "#{state.ASID}".white + ":SSID=" + "#{state.SSID}".yellow + ":S=" + "#{state.SID}".yellow + ":U=" + "#{state.UID}".cyan
    ]

    console.log args.join("|")

    # console.log state

    return

  writeLog: (log, analytics_state) ->
    # We take care of queueing for you write requests until init calls done(),
    # don't worry about that aspect, assume writeState is called only after
    # init completed.

    {SID, UID, CType} = analytics_state

    args = [
      "JA::LOG".yellow
      JustdoHelpers.padString(counter++, 3)
      "#{CType}".green
      "A=" + "#{log.ASID}".white + ":S=" + "#{SID}".yellow + ":U=" + "#{UID}".cyan
      "#{log.cat}:#{log.act}:#{log.cls.join(",")}:#{log.val}".white
    ]

    console.log args.join("|")

    # console.log log

    return

  logServerSession: (server_session) ->
    args = [
      "JA::SERVER_SESSION".yellow
      JustdoHelpers.padString(counter++, 3)
      "SSID=" + "#{server_session.SSID}".cyan + ":env=" + "#{EJSON.stringify(server_session.environment)}".yellow + ":ENC_LOCAL_PASS=" + "#{server_session.devops_password_encrypted}".white
    ]

    console.log args.join("|")

    return

  logServerRecord: (log) ->
    args = [
      "JA::SERVER_LOG".yellow
      JustdoHelpers.padString(counter++, 3)
      "SSID=" + "#{log.SSID}".yellow +
              ":UID=" + "#{log.UID}".white +
              ":CID=" + "#{log.CID}".white +
              ":cat=" + "#{log.cat}".white +
              ":act=" + "#{log.act}".white +
              ":val=" + "#{log.val} ".white
    ]

    console.log args.join("|")

    return


JustdoAnalytics.StorageDrivers.console = ConsoleDriver
