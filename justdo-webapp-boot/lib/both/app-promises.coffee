import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions({
  'bluebird': '3.x.x'
}, 'justdoinc:justdo-webapp-boot')

Promise = require "bluebird"

env_async = new Promise (resolve, reject) ->
  if Meteor.isServer
    resolve(process.env)

    return

  APP.once "env-vars-ready", resolve

  return

APP.getEnv = (cb) ->
  env_async.then Meteor.bindEnvironment (env) -> cb(env)

  return

# On client we also provide a reactive var to get justdo environmental variables
if Meteor.isClient
  APP.env_rv = new ReactiveVar null

  APP.getEnv (env) ->
    APP.env_rv.set env

    return

justdo_labs_features_enabled_async = new Promise (resolve, reject) ->
  APP.getEnv (env) ->
    if env.JUSTDO_LABS_FEATURES_ENABLED is "true"
      resolve(true)
    else
      resolve(false)

    return

APP.isJustdoLabsFeaturesEnabled = (cb) ->
  justdo_labs_features_enabled_async.then Meteor.bindEnvironment (enabled) ->
    if enabled
      cb()

    # Quietly do nothing

    return

  return

# On client we also provide a reactive var to get justdo labs state
if Meteor.isClient
  APP.justdo_labs_features_enabled_rv = new ReactiveVar false

  APP.isJustdoLabsFeaturesEnabled ->
    APP.justdo_labs_features_enabled_rv.set true

    return

APP.isJustdoLabsFeaturesEnabled ->
  APP.logger.debug("JustDo labs features are enabled - begin their init")

  return

development_mode_enabled_async = new Promise (resolve, reject) ->
  APP.getEnv (env) ->
    if env.DEVELOPMENT_MODE is "true"
      resolve(true)
    else
      resolve(false)

    return

APP.isDevelopmentModeEnabled = (cb) ->
  development_mode_enabled_async.then Meteor.bindEnvironment (enabled) ->
    if enabled
      cb(true)
    else
      cb(false)

    return

  return

# On client we also provide a reactive var to get justdo labs state
if Meteor.isClient
  APP.development_mode_enabled_rv = new ReactiveVar false

  APP.isDevelopmentModeEnabled (res) ->
    APP.development_mode_enabled_rv.set res

    return

APP.isDevelopmentModeEnabled (res) ->
  if res
    APP.logger.debug("Development mode is enabled - apply development mode modifications")

  return

APP.init_lib_both_promise = new Promise (resolve, reject) ->
  APP.once("both-code-executed", resolve)

  return

APP.init_lib_all_promise = new Promise (resolve, reject) ->
  APP.once("env-specific-lib-code-executed", resolve)

  return

APP.executeAfterAppLibCode = (cb) ->
  # cb will get called after both the code under lib/020-both and /client
  # or /server (depending on current env) finish run.

  APP.init_lib_all_promise.then Meteor.bindEnvironment cb

APP.init_app_accounts_ready = new Promise (resolve, reject) ->
  APP.once("app-accounts-ready", resolve)

  return

APP.executeAfterAppAccountsReady = (cb) ->
  APP.init_app_accounts_ready.then Meteor.bindEnvironment cb

  return

# On client we also provide a reactive var to get justdo labs state
if Meteor.isClient
  #
  # Setup APP.justdo_app_lib_code_executed_rv
  #
  APP.justdo_app_lib_code_executed_rv = new ReactiveVar false

  APP.executeAfterAppLibCode ->
    APP.justdo_app_lib_code_executed_rv.set true

    return

  #
  # Setup APP.init_client_all_promise and its corresponding
  # reactive var APP.justdo_app_client_code_executed_rv
  #
  APP.justdo_app_client_code_executed_rv = new ReactiveVar false

  APP.init_client_all_promise = new Promise (resolve, reject) ->
    APP.once("client-code-executed", resolve)

    return

  APP.executeAfterAppClientCode = (cb) ->
    # cb will get called after both the code under lib/020-both and /client
    # or /server (depending on current env) finish run.

    APP.init_client_all_promise.then Meteor.bindEnvironment cb

  APP.executeAfterAppClientCode ->
    APP.justdo_app_client_code_executed_rv.set true

    return