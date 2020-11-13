Package.describe({
  name: "justdoinc:justdo-date-fns",
  version: "1.0.0"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);

  api.use("ecmascript", both);
  api.use("tmeasday:check-npm-versions@0.3.1", both);

  api.addFiles("lib/both/date-fns.coffee", both);
  
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.export("JustdoDateFns", both);
});
