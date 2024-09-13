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

  // how-to-invite-users-to-a-justdo
  // api.addAssets([
  //   "lib/both/support-articles/how-to-invite-users-to-a-justdo/assets/bulk1.jpg",
  //   "lib/both/support-articles/how-to-invite-users-to-a-justdo/assets/bulk_add.png",
  //   "lib/both/support-articles/how-to-invite-users-to-a-justdo/assets/bulk_add_2.jpg"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-invite-users-to-a-justdo/how-to-invite-users-to-a-justdo.sass",
  //   "lib/both/support-articles/how-to-invite-users-to-a-justdo/how-to-invite-users-to-a-justdo.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-invite-users-to-a-justdo/how-to-invite-users-to-a-justdo.coffee"
  // ], client);

  // how-to-use-the-archiving-capability
  // api.addAssets([
  //   "lib/both/support-articles/how-to-use-the-archiving-capability/assets/archive1.jpg",
  //   "lib/both/support-articles/how-to-use-the-archiving-capability/assets/archive2.jpg"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-use-the-archiving-capability/how-to-use-the-archiving-capability.sass",
  //   "lib/both/support-articles/how-to-use-the-archiving-capability/how-to-use-the-archiving-capability.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-use-the-archiving-capability/how-to-use-the-archiving-capability.coffee"
  // ], client);

  // how-to-use-the-risk-management-extension
  // api.addAssets([
  //   "lib/both/support-articles/how-to-use-the-risk-management-extension/assets/risk1.jpg",
  //   "lib/both/support-articles/how-to-use-the-risk-management-extension/assets/risk2.jpg",
  //   "lib/both/support-articles/how-to-use-the-risk-management-extension/assets/risk5.jpg",
  //   "lib/both/support-articles/how-to-use-the-risk-management-extension/assets/risk6.jpg",
  //   "lib/both/support-articles/how-to-use-the-risk-management-extension/assets/risk4.gif",
  //   "lib/both/support-articles/how-to-use-the-risk-management-extension/assets/risk3.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-use-the-risk-management-extension/how-to-use-the-risk-management-extension.sass",
  //   "lib/both/support-articles/how-to-use-the-risk-management-extension/how-to-use-the-risk-management-extension.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-use-the-risk-management-extension/how-to-use-the-risk-management-extension.coffee"
  // ], client);

  // how-to-copy-a-task
  // api.addAssets([
  //   "lib/both/support-articles/how-to-copy-a-task/assets/copy2.jpg",
  //   "lib/both/support-articles/how-to-copy-a-task/assets/copy_task_icon.jpg",
  //   "lib/both/support-articles/how-to-copy-a-task/assets/copy1.jpg"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-copy-a-task/how-to-copy-a-task.sass",
  //   "lib/both/support-articles/how-to-copy-a-task/how-to-copy-a-task.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-copy-a-task/how-to-copy-a-task.coffee"
  // ], client);

  // how-to-use-the-slack-functionality
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-slack-functionality/how-to-use-the-slack-functionality.sass",
    "lib/both/support-articles/how-to-use-the-slack-functionality/how-to-use-the-slack-functionality.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/how-to-use-the-slack-functionality/how-to-use-the-slack-functionality.coffee"
  ], client);

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
  ], client);

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
  ], client);

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
  ], client);

  // justdo-meetings
  // api.addAssets([
  //   "lib/both/support-articles/justdo-meetings/assets/schedule_a_meeting.jpg",
  //   "lib/both/support-articles/justdo-meetings/assets/start_a_meeting.jpg",
  //   "lib/both/support-articles/justdo-meetings/assets/delete_meeting.jpg",
  //   "lib/both/support-articles/justdo-meetings/assets/meeting_date_and_time.gif",
  //   "lib/both/support-articles/justdo-meetings/assets/move_agenda_items.gif",
  //   "lib/both/support-articles/justdo-meetings/assets/notes.gif",
  //   "lib/both/support-articles/justdo-meetings/assets/task_notes.gif",
  //   "lib/both/support-articles/justdo-meetings/assets/action_item.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/justdo-meetings/justdo-meetings.sass",
  //   "lib/both/support-articles/justdo-meetings/justdo-meetings.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/justdo-meetings/justdo-meetings.coffee"
  // ], client);

  // how-to-connect-my-email-to-justdo
  // api.addAssets([
  //   "lib/both/support-articles/how-to-connect-my-email-to-justdo/assets/email_from_task_pane.jpg",
  //   "lib/both/support-articles/how-to-connect-my-email-to-justdo/assets/email_meeting_notes.jpg",
  //   "lib/both/support-articles/how-to-connect-my-email-to-justdo/assets/Snag_298b6178.png",
  //   "lib/both/support-articles/how-to-connect-my-email-to-justdo/assets/Snag_2989e43e.png",
  //   "lib/both/support-articles/how-to-connect-my-email-to-justdo/assets/Snag_298d21d5.png"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-connect-my-email-to-justdo/how-to-connect-my-email-to-justdo.sass",
  //   "lib/both/support-articles/how-to-connect-my-email-to-justdo/how-to-connect-my-email-to-justdo.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-connect-my-email-to-justdo/how-to-connect-my-email-to-justdo.coffee"
  // ], client);

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
  ], client);

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
  ], client);

  // can-the-mobile-apps-work-with-an-on-prem-installation
  // api.addAssets([
  //   "lib/both/support-articles/can-the-mobile-apps-work-with-an-on-prem-installation/assets/URL2.png",
  //   "lib/both/support-articles/can-the-mobile-apps-work-with-an-on-prem-installation/assets/URL1.png",
  //   "lib/both/support-articles/can-the-mobile-apps-work-with-an-on-prem-installation/assets/App_login1.jpg",
  //   "lib/both/support-articles/can-the-mobile-apps-work-with-an-on-prem-installation/assets/App_login_with_server1.jpg"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/can-the-mobile-apps-work-with-an-on-prem-installation/can-the-mobile-apps-work-with-an-on-prem-installation.sass",
  //   "lib/both/support-articles/can-the-mobile-apps-work-with-an-on-prem-installation/can-the-mobile-apps-work-with-an-on-prem-installation.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/can-the-mobile-apps-work-with-an-on-prem-installation/can-the-mobile-apps-work-with-an-on-prem-installation.coffee"
  // ], client);

  // how-to-create-tasks-by-email
  // api.addAssets([
  //   "lib/both/support-articles/how-to-create-tasks-by-email/assets/mceclip0.png",
  //   "lib/both/support-articles/how-to-create-tasks-by-email/assets/spawn_emails.GIF"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-create-tasks-by-email/how-to-create-tasks-by-email.sass",
  //   "lib/both/support-articles/how-to-create-tasks-by-email/how-to-create-tasks-by-email.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-create-tasks-by-email/how-to-create-tasks-by-email.coffee"
  // ], client);

  // what-is-the-quick-add-button
  // api.addAssets([
  //   "lib/both/support-articles/what-is-the-quick-add-button/assets/quick_add.GIF"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/what-is-the-quick-add-button/what-is-the-quick-add-button.sass",
  //   "lib/both/support-articles/what-is-the-quick-add-button/what-is-the-quick-add-button.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/what-is-the-quick-add-button/what-is-the-quick-add-button.coffee"
  // ], client);

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
  ], client);

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
  ], client);

  // what-is-the-difference-between-an-admin-a-member-and-a-guest
  // api.addAssets([
  //   "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/assets/mceclip1.png",
  //   "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/assets/mceclip4.png",
  //   "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/assets/mceclip0.png",
  //   "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/assets/mceclip2.png",
  //   "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/assets/mceclip3.png",
  //   "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/assets/user_types_gif.GIF"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/what-is-the-difference-between-an-admin-a-member-and-a-guest.sass",
  //   "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/what-is-the-difference-between-an-admin-a-member-and-a-guest.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/what-is-the-difference-between-an-admin-a-member-and-a-guest/what-is-the-difference-between-an-admin-a-member-and-a-guest.coffee"
  // ], client);

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
  ], client);

  // how-to-merge-justdos
  // api.addAssets([
  //   "lib/both/support-articles/how-to-merge-justdos/assets/confirm_merge.png",
  //   "lib/both/support-articles/how-to-merge-justdos/assets/merge_option.png",
  //   "lib/both/support-articles/how-to-merge-justdos/assets/merge_plugin.png"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-merge-justdos/how-to-merge-justdos.sass",
  //   "lib/both/support-articles/how-to-merge-justdos/how-to-merge-justdos.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-merge-justdos/how-to-merge-justdos.coffee"
  // ], client);

  // most-recent-product-updates
  // api.addAssets([
  //   "lib/both/support-articles/most-recent-product-updates/assets/color_state.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/time_tracker.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/risk.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/color_state_in_grid1.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/Project_health.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/status_indicator.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/Gantt.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/Snag_1574d44e.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/Snag_1574b647.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/media_1.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/media_3.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/baseline_deltas.jpg",
  //   "lib/both/support-articles/most-recent-product-updates/assets/media_4.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/undo.jpg",
  //   "lib/both/support-articles/most-recent-product-updates/assets/bulk_add_2.jpg",
  //   "lib/both/support-articles/most-recent-product-updates/assets/mceclip1.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/mceclip0.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/bulk_add.png",
  //   "lib/both/support-articles/most-recent-product-updates/assets/meeting_indications.jpg",
  //   "lib/both/support-articles/most-recent-product-updates/assets/buffer.jpg",
  //   "lib/both/support-articles/most-recent-product-updates/assets/theme_changing.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/multi_select.jpg",
  //   "lib/both/support-articles/most-recent-product-updates/assets/favorites__2_.GIF",
  //   "lib/both/support-articles/most-recent-product-updates/assets/done_end_date.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/FF2938DD-0A52-468F-85D5-232ECD9701C4.GIF",
  //   "lib/both/support-articles/most-recent-product-updates/assets/2022-05-18_23-01-15_Grid_View_1.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/2022-04-13_9-05-33_great_things_serial_dependencies.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/2022-03-20_16-35-23_Quick_notes.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/8F3061F0-38CF-43B1-BED2-4539E16624C1.GIF",
  //   "lib/both/support-articles/most-recent-product-updates/assets/0DB83A2B-917A-4536-82BA-3EF189662E8C.GIF",
  //   "lib/both/support-articles/most-recent-product-updates/assets/2022-04-13_9-09-52_Gantt_Scroll.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/2022-02-23_17-17-30_group_actions.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/archive.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/2021-11-08_15-22-38_3_.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/2022-02-23_17-17-30_group_actions_cropped.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/89CD49C2-6B9A-4557-B503-F8896544B735.GIF",
  //   "lib/both/support-articles/most-recent-product-updates/assets/2022-03-20_16-35-23_Quick_notes_convert_note_to_task.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/Lags.GIF",
  //   "lib/both/support-articles/most-recent-product-updates/assets/2022-05-18_23-01-15_Grid_View.gif",
  //   "lib/both/support-articles/most-recent-product-updates/assets/Enhanced_import_1.GIF",
  //   "lib/both/support-articles/most-recent-product-updates/assets/freeze_subject.GIF",
  //   "lib/both/support-articles/most-recent-product-updates/assets/import_dependencies1.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/most-recent-product-updates/most-recent-product-updates.sass",
  //   "lib/both/support-articles/most-recent-product-updates/most-recent-product-updates.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/most-recent-product-updates/most-recent-product-updates.coffee"
  // ], client);

  // what-is-justdo-s-resource-management-extension
  api.addFiles([
    "lib/both/support-articles/what-is-justdo-s-resource-management-extension/what-is-justdo-s-resource-management-extension.sass",
    "lib/both/support-articles/what-is-justdo-s-resource-management-extension/what-is-justdo-s-resource-management-extension.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/what-is-justdo-s-resource-management-extension/what-is-justdo-s-resource-management-extension.coffee"
  ], client);

  // how-to-enable-disable-the-justdo-extensions
  // api.addAssets([
  //   "lib/both/support-articles/how-to-enable-disable-the-justdo-extensions/assets/settings.png",
  //   "lib/both/support-articles/how-to-enable-disable-the-justdo-extensions/assets/extensions_1.png"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-enable-disable-the-justdo-extensions/how-to-enable-disable-the-justdo-extensions.sass",
  //   "lib/both/support-articles/how-to-enable-disable-the-justdo-extensions/how-to-enable-disable-the-justdo-extensions.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-enable-disable-the-justdo-extensions/how-to-enable-disable-the-justdo-extensions.coffee"
  // ], client);

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
  ], client);

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
  ], client);

  // how-can-i-expand-collapse-all-tasks
  // api.addAssets([
  //   "lib/both/support-articles/how-can-i-expand-collapse-all-tasks/assets/2017-11-14_17-15-05.png",
  //   "lib/both/support-articles/how-can-i-expand-collapse-all-tasks/assets/colapseandexpand.gif",
  //   "lib/both/support-articles/how-can-i-expand-collapse-all-tasks/assets/expand-collapse.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-can-i-expand-collapse-all-tasks/how-can-i-expand-collapse-all-tasks.sass",
  //   "lib/both/support-articles/how-can-i-expand-collapse-all-tasks/how-can-i-expand-collapse-all-tasks.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-can-i-expand-collapse-all-tasks/how-can-i-expand-collapse-all-tasks.coffee"
  // ], client);

  // what-to-do-if-i-can-t-can-t-expend-all-tasks
  // api.addAssets([
  //   "lib/both/support-articles/what-to-do-if-i-can-t-can-t-expend-all-tasks/assets/2017-11-13_21-33-26.png",
  //   "lib/both/support-articles/what-to-do-if-i-can-t-can-t-expend-all-tasks/assets/2017-11-13_21-34-39.png",
  //   "lib/both/support-articles/what-to-do-if-i-can-t-can-t-expend-all-tasks/assets/2017-11-13_21-36-39.png"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/what-to-do-if-i-can-t-can-t-expend-all-tasks/what-to-do-if-i-can-t-can-t-expend-all-tasks.sass",
  //   "lib/both/support-articles/what-to-do-if-i-can-t-can-t-expend-all-tasks/what-to-do-if-i-can-t-can-t-expend-all-tasks.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/what-to-do-if-i-can-t-can-t-expend-all-tasks/what-to-do-if-i-can-t-can-t-expend-all-tasks.coffee"
  // ], client);

  // calculated-field
  // api.addFiles([
  //   "lib/both/support-articles/calculated-field/calculated-field.sass",
  //   "lib/both/support-articles/calculated-field/calculated-field.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/calculated-field/calculated-field.coffee"
  // ], client);

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
  ], client);

  // how-to-use-the-ticket-queue
  // api.addAssets([
  //   "lib/both/support-articles/how-to-use-the-ticket-queue/assets/TicketQ_define.GIF",
  //   "lib/both/support-articles/how-to-use-the-ticket-queue/assets/ticketQ_add_task.GIF"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-use-the-ticket-queue/how-to-use-the-ticket-queue.sass",
  //   "lib/both/support-articles/how-to-use-the-ticket-queue/how-to-use-the-ticket-queue.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-use-the-ticket-queue/how-to-use-the-ticket-queue.coffee"
  // ], client);

  // keyboard-shortcuts
  // api.addFiles([
  //   "lib/both/support-articles/keyboard-shortcuts/keyboard-shortcuts.sass",
  //   "lib/both/support-articles/keyboard-shortcuts/keyboard-shortcuts.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/keyboard-shortcuts/keyboard-shortcuts.coffee"
  // ], client);

  // who-are-my-justdo-s-administrators
  // api.addAssets([
  //   "lib/both/support-articles/who-are-my-justdo-s-administrators/assets/project_admins_and_members.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/who-are-my-justdo-s-administrators/who-are-my-justdo-s-administrators.sass",
  //   "lib/both/support-articles/who-are-my-justdo-s-administrators/who-are-my-justdo-s-administrators.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/who-are-my-justdo-s-administrators/who-are-my-justdo-s-administrators.coffee"
  // ], client);

  // can-i-install-a-local-copy-of-justdo
  api.addFiles([
    "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/can-i-install-a-local-copy-of-justdo.sass",
    "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/can-i-install-a-local-copy-of-justdo.html"
  ], client);
  api.addFiles([
    "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/can-i-install-a-local-copy-of-justdo.coffee"
  ], client);

  // how-to-rename-your-justdo
  // api.addAssets([
  //   "lib/both/support-articles/how-to-rename-your-justdo/assets/how_to_rename_a_project.gif",
  //   "lib/both/support-articles/how-to-rename-your-justdo/assets/rename_JD.GIF"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-rename-your-justdo/how-to-rename-your-justdo.sass",
  //   "lib/both/support-articles/how-to-rename-your-justdo/how-to-rename-your-justdo.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-rename-your-justdo/how-to-rename-your-justdo.coffee"
  // ], client);

  // tasks-priorities-how-to-set-and-sort
  // api.addAssets([
  //   "lib/both/support-articles/tasks-priorities-how-to-set-and-sort/assets/how_to_manually_prioritize_tasks.gif",
  //   "lib/both/support-articles/tasks-priorities-how-to-set-and-sort/assets/how_to_set_priority.gif",
  //   "lib/both/support-articles/tasks-priorities-how-to-set-and-sort/assets/How_to_sort_by_priority.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/tasks-priorities-how-to-set-and-sort/tasks-priorities-how-to-set-and-sort.sass",
  //   "lib/both/support-articles/tasks-priorities-how-to-set-and-sort/tasks-priorities-how-to-set-and-sort.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/tasks-priorities-how-to-set-and-sort/tasks-priorities-how-to-set-and-sort.coffee"
  // ], client);

  // how-to-get-daily-email-notifications
  // api.addAssets([
  //   "lib/both/support-articles/how-to-get-daily-email-notifications/assets/how_to_turn_on_daily_emails.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-get-daily-email-notifications/how-to-get-daily-email-notifications.sass",
  //   "lib/both/support-articles/how-to-get-daily-email-notifications/how-to-get-daily-email-notifications.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-get-daily-email-notifications/how-to-get-daily-email-notifications.coffee"
  // ], client);

  // how-to-change-my-password
  // api.addAssets([
  //   "lib/both/support-articles/how-to-change-my-password/assets/how_to_change_your_password.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-change-my-password/how-to-change-my-password.sass",
  //   "lib/both/support-articles/how-to-change-my-password/how-to-change-my-password.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-change-my-password/how-to-change-my-password.coffee"
  // ], client);

  // how-to-delete-a-task
  // api.addAssets([
  //   "lib/both/support-articles/how-to-delete-a-task/assets/hot_to_delete_a_project.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-delete-a-task/how-to-delete-a-task.sass",
  //   "lib/both/support-articles/how-to-delete-a-task/how-to-delete-a-task.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-delete-a-task/how-to-delete-a-task.coffee"
  // ], client);

  // how-to-change-the-date-format
  // api.addAssets([
  //   "lib/both/support-articles/how-to-change-the-date-format/assets/how_to_change_the_date_format.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-change-the-date-format/how-to-change-the-date-format.sass",
  //   "lib/both/support-articles/how-to-change-the-date-format/how-to-change-the-date-format.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-change-the-date-format/how-to-change-the-date-format.coffee"
  // ], client);

  // how-to-change-my-profile-picture-and-details
  // api.addAssets([
  //   "lib/both/support-articles/how-to-change-my-profile-picture-and-details/assets/_how_to_change_a_profile_picture.gif"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-change-my-profile-picture-and-details/how-to-change-my-profile-picture-and-details.sass",
  //   "lib/both/support-articles/how-to-change-my-profile-picture-and-details/how-to-change-my-profile-picture-and-details.html"
  // ], client);
  // api.addFiles([
  //   "lib/both/support-articles/how-to-change-my-profile-picture-and-details/how-to-change-my-profile-picture-and-details.coffee"
  // ], client);

  api.export("JustdoSupportCenterData", both);
});
