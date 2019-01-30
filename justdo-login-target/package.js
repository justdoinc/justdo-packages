Package.describe({
  name: "justdoinc:justdo-login-target",
  version: "1.0.0",
  summary: "Track the 'target' param from the hash tag's query string and generate urls that has it",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-login-target"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("base64", both);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);
  api.use('jparker:crypto-base64@0.1.0', both);

  api.add_files("lib/both/init.coffee", both);
  api.add_files('lib/both/errors-types.coffee', both);
  api.add_files("lib/both/api.coffee", both);

  api.add_files("lib/server/init.coffee", server);

  api.add_files("lib/client/init.coffee", client);

  api.export("JustdoLoginTarget", both);
});