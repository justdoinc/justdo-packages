Package.describe({
  name: "justdoinc:justdo-webapp-boot",
  version: "1.0.0",
  summary: "This package contains extensions to the APP var that need to be loaded very early in JustDo code so packages can safely rely on them"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("ecmascript", both);

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("mongo", both);

  api.use("reactive-var", client);
  api.use("tracker", client);

  api.use("tmeasday:check-npm-versions@0.3.1", both);

  api.use('meteorspark:logger@0.3.0', both);
  api.use("meteorspark:app@0.3.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("justdoinc:justdo-accounts@1.0.0", both);

  api.addFiles("lib/both/app-logger.coffee", both);
  api.addFiles("lib/both/app-promises.coffee", both);
  api.addFiles("lib/both/app-logger-configuration.coffee", both);
  api.addFiles("lib/both/app-accounts.coffee", both);

  api.addFiles("lib/client/ddp-monitor.coffee", client);
  api.addFiles("lib/server/ddp-monitor.coffee", server);

  api.addFiles("lib/client/app-pseudo-collections.coffee", client);
});
