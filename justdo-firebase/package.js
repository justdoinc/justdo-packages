Package.describe({
  name: "justdoinc:justdo-firebase",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-firebase"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", server);
  api.use("underscore", server);
  api.use("mongo", server);

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
  //     'colors': '1.1.x'
  //   }, 'justdoinc:justdo-analytics')
  api.use("ecmascript", server);
  api.use("tmeasday:check-npm-versions@0.3.1", server);

  api.use("aldeed:simple-schema@1.5.3", server);
  api.use('aldeed:collection2@2.3.2', server);
  api.use("raix:eventemitter@0.1.1", server);
  api.use("meteorspark:util@0.2.0", server);
  api.use("meteorspark:logger@0.3.0", server);
  api.use("justdoinc:justdo-helpers@1.0.0", server);

  api.use("justdoinc:justdo-analytics@1.0.0", server);

  api.use("matb33:collection-hooks@0.8.4", server);

  api.addFiles("lib/server/init.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/errors-types.coffee", server);
  api.addFiles("lib/server/schemas.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", server);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", server);
  api.addFiles("lib/server/app-integration.coffee", server);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.export("JustdoFirebase", server);
});
