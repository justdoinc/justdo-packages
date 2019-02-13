Package.describe({
  name: "justdoinc:justdo-plugin-store",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-plugin-store"
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
  // Add to the peer dependencies checks to one of the JS/Coffee files of your package,
  // Example:
  //
  //   import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"
  //
  //   checkNpmVersions({
  //     'colors': '1.1.x'
  //   }, 'justdoinc:justdo-analytics')
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

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.addFiles("store-db/init.coffee", both);
  api.addFiles("store-db/categories.coffee", both);

  // justdo-delivery-plannner
  api.addFiles("store-db/plugins/delivery-planner/delivery-planner.coffee", both);
  api.addAssets("store-db/plugins/delivery-planner/media/delivery-planner-icon.png", client);
  api.addAssets("store-db/plugins/delivery-planner/media/delivery-planner-screenshot.png", client);

  // time-tracker 
  api.addFiles("store-db/plugins/justdo-time-tracker/justdo-time-tracker.coffee", both);
  api.addAssets("store-db/plugins/justdo-time-tracker/media/store-list-icon.png", client);

  // resource-management
  api.addFiles("store-db/plugins/resource-management/resource-management.coffee", both);
  api.addAssets("store-db/plugins/resource-management/media/store-list-icon.png", client);

  // roles-and-groups
  api.addFiles("store-db/plugins/roles-and-groups/roles-and-groups.coffee", both);
  api.addAssets("store-db/plugins/roles-and-groups/media/store-list-icon.jpg", client);

  // private-follow-up
  api.addFiles("store-db/plugins/private-follow-up/private-follow-up.coffee", both);
  api.addAssets("store-db/plugins/private-follow-up/media/store-list-icon.jpeg", client);

  // justdo-formulas
  api.addFiles("store-db/plugins/justdo-formulas/justdo-formulas.coffee", both);
  api.addAssets("store-db/plugins/justdo-formulas/media/store-list-icon.jpeg", client);

  // task-copy
  api.addFiles("store-db/plugins/task-copy/task-copy.coffee", both);
  api.addAssets("store-db/plugins/task-copy/media/store-list-icon.png", client);

  // rows-styling
  api.addFiles("store-db/plugins/rows-styling/rows-styling.coffee", both);
  api.addAssets("store-db/plugins/rows-styling/media/store-list-icon.png", client);

  // workload-planner
  api.addFiles("store-db/plugins/workload-planner/workload-planner.coffee", both);
  api.addAssets("store-db/plugins/workload-planner/media/store-list-icon.png", client);

  // maildo
  api.addFiles("store-db/plugins/maildo/maildo.coffee", both);
  api.addAssets("store-db/plugins/maildo/media/store-list-icon.png", client);

  // calculated-due-dates
  api.addFiles("store-db/plugins/calculated-due-dates/calculated-due-dates.coffee", both);
  api.addAssets("store-db/plugins/calculated-due-dates/media/store-list-icon.png", client);

  // meetings
  api.addFiles("store-db/plugins/meetings/meetings.coffee", both);
  api.addAssets("store-db/plugins/meetings/media/store-list-icon.png", client);

  // justdo-activity
  api.addFiles("store-db/plugins/justdo-activity/justdo-activity.coffee", both);
  api.addAssets("store-db/plugins/justdo-activity/media/store-list-icon.png", client);

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);

  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  api.addFiles("lib/ui/categories-list/categories-list.html", client);
  api.addFiles("lib/ui/categories-list/categories-list.coffee", client);
  api.addFiles("lib/ui/categories-list/categories-list.sass", client);

  api.addFiles("lib/ui/plugins-list/plugins-list.html", client);
  api.addFiles("lib/ui/plugins-list/plugins-list.coffee", client);
  api.addFiles("lib/ui/plugins-list/plugins-list.sass", client);

  api.addFiles("lib/ui/plugin-page/plugin-page.html", client);
  api.addFiles("lib/ui/plugin-page/plugin-page.coffee", client);
  api.addFiles("lib/ui/plugin-page/plugin-page.sass", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.export("JustdoPluginStore", both);
});
