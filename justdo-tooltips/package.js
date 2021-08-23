Package.describe({
  name: "justdoinc:justdo-tooltips",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-tooltips"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);

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
  //   }, 'justdoinc:justdo-tooltips')
  api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", client);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);
  api.use("iron:router@1.1.2", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", client);

  api.use("reactive-var", client);
  api.use("tracker", client);

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/static.coffee", client);
  api.addFiles("lib/client/errors-types.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/tooltips-registrar.coffee", client);

  api.addFiles("lib/client/justdo-tooltips.sass", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);
  api.addFiles("lib/client/app-integration.coffee", client);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file.

  api.addFiles("lib/client/core-tooltips/task-info/task-info.html", client);
  api.addFiles("lib/client/core-tooltips/task-info/task-info.sass", client);
  api.addFiles("lib/client/core-tooltips/task-info/task-info.coffee", client);

  api.addFiles("lib/client/core-tooltips/user-info/user-info.html", client);
  api.addFiles("lib/client/core-tooltips/user-info/user-info.sass", client);
  api.addFiles("lib/client/core-tooltips/user-info/user-info.coffee", client);

  api.addFiles("lib/client/core-tooltips/expand-grid/expand-grid.html", client);
  api.addFiles("lib/client/core-tooltips/expand-grid/expand-grid.sass", client);
  api.addFiles("lib/client/core-tooltips/expand-grid/expand-grid.coffee", client);

  api.export("JustdoTooltips", client);
});
