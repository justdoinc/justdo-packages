Package.describe({
  name: "justdoinc:justdo-core-helpers",
  version: "1.0.0",
  summary: "Core helpers are a subset of justdo-helpers that we can call from core packages such as minimongo without circular dependencies",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-helpers"
});

client = "client"
server = "server"
both = [client, server]
Package.onUse(function (api) {
  api.use("underscore", both);
  api.use("coffeescript", both);
  api.use("tracker", both);
  api.use("check", both);
  api.use("reactive-var", client);
  api.use("ecmascript", both);
  api.use("random", both);
  api.use("raix:eventemitter@0.1.1", both);

  api.use("meteorspark:util@0.1.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("meteorspark:app@0.3.0", both);

  api.addFiles("lib/init.coffee", both);

  api.addFiles("lib/both/url.coffee", both);
  api.addFiles("lib/both/cdn.coffee", both);
  api.addFiles("lib/both/same-tick-cache.coffee", both);
  api.addFiles("lib/both/same-tick-stats.coffee", both);
  api.addFiles("lib/both/constructors_tools.coffee", both);
  api.addFiles("lib/both/env-helpers.coffee", both);
  api.addFiles("lib/both/event-emitter-helpers.coffee", both);
  api.addFiles("lib/both/flush-manager.coffee", both);
  api.addFiles("lib/both/profiling.coffee", both);
  api.addFiles("lib/both/client-only-fields.coffee", both);
  api.addFiles("lib/both/simple-schema.coffee", both);
  
  api.addFiles("lib/server/url.coffee", server);

  api.export("JustdoCoreHelpers", both);
});
