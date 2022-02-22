semver_regex_pattern = "v?\\d+\\.\\d+\\.\\d+"

_.extend JustdoSystemRecords,
  semver_regex_pattern: semver_regex_pattern
  semver_regex: new RegExp(semver_regex_pattern, "g")
  semver_regex_strict: new RegExp("^#{semver_regex_pattern}$")