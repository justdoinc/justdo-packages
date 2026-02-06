TestManifest?.register "justdo-core-helpers",
  configurations: [
    {
      id: "default"
      env: {}
      mocha_tests: [
        "JustdoCoreHelpers - SameTickCache"
      ]
      fixtures: []
      primary: true
    }
  ]
  apps: ["web-app"]
