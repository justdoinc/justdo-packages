Package.describe({
  name: "justdoinc:justdo-jira-integration",
  version: "1.0.0",
  summary: "",
});

client = "client"
server = "server"
both = [client, server]

Npm.depends({
  'jira.js': '2.15.3',
  'oauth-1.0a': '2.2.6'//,
  // 'turndown': '7.1.1'
});

Package.onUse(function (api) {
  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("mongo", both);
  api.use("http", both);

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
  //   }, 'justdoinc:justdo-jira-integration')
  // api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);
  api.use("iron:router@1.1.2", both);
  api.use("ejson", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);
  api.use("justdoinc:justdo-system-records@1.0.0", both);
  api.use("justdoinc:justdo-db-migrations@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/static.coffee", server);
  api.addFiles("lib/server/field-mappers.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);
  api.addFiles("lib/server/grid-control-middlewares.coffee", server);
  api.addFiles("lib/server/webhook-event-handlers.coffee", server);

  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  api.addFiles("lib/client/project-conf/project-conf.sass", client);
  api.addFiles("lib/client/project-conf/project-conf.html", client);
  api.addFiles("lib/client/project-conf/project-conf.coffee", client);
  api.addFiles("lib/client/project-conf/project-settings/project-settings.sass", client);
  api.addFiles("lib/client/project-conf/project-settings/project-settings.html", client);
  api.addFiles("lib/client/project-conf/project-settings/project-settings.coffee", client);

  api.addFiles("lib/client/plugin-page/plugin-page.sass", client);
  api.addFiles("lib/client/plugin-page/plugin-page.html", client);
  api.addFiles("lib/client/plugin-page/plugin-page.coffee", client);

  api.addFiles("lib/client/task-pane-section/task-pane-section-registrar.coffee", client);

  api.addFiles("lib/client/task-pane-section/task-pane-section.sass", client);
  api.addFiles("lib/client/task-pane-section/task-pane-section.html", client);
  api.addFiles("lib/client/task-pane-section/task-pane-section.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);

  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file.

  api.export("JustdoJiraIntegration", both);
});
