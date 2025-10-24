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
  api.use("justdoinc:justdo-i18n@1.0.0", both);
  api.use("tap:i18n", both);

  api.addFiles("lib/both/static.coffee", both);
  
  api.addFiles("lib/client/templates/support-page/support-page.sass", client);
  api.addFiles("lib/client/templates/support-page/support-page.html", client);
  api.addFiles("lib/client/templates/support-page/support-page.coffee", client);
  api.addFiles("lib/both/news-category-registrar.coffee", both);
  api.addFiles("lib/client/templates/support-page/article-category/article-category.sass", client);
  api.addFiles("lib/client/templates/support-page/article-category/article-category.html", client);
  api.addFiles("lib/client/templates/support-page/article-category/article-category.coffee", client);
  
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

  // how-to-change-my-password
  api.addFiles([
    "lib/both/support-articles/how-to-change-my-password/how-to-change-my-password.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-change-my-password/how-to-change-my-password.coffee"
  ], both);

  // how-to-delete-a-task
  api.addFiles([
    "lib/both/support-articles/how-to-delete-a-task/how-to-delete-a-task.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-delete-a-task/how-to-delete-a-task.coffee"
  ], both);

  // who-are-my-justdo-s-administrators
  api.addFiles([
    "lib/both/support-articles/who-are-my-justdo-s-administrators/who-are-my-justdo-s-administrators.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/who-are-my-justdo-s-administrators/who-are-my-justdo-s-administrators.coffee"
  ], both);

  // how-to-change-my-profile-picture-and-details
  api.addFiles([
    "lib/both/support-articles/how-to-change-my-profile-picture-and-details/how-to-change-my-profile-picture-and-details.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-change-my-profile-picture-and-details/how-to-change-my-profile-picture-and-details.coffee"
  ], both);

  // tasks-priorities-how-to-set-and-sort
  api.addFiles([
    "lib/both/support-articles/tasks-priorities-how-to-set-and-sort/tasks-priorities-how-to-set-and-sort.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/tasks-priorities-how-to-set-and-sort/tasks-priorities-how-to-set-and-sort.coffee"
  ], both);

  // how-to-rename-your-justdo
  api.addFiles([
    "lib/both/support-articles/how-to-rename-your-justdo/how-to-rename-your-justdo.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-rename-your-justdo/how-to-rename-your-justdo.coffee"
  ], both);

  // how-to-get-daily-email-notifications
  api.addFiles([
    "lib/both/support-articles/how-to-get-daily-email-notifications/how-to-get-daily-email-notifications.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-get-daily-email-notifications/how-to-get-daily-email-notifications.coffee"
  ], both);

  // how-to-change-the-date-format
  api.addFiles([
    "lib/both/support-articles/how-to-change-the-date-format/how-to-change-the-date-format.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-change-the-date-format/how-to-change-the-date-format.coffee"
  ], both);

  // keyboard-shortcuts
  api.addFiles([
    "lib/both/support-articles/keyboard-shortcuts/keyboard-shortcuts.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/keyboard-shortcuts/keyboard-shortcuts.coffee"
  ], both);

  // how-can-i-expand-collapse-all-tasks
  api.addFiles([
    "lib/both/support-articles/how-can-i-expand-collapse-all-tasks/how-can-i-expand-collapse-all-tasks.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-can-i-expand-collapse-all-tasks/how-can-i-expand-collapse-all-tasks.coffee"
  ], both);

  // how-to-merge-justdos
  api.addFiles([
    "lib/both/support-articles/how-to-merge-justdos/how-to-merge-justdos.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-merge-justdos/how-to-merge-justdos.coffee"
  ], both);

  // justdo-meetings
  api.addFiles([
    "lib/both/support-articles/justdo-meetings/justdo-meetings.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/justdo-meetings/justdo-meetings.coffee"
  ], both);

  // can-the-mobile-apps-work-with-an-on-prem-installation
  api.addFiles([
    "lib/both/support-articles/can-the-mobile-apps-work-with-an-on-prem-installation/can-the-mobile-apps-work-with-an-on-prem-installation.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/can-the-mobile-apps-work-with-an-on-prem-installation/can-the-mobile-apps-work-with-an-on-prem-installation.coffee"
  ], both);

  // how-to-use-the-ticket-queue
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-ticket-queue/how-to-use-the-ticket-queue.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-ticket-queue/how-to-use-the-ticket-queue.coffee"
  ], both);

  // calculated-field
  api.addFiles([
    "lib/both/support-articles/calculated-field/calculated-field.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/calculated-field/calculated-field.coffee"
  ], both);

  // most-recent-product-updates
  api.addFiles([
    "lib/both/support-articles/most-recent-product-updates/most-recent-product-updates.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/most-recent-product-updates/most-recent-product-updates.coffee"
  ], both);

  // how-to-use-the-archiving-capability
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-archiving-capability/how-to-use-the-archiving-capability.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-archiving-capability/how-to-use-the-archiving-capability.coffee"
  ], both);

  // how-to-connect-my-email-to-justdo
  api.addFiles([
    "lib/both/support-articles/how-to-connect-my-email-to-justdo/how-to-connect-my-email-to-justdo.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-connect-my-email-to-justdo/how-to-connect-my-email-to-justdo.coffee"
  ], both);

  // how-to-enable-disable-the-justdo-extensions
  api.addFiles([
    "lib/both/support-articles/how-to-enable-disable-the-justdo-extensions/how-to-enable-disable-the-justdo-extensions.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-enable-disable-the-justdo-extensions/how-to-enable-disable-the-justdo-extensions.coffee"
  ], both);

  // what-is-the-difference-between-an-admin-a-member-and-a-guest
  api.addFiles([
    "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/what-is-the-difference-between-an-admin-a-member-and-a-guest.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/what-is-the-difference-between-an-admin-a-member-and-a-guest.coffee"
  ], both);

  // how-to-use-the-risk-management-extension
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-risk-management-extension/how-to-use-the-risk-management-extension.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-risk-management-extension/how-to-use-the-risk-management-extension.coffee"
  ], both);

  // how-to-invite-users-to-a-justdo
  api.addFiles([
    "lib/both/support-articles/how-to-invite-users-to-a-justdo/how-to-invite-users-to-a-justdo.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-invite-users-to-a-justdo/how-to-invite-users-to-a-justdo.coffee"
  ], both);

  // what-to-do-if-i-can-t-can-t-expand-all-tasks
  api.addFiles([
    "lib/both/support-articles/what-to-do-if-i-can-t-can-t-expand-all-tasks/what-to-do-if-i-can-t-can-t-expand-all-tasks.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/what-to-do-if-i-can-t-can-t-expand-all-tasks/what-to-do-if-i-can-t-can-t-expand-all-tasks.coffee"
  ], both);

  // what-is-the-quick-add-button
  api.addFiles([
    "lib/both/support-articles/what-is-the-quick-add-button/what-is-the-quick-add-button.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/what-is-the-quick-add-button/what-is-the-quick-add-button.coffee"
  ], both);

  // how-to-copy-a-task
  api.addFiles([
    "lib/both/support-articles/how-to-copy-a-task/how-to-copy-a-task.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-copy-a-task/how-to-copy-a-task.coffee"
  ], both);

  // how-to-create-tasks-by-email
  api.addFiles([
    "lib/both/support-articles/how-to-create-tasks-by-email/how-to-create-tasks-by-email.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-create-tasks-by-email/how-to-create-tasks-by-email.coffee"
  ], both);

  // how-to-use-the-project-portfolio-management
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-project-portfolio-management/how-to-use-the-project-portfolio-management.sass"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-project-portfolio-management/how-to-use-the-project-portfolio-management.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-project-portfolio-management/how-to-use-the-project-portfolio-management.coffee"
  ], both);

  // migrate-from-monday-to-justdo
  api.addAssets([
    "lib/both/support-articles/migrate-from-monday-to-justdo/assets/monday-justdo-hierarchy.png",
    "lib/both/support-articles/migrate-from-monday-to-justdo/assets/monday-justdo-field-mapping.png"
  ], client);
  api.addFiles([
    "lib/both/support-articles/migrate-from-monday-to-justdo/migrate-from-monday-to-justdo.sass",
    "lib/both/support-articles/migrate-from-monday-to-justdo/migrate-from-monday-to-justdo.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/migrate-from-monday-to-justdo/migrate-from-monday-to-justdo.coffee"
  ], both);
  this.addI18nFiles(api, "lib/both/support-articles/migrate-from-monday-to-justdo/i18n/seo.{}.i18n.json");
  this.addI18nFiles(api, "lib/both/support-articles/migrate-from-monday-to-justdo/i18n/part1.{}.i18n.json");
  this.addI18nFiles(api, "lib/both/support-articles/migrate-from-monday-to-justdo/i18n/part2.{}.i18n.json");
  this.addI18nFiles(api, "lib/both/support-articles/migrate-from-monday-to-justdo/i18n/part3.{}.i18n.json");
  this.addI18nFiles(api, "lib/both/support-articles/migrate-from-monday-to-justdo/i18n/part4.{}.i18n.json");

  // Always after templates
  this.addI18nFiles(api, "i18n/{}.i18n.json");

  api.export("JustdoSupportCenterData", both);
});
