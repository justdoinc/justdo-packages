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
  api.addAssets([
    "lib/both/support-articles/how-to-use-buffer-tasks/assets/slack_settings.jpg",
    "lib/both/support-articles/how-to-use-buffer-tasks/assets/buffer.jpg"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-buffer-tasks/how-to-use-buffer-tasks.sass",
    "lib/both/support-articles/how-to-use-buffer-tasks/how-to-use-buffer-tasks.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-buffer-tasks/how-to-use-buffer-tasks.coffee"
  ], both);

  // how-to-create-custom-grid-views
  api.addAssets([
    "lib/both/support-articles/how-to-create-custom-grid-views/assets/Snag_4e48849e.png",
    "lib/both/support-articles/how-to-create-custom-grid-views/assets/Snag_4e4943c8.png",
    "lib/both/support-articles/how-to-create-custom-grid-views/assets/1B891E1D-F66A-4C42-AA98-D6F83CEECD4D.GIF",
    "lib/both/support-articles/how-to-create-custom-grid-views/assets/F71A1D92-5C93-4A77-8AEB-4BBE61ADA721.GIF"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-create-custom-grid-views/how-to-create-custom-grid-views.sass",
    "lib/both/support-articles/how-to-create-custom-grid-views/how-to-create-custom-grid-views.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-create-custom-grid-views/how-to-create-custom-grid-views.coffee"
  ], both);

  // how-to-use-gantt-dependencies
  api.addAssets([
    "lib/both/support-articles/how-to-use-gantt-dependencies/assets/clickable_ids.jpg",
    "lib/both/support-articles/how-to-use-gantt-dependencies/assets/dependencies_tab.jpg",
    "lib/both/support-articles/how-to-use-gantt-dependencies/assets/2022-06-13_9-51-21_Types_of_dependency.gif"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-gantt-dependencies/how-to-use-gantt-dependencies.sass",
    "lib/both/support-articles/how-to-use-gantt-dependencies/how-to-use-gantt-dependencies.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-gantt-dependencies/how-to-use-gantt-dependencies.coffee"
  ], both);

  // how-to-plan-and-track-working-hours
  api.addAssets([
    "lib/both/support-articles/how-to-plan-and-track-working-hours/assets/Snag_4373538.png",
    "lib/both/support-articles/how-to-plan-and-track-working-hours/assets/CA5EC666-3D7C-4725-94E1-80892B49D82E.GIF",
    "lib/both/support-articles/how-to-plan-and-track-working-hours/assets/29CD686D-AC7B-40F5-95D8-0270D4307A27.GIF",
    "lib/both/support-articles/how-to-plan-and-track-working-hours/assets/5E06D989-352D-4594-B6A2-F4098F303153.GIF"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-plan-and-track-working-hours/how-to-plan-and-track-working-hours.sass",
    "lib/both/support-articles/how-to-plan-and-track-working-hours/how-to-plan-and-track-working-hours.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-plan-and-track-working-hours/how-to-plan-and-track-working-hours.coffee"
  ], both);

  // justdo-extensions
  api.addAssets([
    "lib/both/support-articles/justdo-extensions/assets/extensions.png",
    "lib/both/support-articles/justdo-extensions/assets/exts.png"
  ], client);
  api.addFiles([
    "lib/both/support-articles/justdo-extensions/justdo-extensions.sass",
    "lib/both/support-articles/justdo-extensions/justdo-extensions.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/justdo-extensions/justdo-extensions.coffee"
  ], both);

  // how-to-configure-workdays-and-holidays
  api.addAssets([
    "lib/both/support-articles/how-to-configure-workdays-and-holidays/assets/user_workdays.GIF",
    "lib/both/support-articles/how-to-configure-workdays-and-holidays/assets/JD_workdays.GIF"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-configure-workdays-and-holidays/how-to-configure-workdays-and-holidays.sass",
    "lib/both/support-articles/how-to-configure-workdays-and-holidays/how-to-configure-workdays-and-holidays.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-configure-workdays-and-holidays/how-to-configure-workdays-and-holidays.coffee"
  ], both);

  // how-to-use-the-gantt
  api.addAssets([
    "lib/both/support-articles/how-to-use-the-gantt/assets/baseline.png",
    "lib/both/support-articles/how-to-use-the-gantt/assets/critical_path_IDs.png",
    "lib/both/support-articles/how-to-use-the-gantt/assets/dependencies_tab.png",
    "lib/both/support-articles/how-to-use-the-gantt/assets/completion.png",
    "lib/both/support-articles/how-to-use-the-gantt/assets/Gantt.png",
    "lib/both/support-articles/how-to-use-the-gantt/assets/basket_dates.jpg",
    "lib/both/support-articles/how-to-use-the-gantt/assets/dependencies.GIF",
    "lib/both/support-articles/how-to-use-the-gantt/assets/Gantt_viewing_area.GIF"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-gantt/how-to-use-the-gantt.sass",
    "lib/both/support-articles/how-to-use-the-gantt/how-to-use-the-gantt.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-gantt/how-to-use-the-gantt.coffee"
  ], both);

  // how-to-import-tasks-from-a-spreadsheet
  api.addAssets([
    "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/assets/wrong_owner_email_in_import.jpg",
    "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/assets/import_undo.jpg",
    "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/assets/import_icon.png",
    "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/assets/import_dependencies1.gif",
    "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/assets/Import1.GIF"
  ], client);
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
  api.addAssets([
    "lib/both/support-articles/custom-fields/assets/configure.jpg",
    "lib/both/support-articles/custom-fields/assets/smart_numbers_menu.jpg"
  ], client);
  api.addFiles([
    "lib/both/support-articles/custom-fields/custom-fields.sass",
    "lib/both/support-articles/custom-fields/custom-fields.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/custom-fields/custom-fields.coffee"
  ], both);

  // how-to-share-tasks-with-project-members
  api.addAssets([
    "lib/both/support-articles/how-to-share-tasks-with-project-members/assets/empty_JD.png",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/assets/Selection_576.png",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/assets/2017-11-14_16-29-29.png",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/assets/adding_members.jpg",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/assets/Selection_577.png",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/assets/Selection_575.png",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/assets/edit_members.jpg",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/assets/2017-11-14_16-31-30.png",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/assets/2017-11-14_16-34-41.png"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-share-tasks-with-project-members/how-to-share-tasks-with-project-members.sass",
    "lib/both/support-articles/how-to-share-tasks-with-project-members/how-to-share-tasks-with-project-members.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-share-tasks-with-project-members/how-to-share-tasks-with-project-members.coffee"
  ], both);

  // how-to-print-and-export
  api.addAssets([
    "lib/both/support-articles/how-to-print-and-export/assets/print_menu.jpg",
    "lib/both/support-articles/how-to-print-and-export/assets/print_settings.jpg",
    "lib/both/support-articles/how-to-print-and-export/assets/print_screen.jpg"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-print-and-export/how-to-print-and-export.sass",
    "lib/both/support-articles/how-to-print-and-export/how-to-print-and-export.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-print-and-export/how-to-print-and-export.coffee"
  ], both);

  api.export("JustdoSupportCenterData", both);
});
