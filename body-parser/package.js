Package.describe({
    name: "justdoinc:body-parser",
    version: "0.0.1",
    summary: "exposes npm's bodyParser"
});

Npm.depends({"body-parser": "1.20.3"});

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.2");
  api.addFiles("server/init.js", "server");
  api.export("bodyParser");
});
