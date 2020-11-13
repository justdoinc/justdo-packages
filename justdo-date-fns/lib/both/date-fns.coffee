import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions({
  "date-fns": "1.30.x"
}, "justdoinc:justdo-date-fns")

date_fns = require "./date-fns/src"

JustdoDateFns = {
  "date-fns": date_fns,
  getFormatFn: date_fns.format.getFormatFn
}
