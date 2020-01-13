import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions({
  'mysql': '2.13.x'
}, 'justdoinc:justdo-analytics')

mysql = require('mysql')

env = process.env

host = env.JUSTDO_ANALYTICS_MYSQL_STORAGE_HOST
port = env.JUSTDO_ANALYTICS_MYSQL_STORAGE_PORT
user = env.JUSTDO_ANALYTICS_MYSQL_STORAGE_USER
password = env.JUSTDO_ANALYTICS_MYSQL_STORAGE_PASSWORD
db_name = env.JUSTDO_ANALYTICS_MYSQL_STORAGE_DATABASE_NAME

getInitDBQueries = (db_name) ->
  {category_max_length, action_max_length, value_max_length, user_agent_length,
     cls_max_length, max_classes_per_log} =
    JustdoAnalytics.schemas_consts

  cls_length = (cls_max_length * max_classes_per_log) + (max_classes_per_log - 1 + 2) # -1 to signify the | separators between classes, +2 for the pre/suffix |

  [
    # Uncomment to create the DB work environment
    # """
    # CREATE DATABASE IF NOT EXISTS `#{db_name}` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */;
    # """

    """
    USE #{db_name};
    """

    # SUPER DENGEROUS!!! - BE VERY CAREFUL - MAKE SURE YOU ARE NOT
    # RUNNING AGAINST PROD

    # Remove the | char before running (was placed to reduce risk of mistake)
    # "|DROP TABLE IF EXISTS `JDAnalyticsStates`;"

    # Uncomment to create the table in work environment
    # """
    # CREATE TABLE IF NOT EXISTS `JDAnalyticsStates` (
    #   `ASID` char(17) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Analytics State ID',
    #   `SSID` char(45) COLLATE utf8_unicode_ci NULL COMMENT 'The Server Session ID on which this Analytics State is living',
    #   `UID` char(17) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'The Meteor User ID for the logged-in user - null if user isn''t logged in.\n',
    #   `CID` char(17) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Connection ID - An ID given by Meteor to every connection. Might not survive login/register in some cases, doesn’t survive server disconnection. Move between web app to landing app.',
    #   `DID` char(17) COLLATE utf8_unicode_ci NOT NULL COMMENT 'A unique ID set for the device - should survive between reopening of the app, connection reset, login/logout.\n',
    #   `SID` char(17) COLLATE utf8_unicode_ci NOT NULL COMMENT 'user session ID - A unique ID set when the tab (on mobile the application) is opened reset when the user logout or if the tab is closed - should survive server connection interruptions\n+ should move with the user between landing app and web app .\n',
    #   `IP` char(15) COLLATE utf8_unicode_ci NOT NULL COMMENT 'The client''s IP',
    #   `CType` char(15) COLLATE utf8_unicode_ci NOT NULL COMMENT 'The client type, e.g. web-app , landing-app, ios-app, android-app',
    #   `acceptLanguage` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'The HTTP accept-language header as received from the client',
    #   `userAgent` varchar(#{user_agent_length}) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'The HTTP accept-language header as received from the client',
    #   `appVersion` varchar(64) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Mobile app version / web app version / landing app version',
    #   `serverBuild` varchar(64) COLLATE utf8_unicode_ci NOT NULL COMMENT 'The server build / Protocol version',
    #   `baseURL` varchar(64) COLLATE utf8_unicode_ci NOT NULL COMMENT 'The landing page url for the environment. tdm.justdo.today justdo.today beta.justdo.today',
    #   `TS` datetime DEFAULT CURRENT_TIMESTAMP,
    #   PRIMARY KEY (`ASID`),
    #   KEY `byUID` (`UID`),
    #   KEY `byDID` (`DID`),
    #   KEY `bySID` (`SID`)
    # ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    # """

    # SUPER DENGEROUS!!! - BE VERY CAREFUL - MAKE SURE YOU ARE NOT
    # RUNNING AGAINST PROD

    # Remove the | char before running (was placed to reduce risk of mistake)
    # "|DROP TABLE IF EXISTS `JDAnalyticsData`;"

    # Uncomment to create the table in work environment
    # """
    # CREATE TABLE IF NOT EXISTS `JDAnalyticsData` (
    #   `ADID` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Analytics Data ID',
    #   `ASID` char(17) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Analytics State ID\n',
    #   `TS` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp',
    #   `PID` char(17) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'project ID',
    #   `cat` char(#{category_max_length}) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Category',
    #   `act` char(#{action_max_length}) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Action',
    #   `cls` varchar(#{value_max_length}) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'A | separated list of classes attached to the log (also begin and ends with |)',
    #   `val` varchar(#{value_max_length}) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Free text value, could be comma separated or other',
    #   PRIMARY KEY (`ADID`),
    #   KEY `byASID` (`ASID`),
    #   KEY `byCat` (`cat`)
    # ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    # """

    # Remove the | char before running (was placed to reduce risk of mistake)
    # "|DROP TABLE IF EXISTS `JDServersSessions`;"

    # Uncomment to create the table in work environment
    # """
    # CREATE TABLE IF NOT EXISTS `JDServersSessions` (
    #   `SSID` char(45) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Server Session ID\n',
    #   `TS` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp',
    #   `devopsPasswordEncrypted` text COLLATE utf8_unicode_ci NULL COMMENT 'The symmetric password used to encrypt the server records for this SSID, \n encrypted with the DEVOPS_PUBLIC_KEY\n',
    #   `environmentJson` text COLLATE utf8_unicode_ci NOT NULL COMMENT 'JSONed details about the environment',
    #   PRIMARY KEY (`SSID`),
    #   KEY `byTimestamp` (`TS`)
    # ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    # """

    # Remove the | char before running (was placed to reduce risk of mistake)
    # "|DROP TABLE IF EXISTS `JDServersRecords`;"

    # Uncomment to create the table in work environment
    # """
    # CREATE TABLE IF NOT EXISTS `JDServersRecords` (
    #   `SRID` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Server Record ID',
    #   `SSID` char(45) COLLATE utf8_unicode_ci NOT NULL COMMENT 'The server Session ID from which this log is coming\n',
    #   `TS` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp',
    #   `UID` char(17) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'The Meteor User ID for the logged-in user - null if user isn''t logged in, or if a User ID can''t be determined. Non-normalized, as data can be determined from the CID, that''s on purpose to ease using the data.',
    #   `CID` char(17) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Connection ID - An ID given by Meteor to every connection. Can be used to map the server record to the set of analytics states of JDAnalyticsStates using JDAnalyticsStates.CID',
    #   `cat` char(#{category_max_length}) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Category',
    #   `act` char(#{action_max_length}) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Action',
    #   `val` text COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Free text value, could be comma separated or other',
    #   PRIMARY KEY (`SRID`),
    #   KEY `byTimestamp` (`TS`)
    # ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    # """

  ]

MysqlDriver = ->
  JustdoAnalytics.StorageDriverPrototype.call this

  return @

Util.inherits MysqlDriver, JustdoAnalytics.StorageDriverPrototype

con = null

_.extend MysqlDriver.prototype,
  init: (done, fail) ->
    if not _.isEmpty(host)?
      host = "127.0.0.1"
      
    if not _.isEmpty(port)?
      port = "3306"

    if not (_.isEmpty(user)? and _.isEmpty(password)? and _.isEmpty(db_name)?)
      console.error "[justdo-analytics] JustdoAnalytics MYSQL Server isn't configured (Missing: user, password, db_name)"

      fail()

    # Gets 2 callbacks as parameter:
    # done() should be called upon sucessful connection to the storage driver
    # fail() should be called if connection couldn't be established.

    # Keep for testing of pre-driver ready logs
    #
    # Meteor.setTimeout ->
    #   console.log "HERE"
    #   done()
    # , 20000

    db_config =
      host: host
      port: port
      user: user
      password: password

    # There's no meaning for calling done more than once,
    # but still, we want to avoid it .
    doneOnce = _.once done

    # con = null - con scope is in the parent context
    connectAndHandleDisconnect = ->
      # https://stackoverflow.com/questions/20210522/nodejs-mysql-error-connection-lost-the-server-closed-the-connection
      con = mysql.createConnection(db_config)
      try_again_delay_ms = 2000

      # Recreate the connection, since the old one cannot be reused.
      console.log "[justdo-analytics] [#{JustdoHelpers.getClientType(env)}] Connecting JustdoAnalytics MYSQL"
      con.connect (err) ->
        # The server is either down
        # or restarting (takes a while sometimes).
        # We introduce a delay before attempting to reconnect,
        # to avoid a hot loop, and to allow our node script to
        if err
          console.error "[justdo-analytics] [#{JustdoHelpers.getClientType(env)}] JustdoAnalytics MYSQL Server failed to init, trying again in #{try_again_delay_ms}ms!", err

          # We don't call fail as there's a chance that we'll be able to connect
          # in the next attempt

          setTimeout connectAndHandleDisconnect, try_again_delay_ms
        else
          if JustdoHelpers.getClientType(env) != "web-app"
            console.log "[justdo-analytics] [#{JustdoHelpers.getClientType(env)}] JustdoAnalytics MYSQL Connection Initiated (1)"

            con.query "USE #{db_name};", ->
              doneOnce()

              return

            return
          else
            # To avoid the landing app and web app stepping on each other's toes,
            # we make sure the DB structures are initiated only in the web-app. 
            async.each getInitDBQueries(db_name),
              (query, cb) ->
                con.query query, cb
              , (err) ->
                if (err)
                  console.error "[justdo-analytics] [#{JustdoHelpers.getClientType(env)}] JustdoAnalytics MYSQL DB Init failed, trying again in #{try_again_delay_ms}ms!", err

                  setTimeout connectAndHandleDisconnect, try_again_delay_ms

                  return

                console.log "[justdo-analytics] [#{JustdoHelpers.getClientType(env)}] JustdoAnalytics MYSQL Connection Initiated (2)"

                doneOnce()

                return

        return

      con.on "error", (err) ->
        console.error "[justdo-analytics] [#{JustdoHelpers.getClientType(env)}] JustdoAnalytics MYSQL DB error.", err

        if err.code == "PROTOCOL_CONNECTION_LOST"
          # Connection to the MySQL server is usually
          # lost due to either server restart, or a
          # connnection idle timeout (the wait_timeout
          # server variable configures this)
          connectAndHandleDisconnect()
        else
          throw err
        return
      return

    connectAndHandleDisconnect()

    return @

  writeState: (state) ->
    # We take care of queueing for you write requests until init calls done(),
    # don't worry about that aspect, assume writeState is called only after
    # init completed.

    query = """
      INSERT INTO `JDAnalyticsStates`
      (`ASID`,
      `SSID`,
      `UID`,
      `CID`,
      `DID`,
      `SID`,
      `IP`,
      `CType`,
      `acceptLanguage`,
      `userAgent`,
      `appVersion`,
      `serverBuild`,
      `baseURL`)
      VALUES
      (#{con.escape(state.ASID)},
      #{con.escape(state.SSID)},
      #{con.escape(state.UID)},
      #{con.escape(state.CID)},
      #{con.escape(state.DID)},
      #{con.escape(state.SID)},
      #{con.escape(state.ip)},
      #{con.escape(state.CType)},
      #{con.escape(state.acceptLanguage)},
      #{con.escape(state.userAgent)},
      #{con.escape(state.appVersion)},
      #{con.escape(state.serverBuild)},
      #{con.escape(state.baseURL)});
    """

    # console.log state
    # console.log query

    con.query query, (err) ->
      if err?
        console.error "[justdo-analytics] [#{JustdoHelpers.getClientType(env)}] Attempt to write state failed. State: ", state, err

      return

    return

  writeLog: (log, analytics_state) ->
    # We take care of queueing for you write requests until init calls done(),
    # don't worry about that aspect, assume writeState is called only after
    # init completed.

    if not _.isEmpty(log.cls)
      cls = "|#{log.cls.join("|")}|"
    else
      cls = ""

    query = """
      INSERT INTO `JDAnalyticsData`
      (`ASID`,
      `PID`,
      `cls`,
      `cat`,
      `act`,
      `val`)
      VALUES
      (#{con.escape(log.ASID)},
      #{con.escape(log.pid)},
      #{con.escape(cls)},
      #{con.escape(log.cat)},
      #{con.escape(log.act)},
      #{con.escape(log.val)});
    """

    # console.log log
    # console.log query

    con.query query, (err) ->
      if err?
        console.error "[justdo-analytics] [#{JustdoHelpers.getClientType(env)}] Attempt to write log failed. Log: ", log, err

        return

      # console.log "[justdo-analytics] [#{JustdoHelpers.getClientType(env)}] Log written", log

      return

    return

  logServerSession: (server_session) ->
    {SSID, devops_password_encrypted, environment} = server_session

    check SSID, String
    check devops_password_encrypted, Match.Maybe(String)
    check environment, Object

    environment_json = EJSON.stringify(environment)

    query = """
      INSERT INTO `JDServersSessions`
      (`SSID`,
      `devopsPasswordEncrypted`,
      `environmentJson`
      )
      VALUES
      (#{con.escape(SSID)},
      #{con.escape(devops_password_encrypted)},
      #{con.escape(environment_json)}
      );
    """

    con.query query, (err) ->
      if err?
        console.error "[justdo-analytics] Attempt to write server session failed. Log: ", server_session, err

        return
      return

    return

  logServerRecord: (log) ->
    {SSID, UID, CID, cat, act, val} = log

    check SSID, String
    check UID, Match.Maybe(String)
    check CID, Match.Maybe(String)
    check cat, String
    check act, String
    check val, Match.Maybe(String)

    query = """
      INSERT INTO `JDServersRecords`
      (`SSID`,
      `UID`,
      `CID`,
      `cat`,
      `act`,
      `val`
      )
      VALUES
      (#{con.escape(SSID)},
      #{con.escape(UID)},
      #{con.escape(CID)},
      #{con.escape(cat)},
      #{con.escape(act)},
      #{con.escape(val)}
      );
    """

    con.query query, (err) ->
      if err?
        console.error "[justdo-analytics] Attempt to write server record failed, Log: ", log, err

        return
      return

    return




JustdoAnalytics.StorageDrivers.mysql = MysqlDriver