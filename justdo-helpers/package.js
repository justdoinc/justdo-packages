Package.describe({
  name: "justdoinc:justdo-helpers",
  version: "1.0.0",
  summary: "Helpers offering support to the JustDo app",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-helpers"
});

client = "client"
server = "server"
both = [client, server]
Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("underscore", both);
  api.use("coffeescript", both);
  api.use("tracker", both);
  api.use("check", both);
  api.use("reactive-var", client);
  api.use("mongo", both);
  api.use("blaze", client, {weak: true});
  api.use("templating", client, {weak: true});
  api.use("ecmascript", both);

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

  api.add_files("lib/init.coffee", both);
  api.add_files("lib/both/json.coffee", both);
  api.add_files("lib/both/caching.coffee", both);
  api.add_files("lib/both/strings.coffee", both);
  api.add_files("lib/both/date.coffee", both);
  api.add_files("lib/both/modules.coffee", both);
  api.add_files("lib/both/platform-details.coffee", both);
  api.add_files("lib/both/poc-permitted-domains.coffee", both);
  api.add_files("lib/both/event-emitter-helpers.coffee", both);
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

  api.add_files("lib/client/blaze-extensions.coffee", client);
  api.add_files("lib/client/blaze.coffee", client);
  api.add_files("lib/client/bound-element.sass", client);
  api.add_files("lib/client/bound-element.coffee", client);
  api.add_files("lib/client/contrast.coffee", client);
  api.add_files("lib/client/date-time.coffee", client);
  api.add_files("lib/client/dom-ghost-debugger.sass", client);
  api.add_files("lib/client/dom-ghost-debugger.coffee", client);
  api.add_files("lib/client/template-dropdown.coffee", client);
  api.add_files("lib/client/iron-router.coffee", client);
  api.add_files("lib/client/jquery.coffee", client);
  api.add_files("lib/client/tab-visibility.coffee", client);
  api.add_files("lib/client/query-string.js", client);
  api.add_files("lib/client/reactive-items-list.coffee", client);
  api.add_files("lib/client/reactivity-utils.coffee", client);
  api.add_files("lib/client/xss.coffee", client);

  api.add_files("lib/server/app-domains.coffee", server);
  api.add_files("lib/server/ddp.coffee", server);
  api.add_files("lib/server/network.coffee", server);
  api.add_files("lib/server/cpu.coffee", server);

  api.export("JustdoHelpers", both);
});
