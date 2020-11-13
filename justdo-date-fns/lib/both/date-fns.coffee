import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions({
  "date-fns": "1.30.x"
}, "justdoinc:justdo-date-fns")

date_fns = require "date-fns"

JustdoDateFns = {
  "date-fns": date_fns
}
