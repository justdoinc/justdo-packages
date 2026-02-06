TestManifest?.register "justdo-formula-fields",
  configurations: [
    {
      id: "default"
      env: {}
      mocha_tests: [
        "JustdoFormulaFields - Static Utilities"
        "JustdoFormulaFields - API"
        "JustdoFormulaFields - Dependency Tracking"
        "JustdoFormulaFields - Formatter Caching"
      ]
      fixtures: []
      primary: true
    }
  ]
  apps: ["web-app"]
