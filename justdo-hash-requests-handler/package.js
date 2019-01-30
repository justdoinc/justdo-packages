Package.describe({
  name: "justdoinc:hash-requests-handler",
  version: "1.0.0",
  summary: "A for defining a handlers for actions requests received by the hash (#) part of the url",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/hash-requests-handler"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);

  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/errors-types.coffee", client);
  api.addFiles("lib/client/api.coffee", client);

  api.export("HashRequestsHandler", both);
});
