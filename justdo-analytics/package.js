Package.describe({
  name: "justdoinc:justdo-analytics",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-analytics"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("mongo", both);

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
  // Add to the peer dependencies checks to one of the JS files of your package,
  // Example:
  //
  //   import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"
  //
  //   checkNpmVersions({
  //     'color': '1.1.x'
  //   }, 'justdoinc:justdo-analytics')
  api.use("ecmascript", both);
  api.use("tmeasday:check-npm-versions@0.3.1", both);

  api.use("justdoinc:justdo-aws-base@1.0.0", server);

  // api.use("stevezhu:lodash@4.17.2", both);
  // api.use("templating", client);
  // api.use('fourseven:scss@3.2.0', client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);
  api.use('justdoinc:body-parser@0.0.1', server);
  api.use('peerlibrary:async@1.5.2_1', server);

  api.use('meteorhacks:inject-data@2.0.0', both);
  api.use('meteorhacks:picker@1.0.3', both);

  api.use('meteorspark:colors@1.1.2', server);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", both);
  api.use("ejson", both);
  api.use("check", both);
  api.use("tracker", client);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/logs-registrar.coffee", both);
  api.addFiles("lib/both/justdo-analytics-helpers.coffee", both);


  api.addFiles("lib/server/init-storage.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);
  api.addFiles("lib/server/data-injections.coffee", server);

  // Storages
  api.addFiles("lib/server/storage-drivers/storage-driver-prototype.coffee", server);
  api.addFiles("lib/server/storage-drivers/console-storage.coffee", server);
  api.addFiles("lib/server/storage-drivers/mysql-storage.coffee", server);

  api.addFiles("lib/client/api.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file.

  api.export("JustdoAnalytics", both);
});
