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

  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/news-category-registrar.coffee", both);
  
  api.addFiles("lib/client/templates/global-template-helper.coffee", client);

  api.addFiles("lib/client/templates/support-page-article/support-page-article.sass", client);
  api.addFiles("lib/client/templates/support-page-article/support-page-article.html", client);
  api.addFiles("lib/client/templates/support-page-article/support-page-article.coffee", client);

  // can-i-install-a-local-copy-of-justdo
  api.addFiles([
    "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/can-i-install-a-local-copy-of-justdo.sass",
    "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/can-i-install-a-local-copy-of-justdo.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/can-i-install-a-local-copy-of-justdo.coffee"
  ], both);

  // how-to-use-the-slack-functionality
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-slack-functionality/how-to-use-the-slack-functionality.sass",
    "lib/both/support-articles/how-to-use-the-slack-functionality/how-to-use-the-slack-functionality.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-slack-functionality/how-to-use-the-slack-functionality.coffee"
  ], both);

  // how-to-use-buffer-tasks
  api.addFiles([
    "lib/both/support-articles/how-to-use-buffer-tasks/how-to-use-buffer-tasks.sass",
    "lib/both/support-articles/how-to-use-buffer-tasks/how-to-use-buffer-tasks.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-buffer-tasks/how-to-use-buffer-tasks.coffee"
  ], both);

  // how-to-create-custom-grid-views
  api.addFiles([
    "lib/both/support-articles/how-to-create-custom-grid-views/how-to-create-custom-grid-views.sass",
    "lib/both/support-articles/how-to-create-custom-grid-views/how-to-create-custom-grid-views.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-create-custom-grid-views/how-to-create-custom-grid-views.coffee"
  ], both);

  // how-to-use-gantt-dependencies
  api.addFiles([
    "lib/both/support-articles/how-to-use-gantt-dependencies/how-to-use-gantt-dependencies.sass",
    "lib/both/support-articles/how-to-use-gantt-dependencies/how-to-use-gantt-dependencies.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-gantt-dependencies/how-to-use-gantt-dependencies.coffee"
  ], both);

  // how-to-plan-and-track-working-hours
  api.addFiles([
    "lib/both/support-articles/how-to-plan-and-track-working-hours/how-to-plan-and-track-working-hours.sass",
    "lib/both/support-articles/how-to-plan-and-track-working-hours/how-to-plan-and-track-working-hours.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-plan-and-track-working-hours/how-to-plan-and-track-working-hours.coffee"
  ], both);

  // justdo-extensions
  api.addFiles([
    "lib/both/support-articles/justdo-extensions/justdo-extensions.sass",
    "lib/both/support-articles/justdo-extensions/justdo-extensions.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/justdo-extensions/justdo-extensions.coffee"
  ], both);

  // how-to-configure-workdays-and-holidays
  api.addFiles([
    "lib/both/support-articles/how-to-configure-workdays-and-holidays/how-to-configure-workdays-and-holidays.sass",
    "lib/both/support-articles/how-to-configure-workdays-and-holidays/how-to-configure-workdays-and-holidays.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-configure-workdays-and-holidays/how-to-configure-workdays-and-holidays.coffee"
  ], both);

  // how-to-use-the-gantt
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-gantt/how-to-use-the-gantt.sass",
    "lib/both/support-articles/how-to-use-the-gantt/how-to-use-the-gantt.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-gantt/how-to-use-the-gantt.coffee"
  ], both);

  // how-to-import-tasks-from-a-spreadsheet
  api.addFiles([
    "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/how-to-import-tasks-from-a-spreadsheet.sass",
    "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/how-to-import-tasks-from-a-spreadsheet.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/how-to-import-tasks-from-a-spreadsheet.coffee"
  ], both);

  // what-is-justdo-s-resource-management-extension
  api.addFiles([
    "lib/both/support-articles/what-is-justdo-s-resource-management-extension/what-is-justdo-s-resource-management-extension.sass",
    "lib/both/support-articles/what-is-justdo-s-resource-management-extension/what-is-justdo-s-resource-management-extension.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/what-is-justdo-s-resource-management-extension/what-is-justdo-s-resource-management-extension.coffee"
  ], both);

  // custom-fields
  api.addFiles([
    "lib/both/support-articles/custom-fields/custom-fields.sass",
    "lib/both/support-articles/custom-fields/custom-fields.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/custom-fields/custom-fields.coffee"
  ], both);

  // how-to-share-tasks-with-project-members
  api.addFiles([
    "lib/both/support-articles/how-to-share-tasks-with-project-members/how-to-share-tasks-with-project-members.sass",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/how-to-share-tasks-with-project-members.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-share-tasks-with-project-members/how-to-share-tasks-with-project-members.coffee"
  ], both);

  // how-to-print-and-export
  api.addFiles([
    "lib/both/support-articles/how-to-print-and-export/how-to-print-and-export.sass",
    "lib/both/support-articles/how-to-print-and-export/how-to-print-and-export.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-print-and-export/how-to-print-and-export.coffee"
  ], both);

  api.export("JustdoSupportCenterData", both);
});
