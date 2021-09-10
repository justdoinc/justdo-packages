Package.describe({
  name: "justdoinc:justdo-helpers",
  version: "1.0.0",
  summary: "Helpers offering support to the JustDo app",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-helpers"
});

Npm.depends({"cookie": "0.4.1"})

client = "client"
server = "server"
both = [client, server]
Package.onUse(function (api) {
  api.use("underscore", both);
  api.use("coffeescript", both);
  api.use("tracker", both);
  api.use("check", both);
  api.use("reactive-var", client);
  api.use("mongo", both);
  api.use("minimongo", both);
  api.use("blaze", client, {weak: true});
  api.use("templating", client, {weak: true});
  api.use("ecmascript", both);
  api.use("random", both);

  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.1.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("meteorspark:app@0.3.0", both);
  api.use("meteorspark:json-sortify@0.1.0", both);
  api.use("iron:router@1.0.9", both, {weak: true});
  api.use("vazco:universe-html-purifier@1.2.3", both);
  api.use("peerlibrary:async@1.5.2_1", both);
  api.use("momentjs:moment",both);

  api.use("aldeed:simple-schema@1.5.3", both);

  api.use('fourseven:scss@3.2.0', client);

  api.use("justdoinc:justdo-date-fns@1.0.0", both);

  api.add_files("lib/init.coffee", both);
  api.add_files("lib/both/lorem-ipsum.coffee", both);
  api.add_files("lib/both/json.coffee", both);
  api.add_files("lib/both/poc-permitted-domains.coffee", both);
  api.add_files("lib/both/same-tick-cache.coffee", both);
  api.add_files("lib/both/same-tick-stats.coffee", both);
  api.add_files("lib/both/strings.coffee", both);
  api.add_files("lib/both/date.coffee", both);
  api.add_files("lib/both/modules.coffee", both);
  api.add_files("lib/both/platform-details.coffee", both);
  api.add_files("lib/both/event-emitter-helpers.coffee", both);
  api.add_files("lib/both/fiber-var.coffee", both);
  api.add_files("lib/both/constructors_tools.coffee", both);
  api.add_files("lib/both/prereq.coffee", both);
  api.add_files("lib/both/profiling.coffee", both);
  api.add_files("lib/both/regexp.coffee", both);
  api.add_files("lib/both/simple-schema.coffee", both);
  api.add_files("lib/both/functions.coffee", both);
  api.add_files("lib/both/users.coffee", both);
  api.add_files("lib/both/tasks.coffee", both);
  api.add_files("lib/both/xss.coffee", both);
  api.add_files("lib/both/control-flows.coffee", both);
  api.add_files("lib/both/mongo.coffee", both);
  api.add_files("lib/both/objects.coffee", both);
  api.add_files("lib/both/debug-tracker.coffee", both);
  api.add_files("lib/both/computed-reactive-var.coffee", both);
  api.add_files("lib/both/flush-manager.coffee", both);
  api.add_files("lib/both/client-type.coffee", both);
  api.add_files("lib/both/collections-hooks.coffee", both);
  api.add_files("lib/both/common-regexps.coffee", both);
  api.add_files("lib/both/common-errors-types.coffee", both);
  api.add_files("lib/both/get-app-version.coffee", both);
  api.add_files("lib/both/handlers-registrar.coffee", both);
  api.add_files("lib/both/ddp-helpers.coffee", both);
  api.add_files("lib/both/reactive-items-list.coffee", both);
  api.add_files("lib/both/middlewares.coffee", both);
  api.add_files("lib/both/state-machine.coffee", both);

  api.add_files("lib/client/users.coffee", client);
  api.add_files("lib/client/minimongo.coffee", client);
  api.add_files("lib/client/blaze-extensions.coffee", client);
  api.add_files("lib/client/blaze.coffee", client);
  api.add_files("lib/client/bound-element.sass", client);
  api.add_files("lib/client/bound-element.coffee", client);
  api.add_files("lib/client/contrast.coffee", client);
  api.add_files("lib/client/css-block.coffee", client);
  api.add_files("lib/client/date-time.coffee", client);
  api.add_files("lib/client/dom-ghost-debugger.sass", client);
  api.add_files("lib/client/dom-ghost-debugger.coffee", client);
  api.add_files("lib/client/template-dropdown.coffee", client);
  api.add_files("lib/client/iron-router.coffee", client);
  api.add_files("lib/client/jquery.coffee", client);
  api.add_files("lib/client/tab-visibility.coffee", client);
  api.add_files("lib/client/tasks-generator.coffee", client);
  api.add_files("lib/client/query-string.js", client);
  api.add_files("lib/client/reactivity-utils.coffee", client);
  api.add_files("lib/client/xss.coffee", client);
  api.add_files("lib/client/users-generator.coffee", client);
  api.add_files("lib/client/mods/justdo-direct-ownership-assignment.coffee", client);

  api.add_files("lib/server/http-auth.coffee", server);
  api.add_files("lib/server/app-domains.coffee", server);
  api.add_files("lib/server/bson-to-json.coffee", server);
  api.add_files("lib/server/cookie.coffee", server);
  api.add_files("lib/server/ddp.coffee", server);
  api.add_files("lib/server/fibers.coffee", server);
  api.add_files("lib/server/ddp-socket.coffee", server);
  api.add_files("lib/server/network.coffee", server);
  api.add_files("lib/server/cpu.coffee", server);
  api.add_files("lib/server/users-generator.coffee", server);
  api.add_files("lib/server/users.coffee", server);
  api.add_files("lib/server/tasks-generator.coffee", server);
  api.add_files("lib/server/url.coffee", server);

  api.export("JustdoHelpers", both);
});
