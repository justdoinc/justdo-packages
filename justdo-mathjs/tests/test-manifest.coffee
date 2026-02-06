TestManifest?.register "justdo-mathjs",
  configurations: [
    {
      id: "default"
      env: {}
      mocha_tests: ["JustdoMathjs - parseSingleRestrictedRationalExpression"]
      fixtures: []
      primary: true
    }
  ]
  apps: ["web-app"]
