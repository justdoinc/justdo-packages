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

  api.add_files("lib/init.coffee", both);

  api.add_files("lib/both/same-tick-cache.coffee", both);
  api.add_files("lib/both/same-tick-stats.coffee", both);
  api.add_files("lib/both/constructors_tools.coffee", both);
  api.add_files("lib/both/event-emitter-helpers.coffee", both);
  api.add_files("lib/both/flush-manager.coffee", both);
  api.add_files("lib/both/profiling.coffee", both);

  api.export("JustdoCoreHelpers", both);
});
