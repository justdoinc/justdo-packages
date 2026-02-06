TestManifest?.register "justdo-helpers",
  configurations: [
    {
      id: "default"
      env: {}
      mocha_tests: ["Barriers"]
      fixtures: []
      primary: true
    }
  ]
  apps: ["web-app"]
