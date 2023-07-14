Package.describe({
  name: "justdoinc:justdo-news-data",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-news-data"
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
  //   }, 'justdoinc:justdo-news-data')
  // api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", client);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);
  api.use("iron:router@1.1.2", both);

  api.use("reactive-var", client);
  api.use("tracker", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.use("justdoinc:justdo-news@1.0.0", both);

  api.addFiles("lib/both/news-category-registrar.coffee", both);

  api.addFiles("lib/client/news-common.sass", client);
  api.addFiles("lib/client/templates/version-release/version-release.html", client);
  api.addFiles("lib/client/templates/version-release/version-release.coffee", client);

  // v3.133.x (Fake for package testing purpose, do not commit uncommentted!)
  // api.addAssets([
  //   "lib/both/news/v3-133/assets/2023_03_10_6.jpg"
  // ], client)
  // api.addFiles("lib/both/news/v3-133/v3-133.coffee", both);

  // v3.138.x
  api.addAssets([
    "lib/both/news/v3-138/assets/1.jpg",
    "lib/both/news/v3-138/assets/2.jpg",
    "lib/both/news/v3-138/assets/3.jpg"
  ], client);
  api.addFiles("lib/both/news/v3-138/v3-138.coffee", both);

  // v3.136.x
  api.addAssets([
    "lib/both/news/v3-136/assets/2023_03_10_1.jpg",
    "lib/both/news/v3-136/assets/2023_03_10_3.jpg",
    "lib/both/news/v3-136/assets/2023_03_10_5.jpg",
    "lib/both/news/v3-136/assets/2023_03_10_6.jpg",
  ], client);
  api.addFiles("lib/both/news/v3-136/v3-136.coffee", both);

  // v3.134
  api.addAssets([
    "lib/both/news/v3-134/assets/2023_04_10_1.png",
    "lib/both/news/v3-134/assets/2023_04_10_2.png",
    "lib/both/news/v3-134/assets/2023_04_10_3.png",
  ], client);
  api.addFiles("lib/both/news/v3-134/v3-134.coffee", both);

  api.export("JustdoNewsData", both);
});
