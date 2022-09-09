Package.describe({
  name: "justdoinc:justdo-system-updates",
  version: "1.0.0",
  summary: "Justdo System Updates",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-system-updates"
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
  //     'colors': '1.1.x'
  //   }, 'justdoinc:justdo-analytics')
  // api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("justdoinc:justdo-login-state@1.0.0", client)

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

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static-api.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/init.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);

  api.addFiles("lib/client/user-conf/system-updates-user-conf.sass", client);
  api.addFiles("lib/client/user-conf/system-updates-user-conf.html", client);
  api.addFiles("lib/client/user-conf/system-updates-user-conf.coffee", client);

  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // // Note: app-integration need to load last, so immediateInit procedures in
  // // the server will have the access to the apis loaded after the init.coffee
  // // file.

  // api.addFiles("lib/core-system-updates/new-priority-style/new-priority-style.sass", client);
  // api.addFiles("lib/core-system-updates/new-priority-style/new-priority-style.html", client);
  // api.addFiles("lib/core-system-updates/new-priority-style/new-priority-style.coffee", both);

  // // v3_54_0
  // api.addFiles("lib/core-system-updates/v3-54-0/v3-54-0.sass", client);
  // api.addFiles("lib/core-system-updates/v3-54-0/v3-54-0.html", client);
  // api.addFiles("lib/core-system-updates/v3-54-0/v3-54-0.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-54-0/media/media_1.png", client);
  // api.addAssets("lib/core-system-updates/v3-54-0/media/media_3.gif", client);
  // api.addAssets("lib/core-system-updates/v3-54-0/media/media_4.gif", client);

  // // v3_64_0
  // api.addFiles("lib/core-system-updates/v3-64-0/v3-64-0.sass", client);
  // api.addFiles("lib/core-system-updates/v3-64-0/v3-64-0.html", client);
  // api.addFiles("lib/core-system-updates/v3-64-0/v3-64-0.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-64-0/media/media_1.png", client);
  // api.addAssets("lib/core-system-updates/v3-64-0/media/media_2.png", client);
  // api.addAssets("lib/core-system-updates/v3-64-0/media/media_3.png", client);

  // // v3_74_2
  // api.addFiles("lib/core-system-updates/v3-74-2/v3-74-2.sass", client);
  // api.addFiles("lib/core-system-updates/v3-74-2/v3-74-2.html", client);
  // api.addFiles("lib/core-system-updates/v3-74-2/v3-74-2.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-74-2/media/media_1.png", client);
  // api.addAssets("lib/core-system-updates/v3-74-2/media/media_2.gif", client);

  // // v3_85_0
  // api.addFiles("lib/core-system-updates/v3-85-0/v3-85-0.sass", client);
  // api.addFiles("lib/core-system-updates/v3-85-0/v3-85-0.html", client);
  // api.addFiles("lib/core-system-updates/v3-85-0/v3-85-0.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-85-0/media/media_1.gif", client);
  // api.addAssets("lib/core-system-updates/v3-85-0/media/media_2.gif", client);

  // // v3_91_0
  // api.addFiles("lib/core-system-updates/v3-91-0/v3-91-0.sass", client);
  // api.addFiles("lib/core-system-updates/v3-91-0/v3-91-0.html", client);
  // api.addFiles("lib/core-system-updates/v3-91-0/v3-91-0.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-91-0/media/media_freeze.gif", client);
  // api.addAssets("lib/core-system-updates/v3-91-0/media/media_lags.gif", client);

  // // v3_101_0
  // api.addFiles("lib/core-system-updates/v3-101-0/v3-101-0.sass", client);
  // api.addFiles("lib/core-system-updates/v3-101-0/v3-101-0.html", client);
  // api.addFiles("lib/core-system-updates/v3-101-0/v3-101-0.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-101-0/media/media_1.gif", client);
  // api.addAssets("lib/core-system-updates/v3-101-0/media/media_2.png", client);

  // // v3_104
  // api.addFiles("lib/core-system-updates/v3-104/v3-104.sass", client);
  // api.addFiles("lib/core-system-updates/v3-104/v3-104.html", client);
  // api.addFiles("lib/core-system-updates/v3-104/v3-104.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-104/media/image1.gif", client);
  // api.addAssets("lib/core-system-updates/v3-104/media/image2.png", client);
  // api.addAssets("lib/core-system-updates/v3-104/media/image3.png", client);

  // // v3_106_0
  // api.addFiles("lib/core-system-updates/v3-106-0/v3-106-0.sass", client);
  // api.addFiles("lib/core-system-updates/v3-106-0/v3-106-0.html", client);
  // api.addFiles("lib/core-system-updates/v3-106-0/v3-106-0.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-106-0/media/media_1.gif", client);
  // api.addAssets("lib/core-system-updates/v3-106-0/media/media_2.png", client);

  // // v3_110
  // api.addFiles("lib/core-system-updates/v3-110/v3-110.sass", client);
  // api.addFiles("lib/core-system-updates/v3-110/v3-110.html", client);
  // api.addFiles("lib/core-system-updates/v3-110/v3-110.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-110/media/image_1.jpeg", client);
  // api.addAssets("lib/core-system-updates/v3-110/media/image_2.gif", client);

  // // v3_113
  // api.addFiles("lib/core-system-updates/v3-113/v3-113.sass", client);
  // api.addFiles("lib/core-system-updates/v3-113/v3-113.html", client);
  // api.addFiles("lib/core-system-updates/v3-113/v3-113.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-113/media/image1.png", client);

  // // v3_118_2
  // api.addFiles("lib/core-system-updates/v3-118-2/v3-118-2.sass", client);
  // api.addFiles("lib/core-system-updates/v3-118-2/v3-118-2.html", client);
  // api.addFiles("lib/core-system-updates/v3-118-2/v3-118-2.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-118-2/media/image1.gif", client);

  // // v3_120_0
  // api.addFiles("lib/core-system-updates/v3-120-0/v3-120-0.sass", client);
  // api.addFiles("lib/core-system-updates/v3-120-0/v3-120-0.html", client);
  // api.addFiles("lib/core-system-updates/v3-120-0/v3-120-0.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-120-0/media/image1.gif", client);
  // api.addAssets("lib/core-system-updates/v3-120-0/media/image2.gif", client);

  // // v3_122_0
  // api.addFiles("lib/core-system-updates/v3-122-0/v3-122-0.sass", client);
  // api.addFiles("lib/core-system-updates/v3-122-0/v3-122-0.html", client);
  // api.addFiles("lib/core-system-updates/v3-122-0/v3-122-0.coffee", both);
  // api.addAssets("lib/core-system-updates/v3-122-0/media/image1.gif", client);
  // api.addAssets("lib/core-system-updates/v3-122-0/media/image2.gif", client);

  // v3_126_x
  api.addFiles("lib/core-system-updates/v3-126-x/v3-126-x.sass", client);
  api.addFiles("lib/core-system-updates/v3-126-x/v3-126-x.html", client);
  api.addFiles("lib/core-system-updates/v3-126-x/v3-126-x.coffee", both);
  api.addAssets("lib/core-system-updates/v3-126-x/media/image1.gif", client);

  // v3_126_13
  api.addFiles("lib/core-system-updates/v3-126-13/v3-126-13.html", client);
  api.addFiles("lib/core-system-updates/v3-126-13/v3-126-13.coffee", both);
  api.addAssets("lib/core-system-updates/v3-126-13/media/image1.gif", client);
  api.addAssets("lib/core-system-updates/v3-126-13/media/image2.png", client);

  // v3_128_0
  api.addFiles("lib/core-system-updates/v3-128-0/v3-128-0.sass", client);
  api.addFiles("lib/core-system-updates/v3-128-0/v3-128-0.html", client);
  api.addFiles("lib/core-system-updates/v3-128-0/v3-128-0.coffee", both);
  api.addAssets("lib/core-system-updates/v3-128-0/media/image1.gif", client);

  // v3_130_x
  api.addFiles("lib/core-system-updates/v3-130-x/v3-130-x.sass", client);
  api.addFiles("lib/core-system-updates/v3-130-x/v3-130-x.html", client);
  api.addFiles("lib/core-system-updates/v3-130-x/v3-130-x.coffee", both);
  api.addAssets("lib/core-system-updates/v3-130-x/media/image1.jpg", client);
  api.addAssets("lib/core-system-updates/v3-130-x/media/image2.gif", client);

  api.export("JustdoSystemUpdates", both);
});
