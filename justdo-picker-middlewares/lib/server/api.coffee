import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions({
  'body-parser': '1.18.3'
}, 'justdoinc:justdo-analytics')

bodyParser = require('body-parser')

_.extend JustdoPickerMiddlewares.prototype,
  _immediateInit: ->
    @setupMiddlewares()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  setupMiddlewares: ->
    limit = "10mb"

    Picker.middleware bodyParser.urlencoded({limit: limit, extended: false})

    return