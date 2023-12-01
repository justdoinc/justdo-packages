Package.describe({
  name: "justdoinc:justdo-login-state",
  version: "1.0.0",
  summary: "Takes care of determining user login state, and verification/reset password/enrollment procedures",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-login-state"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("accounts-base", both);
  api.use("accounts-password", both);
  api.use("reactive-var", client);
  api.use("tracker", client);
  api.use("templating", both);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);
  api.use('justdoinc:body-parser@0.0.1', server);
  
  api.use('staringatlights:inject-data@2.3.0', both);
  api.use('meteorhacks:picker@1.0.3', both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles('lib/both/errors-types.coffee', both);

  api.addFiles("lib/server/init.coffee", server);
  api.addFiles("lib/server/data-injections.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);
  api.addFiles("lib/client/templates-helpers.coffee", client);

  api.export("JustdoLoginState", both);
});
