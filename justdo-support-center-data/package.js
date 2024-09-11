Package.describe({
  name: "justdoinc:justdo-support-center-data",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-support-center-data"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
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
  //   }, 'justdoinc:justdo-support-center-data')
  // api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);

  api.addFiles("lib/both/news-category-registrar.coffee", both);

  api.addFiles("lib/client/templates/support-page-article/support-page-article.sass", client);
  api.addFiles("lib/client/templates/support-page-article/support-page-article.html", client);
  api.addFiles("lib/client/templates/support-page-article/support-page-article.coffee", client);

  // can-i-install-a-local-copy-of-justdo
  api.addFiles([
    "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/can-i-install-a-local-copy-of-justdo.sass",
    "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/can-i-install-a-local-copy-of-justdo.html"
  ], client);
  api.addFiles(["lib/both/support-articles/can-i-install-a-local-copy-of-justdo/can-i-install-a-local-copy-of-justdo.coffee"], both);

  // how-to-change-my-profile-picture-and-details
  api.addAssets([
    "lib/both/support-articles/how-to-change-my-profile-picture-and-details/assets/_how_to_change_a_profile_picture.gif"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-change-my-profile-picture-and-details/how-to-change-my-profile-picture-and-details.sass",
    "lib/both/support-articles/how-to-change-my-profile-picture-and-details/how-to-change-my-profile-picture-and-details.html"
  ], client);
  api.addFiles(["lib/both/support-articles/how-to-change-my-profile-picture-and-details/how-to-change-my-profile-picture-and-details.coffee"], both);

  // custom-fields
  api.addAssets([
    "lib/both/support-articles/custom-fields/assets/configure.jpg",
    "lib/both/support-articles/custom-fields/assets/smart_numbers_menu.jpg"
  ], client);
  api.addFiles([
    "lib/both/support-articles/custom-fields/custom-fields.sass",
    "lib/both/support-articles/custom-fields/custom-fields.html"
  ], client);
  api.addFiles(["lib/both/support-articles/custom-fields/custom-fields.coffee"], both);

  api.export("JustdoSupportCenterData", both);
});
