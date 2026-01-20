import {checkNpmVersions} from "meteor/tmeasday:check-npm-versions"

checkNpmVersions(
  "moment": "2.30.1",
  "moment-timezone": "0.6.0"
, "justdoinc:justdo-moment")

moment = require("moment")
require("moment-timezone")