Package.describe({
  name: "justdoinc:justdo-accounts",
  version: "1.0.0",
  summary: "Takes care of accounts creation/registration/enrollment/password-reset/verification",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-accounts"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use('npm-bcrypt@0.9.2', server);

  api.use("coffeescript", both);
  api.use("mongo", both);
  api.use("check", both);
  api.use("underscore", both);
  api.use("accounts-base@1.2.14", both);
  api.use("accounts-password@1.3.3", both);
  api.use("tracker", client);
  api.use("http", both);

  api.use("sha", both);
  api.use("srp", both);

  api.use("justdoinc:justdo-aws-base", server, {unordered: true});

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);
  api.use('justdoinc:justdo-legal-docs-versions@1.0.0', both);
  api.use('justdoinc:justdo-login-state@1.0.0', client);

  api.use('aldeed:simple-schema@1.3.1', both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use('risul:moment-timezone@0.5.0_5', client)

  api.use("matb33:collection-hooks@0.8.4", both);

  api.add_files("lib/both/init.coffee", both);
  api.add_files('lib/both/errors-types.coffee', both);
  api.add_files('lib/both/meteor-accounts-configuration.coffee', both);
  api.add_files('lib/both/schemas.coffee', both);
  api.add_files('lib/both/api.coffee', both);

  api.add_files("lib/server/init.coffee", server);
  api.add_files("lib/server/api.coffee", server);
  api.add_files("lib/server/collection-hooks.coffee", server);
  api.add_files("lib/server/allow-deny.coffee", server);
  api.add_files("lib/server/methods.coffee", server);
  api.add_files("lib/server/publications.coffee", server);

  api.add_files("lib/client/init.coffee", client);
  api.add_files("lib/client/api.coffee", client);
  api.add_files("lib/client/collection-hooks.coffee", client);
  api.add_files("lib/client/methods.coffee", client);

  api.use("meteorspark:app@0.3.0", both);

  api.export("JustdoAccounts", both);
});
