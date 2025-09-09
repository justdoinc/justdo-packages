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

  api.use("astrocoders:handlebars-server@1.0.3", server);

  api.use("justdoinc:justdo-core-helpers@1.0.0", both);

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

  api.addFiles("lib/init.coffee", both);
  api.addFiles("lib/both/cdn.coffee", both);
  api.addFiles("lib/both/client-only-fields.coffee", both);
  api.addFiles("lib/both/lorem-ipsum.coffee", both);
  api.addFiles("lib/both/json.coffee", both);
  api.addFiles("lib/both/poc-permitted-domains.coffee", both);
  api.addFiles("lib/both/pointed-limited-stack.coffee", both);
  api.addFiles("lib/both/same-tick-cache.coffee", both);
  api.addFiles("lib/both/same-tick-stats.coffee", both);
  api.addFiles("lib/both/strings.coffee", both);
  api.addFiles("lib/both/date.coffee", both);
  api.addFiles("lib/both/modules.coffee", both);
  api.addFiles("lib/both/platform-details.coffee", both);
  api.addFiles("lib/both/event-emitter-helpers.coffee", both);
  api.addFiles("lib/both/fiber-var.coffee", both);
  api.addFiles("lib/both/files.coffee", both);
  api.addFiles("lib/both/constructors_tools.coffee", both);
  api.addFiles("lib/both/prereq.coffee", both);
  api.addFiles("lib/both/profiling.coffee", both);
  api.addFiles("lib/both/regexp.coffee", both);
  api.addFiles("lib/both/simple-schema.coffee", both);
  api.addFiles("lib/both/functions.coffee", both);
  api.addFiles("lib/both/url.coffee", both);
  api.addFiles("lib/both/users.coffee", both);
  api.addFiles("lib/both/tasks.coffee", both);
  api.addFiles("lib/both/xss.coffee", both);
  api.addFiles("lib/both/control-flows.coffee", both);
  api.addFiles("lib/both/mongo.coffee", both);
  api.addFiles("lib/both/numbers.coffee", both);
  api.addFiles("lib/both/objects.coffee", both);
  api.addFiles("lib/both/debug-tracker.coffee", both);
  api.addFiles("lib/both/env-helpers.coffee", both);
  api.addFiles("lib/both/computed-reactive-var.coffee", both);
  api.addFiles("lib/both/flush-manager.coffee", both);
  api.addFiles("lib/both/client-type.coffee", both);
  api.addFiles("lib/both/collections-hooks.coffee", both);
  api.addFiles("lib/both/common-regexps.coffee", both);
  api.addFiles("lib/both/common-errors-types.coffee", both);
  api.addFiles("lib/both/get-app-version.coffee", both);
  api.addFiles("lib/both/handlers-registrar.coffee", both);
  api.addFiles("lib/both/ddp-helpers.coffee", both);
  api.addFiles("lib/both/reactive-items-list.coffee", both);
  api.addFiles("lib/both/middlewares.coffee", both);
  api.addFiles("lib/both/state-machine.coffee", both);
  api.addFiles("lib/both/barriers.coffee", both);
  api.addFiles("lib/both/testcase.coffee", both);

  api.addFiles("lib/client/users.coffee", client);
  api.addFiles("lib/client/minimongo.coffee", client);
  api.addFiles("lib/client/blaze-extensions.coffee", client);
  api.addFiles("lib/client/blaze.coffee", client);
  api.addFiles("lib/client/bound-element.sass", client);
  api.addFiles("lib/client/bound-element.coffee", client);
  api.addFiles("lib/client/common-messages.coffee", client);
  api.addFiles("lib/client/contrast.coffee", client);
  api.addFiles("lib/client/css-block.coffee", client);
  api.addFiles("lib/client/date-time.coffee", client);
  api.addFiles("lib/client/dom-ghost-debugger.sass", client);
  api.addFiles("lib/client/dom-ghost-debugger.coffee", client);
  api.addFiles("lib/client/froala-editor.coffee", client);
  api.addFiles("lib/client/template-dropdown.coffee", client);
  api.addFiles("lib/client/iron-router.coffee", client);
  api.addFiles("lib/client/jquery.coffee", client);
  api.addFiles("lib/client/tab-visibility.coffee", client);
  api.addFiles("lib/client/tasks-generator.coffee", client);
  api.addFiles("lib/client/query-string.js", client);
  api.addFiles("lib/client/reactivity-utils.coffee", client);
  api.addFiles("lib/client/xss.coffee", client);
  api.addFiles("lib/client/users-generator.coffee", client);
  api.addFiles("lib/client/justdo-events-standardization.coffee", client);
  api.addFiles("lib/client/numbers.coffee", client);
  api.addFiles("lib/client/profiler.coffee", client);
  api.addFiles("lib/client/mods/justdo-direct-ownership-assignment.coffee", client);

  api.addFiles("lib/server/http-auth.coffee", server);
  api.addFiles("lib/server/app-domains.coffee", server);
  api.addFiles("lib/server/bson-to-json.coffee", server);
  api.addFiles("lib/server/cookie.coffee", server);
  api.addFiles("lib/server/ddp.coffee", server);
  api.addFiles("lib/server/fibers.coffee", server);
  api.addFiles("lib/server/ddp-socket.coffee", server);
  api.addFiles("lib/server/mongo.coffee", server);
  api.addFiles("lib/server/network.coffee", server);
  api.addFiles("lib/server/profiler.coffee", server);
  api.addFiles("lib/server/cpu.coffee", server);
  api.addFiles("lib/server/users-generator.coffee", server);
  api.addFiles("lib/server/users.coffee", server);
  api.addFiles("lib/server/tasks-generator.coffee", server);
  api.addFiles("lib/server/xss.coffee", server);
  api.addFiles("lib/server/url.coffee", server);
  api.addFiles("lib/server/iron-router.coffee", server);

  api.export("JustdoHelpers", both);
});
