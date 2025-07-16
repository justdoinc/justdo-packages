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
  api.use("coffeescript", both);
  api.use("mongo", both);
  api.use("check", both);
  api.use("underscore", both);
  api.use("accounts-base", both);
  api.use("accounts-password", both);
  api.use("tracker", client);
  api.use("http", both);
  api.use("ecmascript", both);

  api.use("sha", both);
  api.use("srp", both);

  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("justdoinc:justdo-aws-base", server, {unordered: true});

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use("tap:i18n", both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);
  api.use('justdoinc:justdo-legal-docs-versions@1.0.0', both);
  api.use('justdoinc:justdo-login-state@1.0.0', client);

  api.use('aldeed:simple-schema@1.3.1', both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use('risul:moment-timezone@0.5.0_5', client)

  api.use("matb33:collection-hooks@0.8.4", both);

  api.addFiles("lib/both/simple-schema-extensions.coffee", both);
  api.addFiles("lib/both/init.coffee", both);
  api.addFiles('lib/both/errors-types.coffee', both);
  api.addFiles('lib/both/meteor-accounts-configuration.coffee', both);
  api.addFiles('lib/both/schemas.coffee', both);
  api.addFiles('lib/both/api.coffee', both);

  api.addFiles("lib/server/init.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/collection-hooks.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);
  api.addFiles("lib/server/db-migrations.coffee", server);

  api.addFiles("lib/client/edit-avatar-color-dialog/edit-avatar-color-dialog.html", client);
  api.addFiles("lib/client/edit-avatar-color-dialog/edit-avatar-color-dialog.sass", client);
  api.addFiles("lib/client/edit-avatar-color-dialog/edit-avatar-color-dialog.coffee", client);
  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/collection-hooks.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  this.addI18nFiles(api, "i18n/{}.i18n.json");

  api.use("meteorspark:app@0.3.0", both);

  api.export("JustdoAccounts", both);
});
