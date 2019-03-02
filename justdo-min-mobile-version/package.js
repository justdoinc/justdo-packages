Package.describe({
  name: "justdoinc:justdo-min-mobile-version",
  version: "1.0.0",
  summary: ""
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("coffeescript", both);
  api.use("underscore", both);

  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);
  
  api.add_files("lib/server/init.coffee", server);
});
