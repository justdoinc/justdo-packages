Package.describe({
  name: "justdoinc:justdo-db-migrations",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-db-migrations"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("mongo", both);
  api.use("check", both);
  
  // Uncomment if you want to use NPM peer dependencies using
  // checkNpmVersions.
  //
  // Introducing new NPM packages procedure:
  //
  // * Uncomment the lines below.
  // * Add your packages to the main web-app package.json dependencies section.
  // * Call $ meteor npm install
  // * Call $ meteor npm shrinkwrap
  //
  // Add to the peer dependencies checks to one of the JS/Coffee files of your package,
  // Example:
  //
  //   import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"
  //
  //   checkNpmVersions({
  //     'colors': '1.1.x'
  //   }, 'justdoinc:justdo-db-migrations')
  // api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("accounts-base", both);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("momentjs:moment", both);
  api.use("risul:moment-timezone@0.5.0_5", both);

  api.use("justdoinc:justdo-jobs-processor", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/core-batched-collection-updates-types.coffee", server);

  api.addFiles("lib/server/static.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);
  api.addFiles("lib/server/jobs.coffee", server);

  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 
  api.addFiles("lib/server/core-migrations/add-justdo-timezone.coffee", server);
  api.addFiles("lib/server/core-migrations/add-parents2.coffee", server);
  api.addFiles("lib/server/core-migrations/check-parents2.coffee", server);
  api.addFiles("lib/server/core-migrations/maintain-parents2.coffee", server);
  api.addFiles("lib/server/core-migrations/user-login-resume-expiry.coffee", server);
  api.addFiles("lib/server/core-migrations/clean-users-from-removed-tasks.coffee", server);
  api.addFiles("lib/server/core-migrations/remove-residual-temp-import-id.coffee", server);
  api.addFiles("lib/server/core-migrations/users-max-resume-tokens-trimmer.coffee", server);
  api.addFiles("lib/server/core-migrations/batched-collection-updates.coffee", server);

  api.export("JustdoDbMigrations", both);
});
