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

  // Always after templates
  api.addFiles([
    "i18n/en.i18n.json",
    "i18n/ar.i18n.json",
    "i18n/es.i18n.json",
    "i18n/fr.i18n.json",
    "i18n/he.i18n.json",
    "i18n/ja.i18n.json",
    "i18n/km.i18n.json",
    "i18n/ko.i18n.json",
    "i18n/pt-PT.i18n.json",
    "i18n/pt-BR.i18n.json",
    "i18n/vi.i18n.json",
    "i18n/ru.i18n.json",
    "i18n/yi.i18n.json",
    "i18n/it.i18n.json",
    "i18n/de.i18n.json",
    "i18n/hi.i18n.json",
    "i18n/tr.i18n.json",
    "i18n/el.i18n.json",
    "i18n/da.i18n.json",
    "i18n/fi.i18n.json",
    "i18n/nl.i18n.json",
    "i18n/sv.i18n.json",
    "i18n/th.i18n.json",
    "i18n/id.i18n.json",
    "i18n/pl.i18n.json",
    "i18n/cs.i18n.json",
    "i18n/hu.i18n.json",
    "i18n/ro.i18n.json",
    "i18n/sk.i18n.json",
    "i18n/uk.i18n.json",
    "i18n/bg.i18n.json",
    "i18n/hr.i18n.json",
    "i18n/sr.i18n.json",
    "i18n/sl.i18n.json",
    "i18n/et.i18n.json",
    "i18n/lv.i18n.json",
    "i18n/lt.i18n.json",
    "i18n/am.i18n.json",
    "i18n/zh-CN.i18n.json",
    "i18n/zh-TW.i18n.json",
    "i18n/sw.i18n.json",
    "i18n/af.i18n.json",
    "i18n/az.i18n.json",
    "i18n/be.i18n.json",
    "i18n/bn.i18n.json",
    "i18n/bs.i18n.json",
    "i18n/ca.i18n.json",
    "i18n/eu.i18n.json",
    "i18n/lb.i18n.json",
    "i18n/mk.i18n.json",
    "i18n/ne.i18n.json",
    "i18n/nb.i18n.json",
    "i18n/sq.i18n.json",
    "i18n/ta.i18n.json",
    "i18n/uz.i18n.json",
    "i18n/hy.i18n.json",
    "i18n/kk.i18n.json",
    "i18n/ky.i18n.json",
    "i18n/ms.i18n.json",
    "i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/en.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ar.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/es.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/fr.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/he.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ja.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/km.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ko.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/vi.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ru.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/yi.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/it.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/de.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/hi.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/tr.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/el.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/da.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/fi.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/nl.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/sv.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/th.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/id.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/pl.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/cs.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/hu.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ro.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/sk.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/uk.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/bg.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/hr.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/sr.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/sl.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/et.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/lv.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/lt.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/am.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/sw.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/af.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/az.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/be.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/bn.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/bs.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ca.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/eu.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/lb.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/mk.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ne.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/nb.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/sq.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ta.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/uz.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/hy.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/kk.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ky.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/ms.i18n.json",
    // "lib/both/support-articles/can-i-install-a-local-copy-of-justdo/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/custom-fields/i18n/en.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ar.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/es.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/fr.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/he.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ja.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/km.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ko.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/vi.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ru.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/yi.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/it.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/de.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/hi.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/tr.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/el.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/da.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/fi.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/nl.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/sv.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/th.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/id.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/pl.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/cs.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/hu.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ro.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/sk.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/uk.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/bg.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/hr.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/sr.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/sl.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/et.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/lv.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/lt.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/am.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/sw.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/af.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/az.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/be.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/bn.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/bs.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ca.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/eu.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/lb.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/mk.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ne.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/nb.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/sq.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ta.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/uz.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/hy.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/kk.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ky.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/ms.i18n.json",
    // "lib/both/support-articles/custom-fields/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-configure-workdays-and-holidays/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/how-to-create-custom-grid-views/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-create-custom-grid-views/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-import-tasks-from-a-spreadsheet/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-plan-and-track-working-hours/i18n/tg.i18n.json"
  ], both);
  
  api.addFiles([
    "lib/both/support-articles/how-to-print-and-export/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-print-and-export/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-share-tasks-with-project-members/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/how-to-use-buffer-tasks/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-use-buffer-tasks/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-use-gantt-dependencies/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/how-to-use-the-gantt/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-use-the-gantt/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/en.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ar.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/es.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/fr.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/he.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ja.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/km.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ko.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/vi.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ru.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/yi.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/it.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/de.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/hi.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/tr.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/el.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/da.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/fi.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/nl.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/sv.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/th.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/id.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/pl.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/cs.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/hu.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ro.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/sk.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/uk.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/bg.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/hr.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/sr.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/sl.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/et.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/lv.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/lt.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/am.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/sw.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/af.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/az.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/be.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/bn.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/bs.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ca.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/eu.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/lb.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/mk.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ne.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/nb.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/sq.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ta.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/uz.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/hy.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/kk.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ky.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/ms.i18n.json",
    // "lib/both/support-articles/how-to-use-the-slack-functionality/i18n/tg.i18n.json"
  ], both);
  
  api.addFiles([
    "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/en.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ar.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/es.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/fr.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/he.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ja.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/km.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ko.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/vi.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ru.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/yi.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/it.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/de.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/hi.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/tr.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/el.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/da.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/fi.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/nl.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/sv.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/th.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/id.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/pl.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/cs.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/hu.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ro.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/sk.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/uk.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/bg.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/hr.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/sr.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/sl.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/et.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/lv.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/lt.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/am.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/sw.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/af.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/az.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/be.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/bn.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/bs.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ca.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/eu.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/lb.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/mk.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ne.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/nb.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/sq.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ta.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/uz.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/hy.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/kk.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ky.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/ms.i18n.json",
    // "lib/both/support-articles/what-is-justdo-s-resource-management-extension/i18n/tg.i18n.json"
  ], both);

  api.addFiles([
    "lib/both/support-articles/justdo-extensions/i18n/en.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ar.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/es.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/fr.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/he.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ja.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/km.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ko.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/pt-PT.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/pt-BR.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/vi.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ru.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/yi.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/it.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/de.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/hi.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/tr.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/el.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/da.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/fi.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/nl.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/sv.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/th.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/id.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/pl.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/cs.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/hu.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ro.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/sk.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/uk.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/bg.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/hr.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/sr.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/sl.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/et.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/lv.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/lt.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/am.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/zh-CN.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/zh-TW.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/sw.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/af.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/az.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/be.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/bn.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/bs.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ca.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/eu.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/lb.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/mk.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ne.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/nb.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/sq.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ta.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/uz.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/hy.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/kk.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ky.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/ms.i18n.json",
    // "lib/both/support-articles/justdo-extensions/i18n/tg.i18n.json"
  ], both);

  api.export("JustdoSupportCenterData", both);
});
