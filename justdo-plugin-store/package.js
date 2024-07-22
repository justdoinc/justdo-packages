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

  api.use("ecmascript", both);
  api.use("tmeasday:check-npm-versions@0.3.1", both);

  api.use("mongo", both);

  api.use("underscore", both);
  api.use("coffeescript", both);

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
  api.use("webapp", server);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", both);
  api.use("tap:i18n", both);
  api.use("justdoinc:justdo-i18n@1.0.0", both);

  api.use("tracker", client);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);

  api.addFiles("store-db/init.coffee", both);
  api.addFiles("store-db/categories.coffee", both);

  // justdo-calendar-view
  api.addFiles("store-db/plugins/justdo-calendar-view/justdo-calendar-view.coffee", both);
  api.addAssets("store-db/plugins/justdo-calendar-view/media/store-list-icon.png", client);

  // justdo-planning-utilities
  api.addFiles("store-db/plugins/gantt-chart/gantt-chart.coffee", both);
  api.addAssets("store-db/plugins/gantt-chart/media/delivery-planner-icon.png", client);
  api.addAssets("store-db/plugins/gantt-chart/media/delivery-planner-screenshot.png", client);

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

  // risk-management
  api.addFiles("store-db/plugins/risk-management/risk-management.coffee", both);
  api.addAssets("store-db/plugins/risk-management/media/store-list-icon.png", client);

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

  // justdo-checklist
  api.addFiles("store-db/plugins/justdo-checklist/justdo-checklist.coffee", both);
  api.addAssets("store-db/plugins/justdo-checklist/media/checklist-icon.jpg", client);


  api.addFiles("lib/both/analytics.coffee", both);

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

  // Categories
  api.addFiles([
    "store-db/i18n/categories.en.i18n.json",
    "store-db/i18n/categories.ar.i18n.json",
    "store-db/i18n/categories.es.i18n.json",
    "store-db/i18n/categories.fr.i18n.json",
    "store-db/i18n/categories.he.i18n.json",
    "store-db/i18n/categories.ja.i18n.json",
    "store-db/i18n/categories.km.i18n.json",
    "store-db/i18n/categories.ko.i18n.json",
    "store-db/i18n/categories.pt-PT.i18n.json",
    "store-db/i18n/categories.pt-BR.i18n.json",
    "store-db/i18n/categories.vi.i18n.json",
    "store-db/i18n/categories.ru.i18n.json",
    "store-db/i18n/categories.yi.i18n.json",
    "store-db/i18n/categories.it.i18n.json",
    "store-db/i18n/categories.de.i18n.json",
    "store-db/i18n/categories.hi.i18n.json",
    "store-db/i18n/categories.tr.i18n.json",
    "store-db/i18n/categories.el.i18n.json",
    "store-db/i18n/categories.da.i18n.json",
    "store-db/i18n/categories.fi.i18n.json",
    "store-db/i18n/categories.nl.i18n.json",
    "store-db/i18n/categories.sv.i18n.json",
    "store-db/i18n/categories.th.i18n.json",
    "store-db/i18n/categories.id.i18n.json",
    "store-db/i18n/categories.pl.i18n.json",
    "store-db/i18n/categories.cs.i18n.json",
    "store-db/i18n/categories.hu.i18n.json",
    "store-db/i18n/categories.ro.i18n.json",
    "store-db/i18n/categories.sk.i18n.json",
    "store-db/i18n/categories.uk.i18n.json",
    "store-db/i18n/categories.bg.i18n.json",
    "store-db/i18n/categories.hr.i18n.json",
    "store-db/i18n/categories.sr.i18n.json",
    "store-db/i18n/categories.sl.i18n.json",
    "store-db/i18n/categories.et.i18n.json",
    "store-db/i18n/categories.lv.i18n.json",
    "store-db/i18n/categories.lt.i18n.json",
    "store-db/i18n/categories.am.i18n.json",
    "store-db/i18n/categories.zh-CN.i18n.json",
    "store-db/i18n/categories.zh-TW.i18n.json",
    "store-db/i18n/categories.sw.i18n.json",
    "store-db/i18n/categories.af.i18n.json",
    "store-db/i18n/categories.az.i18n.json",
    "store-db/i18n/categories.be.i18n.json",
    "store-db/i18n/categories.bn.i18n.json",
    "store-db/i18n/categories.bs.i18n.json",
    "store-db/i18n/categories.ca.i18n.json",
    "store-db/i18n/categories.eu.i18n.json",
    "store-db/i18n/categories.lb.i18n.json",
    "store-db/i18n/categories.mk.i18n.json",
    "store-db/i18n/categories.ne.i18n.json",
    "store-db/i18n/categories.nb.i18n.json",
    "store-db/i18n/categories.sq.i18n.json",
    "store-db/i18n/categories.ta.i18n.json",
    "store-db/i18n/categories.uz.i18n.json",
    "store-db/i18n/categories.hy.i18n.json",
    "store-db/i18n/categories.kk.i18n.json",
    "store-db/i18n/categories.ky.i18n.json",
    "store-db/i18n/categories.ms.i18n.json",
    "store-db/i18n/categories.tg.i18n.json"
  ], both);

  // Calculated due dates
  api.addFiles([
    "store-db/plugins/calculated-due-dates/i18n/en.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ar.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/es.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/fr.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/he.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ja.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/km.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ko.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/pt-PT.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/pt-BR.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/vi.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ru.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/yi.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/it.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/de.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/hi.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/tr.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/el.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/da.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/fi.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/nl.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/sv.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/th.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/id.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/pl.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/cs.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/hu.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ro.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/sk.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/uk.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/bg.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/hr.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/sr.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/sl.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/et.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/lv.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/lt.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/am.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/zh-CN.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/zh-TW.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/sw.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/af.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/az.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/be.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/bn.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/bs.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ca.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/eu.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/lb.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/mk.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ne.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/nb.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/sq.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ta.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/uz.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/hy.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/kk.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ky.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/ms.i18n.json",
    "store-db/plugins/calculated-due-dates/i18n/tg.i18n.json"
  ], both);

  // Gantt Chart
  api.addFiles([
    "store-db/plugins/gantt-chart/i18n/en.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ar.i18n.json",
    "store-db/plugins/gantt-chart/i18n/es.i18n.json",
    "store-db/plugins/gantt-chart/i18n/fr.i18n.json",
    "store-db/plugins/gantt-chart/i18n/he.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ja.i18n.json",
    "store-db/plugins/gantt-chart/i18n/km.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ko.i18n.json",
    "store-db/plugins/gantt-chart/i18n/pt-PT.i18n.json",
    "store-db/plugins/gantt-chart/i18n/pt-BR.i18n.json",
    "store-db/plugins/gantt-chart/i18n/vi.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ru.i18n.json",
    "store-db/plugins/gantt-chart/i18n/yi.i18n.json",
    "store-db/plugins/gantt-chart/i18n/it.i18n.json",
    "store-db/plugins/gantt-chart/i18n/de.i18n.json",
    "store-db/plugins/gantt-chart/i18n/hi.i18n.json",
    "store-db/plugins/gantt-chart/i18n/tr.i18n.json",
    "store-db/plugins/gantt-chart/i18n/el.i18n.json",
    "store-db/plugins/gantt-chart/i18n/da.i18n.json",
    "store-db/plugins/gantt-chart/i18n/fi.i18n.json",
    "store-db/plugins/gantt-chart/i18n/nl.i18n.json",
    "store-db/plugins/gantt-chart/i18n/sv.i18n.json",
    "store-db/plugins/gantt-chart/i18n/th.i18n.json",
    "store-db/plugins/gantt-chart/i18n/id.i18n.json",
    "store-db/plugins/gantt-chart/i18n/pl.i18n.json",
    "store-db/plugins/gantt-chart/i18n/cs.i18n.json",
    "store-db/plugins/gantt-chart/i18n/hu.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ro.i18n.json",
    "store-db/plugins/gantt-chart/i18n/sk.i18n.json",
    "store-db/plugins/gantt-chart/i18n/uk.i18n.json",
    "store-db/plugins/gantt-chart/i18n/bg.i18n.json",
    "store-db/plugins/gantt-chart/i18n/hr.i18n.json",
    "store-db/plugins/gantt-chart/i18n/sr.i18n.json",
    "store-db/plugins/gantt-chart/i18n/sl.i18n.json",
    "store-db/plugins/gantt-chart/i18n/et.i18n.json",
    "store-db/plugins/gantt-chart/i18n/lv.i18n.json",
    "store-db/plugins/gantt-chart/i18n/lt.i18n.json",
    "store-db/plugins/gantt-chart/i18n/am.i18n.json",
    "store-db/plugins/gantt-chart/i18n/zh-CN.i18n.json",
    "store-db/plugins/gantt-chart/i18n/zh-TW.i18n.json",
    "store-db/plugins/gantt-chart/i18n/sw.i18n.json",
    "store-db/plugins/gantt-chart/i18n/af.i18n.json",
    "store-db/plugins/gantt-chart/i18n/az.i18n.json",
    "store-db/plugins/gantt-chart/i18n/be.i18n.json",
    "store-db/plugins/gantt-chart/i18n/bn.i18n.json",
    "store-db/plugins/gantt-chart/i18n/bs.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ca.i18n.json",
    "store-db/plugins/gantt-chart/i18n/eu.i18n.json",
    "store-db/plugins/gantt-chart/i18n/lb.i18n.json",
    "store-db/plugins/gantt-chart/i18n/mk.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ne.i18n.json",
    "store-db/plugins/gantt-chart/i18n/nb.i18n.json",
    "store-db/plugins/gantt-chart/i18n/sq.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ta.i18n.json",
    "store-db/plugins/gantt-chart/i18n/uz.i18n.json",
    "store-db/plugins/gantt-chart/i18n/hy.i18n.json",
    "store-db/plugins/gantt-chart/i18n/kk.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ky.i18n.json",
    "store-db/plugins/gantt-chart/i18n/ms.i18n.json",
    "store-db/plugins/gantt-chart/i18n/tg.i18n.json"
  ], both);

  // Activities
  api.addFiles([
    "store-db/plugins/justdo-activity/i18n/en.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ar.i18n.json",
    "store-db/plugins/justdo-activity/i18n/es.i18n.json",
    "store-db/plugins/justdo-activity/i18n/fr.i18n.json",
    "store-db/plugins/justdo-activity/i18n/he.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ja.i18n.json",
    "store-db/plugins/justdo-activity/i18n/km.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ko.i18n.json",
    "store-db/plugins/justdo-activity/i18n/pt-PT.i18n.json",
    "store-db/plugins/justdo-activity/i18n/pt-BR.i18n.json",
    "store-db/plugins/justdo-activity/i18n/vi.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ru.i18n.json",
    "store-db/plugins/justdo-activity/i18n/yi.i18n.json",
    "store-db/plugins/justdo-activity/i18n/it.i18n.json",
    "store-db/plugins/justdo-activity/i18n/de.i18n.json",
    "store-db/plugins/justdo-activity/i18n/hi.i18n.json",
    "store-db/plugins/justdo-activity/i18n/tr.i18n.json",
    "store-db/plugins/justdo-activity/i18n/el.i18n.json",
    "store-db/plugins/justdo-activity/i18n/da.i18n.json",
    "store-db/plugins/justdo-activity/i18n/fi.i18n.json",
    "store-db/plugins/justdo-activity/i18n/nl.i18n.json",
    "store-db/plugins/justdo-activity/i18n/sv.i18n.json",
    "store-db/plugins/justdo-activity/i18n/th.i18n.json",
    "store-db/plugins/justdo-activity/i18n/id.i18n.json",
    "store-db/plugins/justdo-activity/i18n/pl.i18n.json",
    "store-db/plugins/justdo-activity/i18n/cs.i18n.json",
    "store-db/plugins/justdo-activity/i18n/hu.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ro.i18n.json",
    "store-db/plugins/justdo-activity/i18n/sk.i18n.json",
    "store-db/plugins/justdo-activity/i18n/uk.i18n.json",
    "store-db/plugins/justdo-activity/i18n/bg.i18n.json",
    "store-db/plugins/justdo-activity/i18n/hr.i18n.json",
    "store-db/plugins/justdo-activity/i18n/sr.i18n.json",
    "store-db/plugins/justdo-activity/i18n/sl.i18n.json",
    "store-db/plugins/justdo-activity/i18n/et.i18n.json",
    "store-db/plugins/justdo-activity/i18n/lv.i18n.json",
    "store-db/plugins/justdo-activity/i18n/lt.i18n.json",
    "store-db/plugins/justdo-activity/i18n/am.i18n.json",
    "store-db/plugins/justdo-activity/i18n/zh-CN.i18n.json",
    "store-db/plugins/justdo-activity/i18n/zh-TW.i18n.json",
    "store-db/plugins/justdo-activity/i18n/sw.i18n.json",
    "store-db/plugins/justdo-activity/i18n/af.i18n.json",
    "store-db/plugins/justdo-activity/i18n/az.i18n.json",
    "store-db/plugins/justdo-activity/i18n/be.i18n.json",
    "store-db/plugins/justdo-activity/i18n/bn.i18n.json",
    "store-db/plugins/justdo-activity/i18n/bs.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ca.i18n.json",
    "store-db/plugins/justdo-activity/i18n/eu.i18n.json",
    "store-db/plugins/justdo-activity/i18n/lb.i18n.json",
    "store-db/plugins/justdo-activity/i18n/mk.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ne.i18n.json",
    "store-db/plugins/justdo-activity/i18n/nb.i18n.json",
    "store-db/plugins/justdo-activity/i18n/sq.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ta.i18n.json",
    "store-db/plugins/justdo-activity/i18n/uz.i18n.json",
    "store-db/plugins/justdo-activity/i18n/hy.i18n.json",
    "store-db/plugins/justdo-activity/i18n/kk.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ky.i18n.json",
    "store-db/plugins/justdo-activity/i18n/ms.i18n.json",
    "store-db/plugins/justdo-activity/i18n/tg.i18n.json"
  ], both);

  // Calendar View
  api.addFiles([
    "store-db/plugins/justdo-calendar-view/i18n/en.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ar.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/es.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/fr.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/he.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ja.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/km.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ko.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/pt-PT.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/pt-BR.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/vi.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ru.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/yi.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/it.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/de.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/hi.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/tr.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/el.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/da.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/fi.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/nl.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/sv.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/th.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/id.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/pl.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/cs.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/hu.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ro.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/sk.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/uk.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/bg.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/hr.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/sr.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/sl.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/et.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/lv.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/lt.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/am.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/zh-CN.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/zh-TW.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/sw.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/af.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/az.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/be.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/bn.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/bs.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ca.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/eu.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/lb.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/mk.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ne.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/nb.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/sq.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ta.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/uz.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/hy.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/kk.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ky.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/ms.i18n.json",
    "store-db/plugins/justdo-calendar-view/i18n/tg.i18n.json"
  ], both);

  // Checklist
  api.addFiles([
    "store-db/plugins/justdo-checklist/i18n/en.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ar.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/es.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/fr.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/he.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ja.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/km.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ko.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/pt-PT.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/pt-BR.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/vi.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ru.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/yi.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/it.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/de.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/hi.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/tr.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/el.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/da.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/fi.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/nl.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/sv.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/th.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/id.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/pl.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/cs.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/hu.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ro.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/sk.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/uk.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/bg.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/hr.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/sr.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/sl.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/et.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/lv.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/lt.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/am.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/zh-CN.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/zh-TW.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/sw.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/af.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/az.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/be.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/bn.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/bs.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ca.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/eu.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/lb.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/mk.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ne.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/nb.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/sq.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ta.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/uz.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/hy.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/kk.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ky.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/ms.i18n.json",
    "store-db/plugins/justdo-checklist/i18n/tg.i18n.json"
  ], both);

  // Formulas
  api.addFiles([
    "store-db/plugins/justdo-formulas/i18n/en.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ar.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/es.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/fr.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/he.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ja.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/km.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ko.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/pt-PT.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/pt-BR.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/vi.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ru.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/yi.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/it.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/de.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/hi.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/tr.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/el.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/da.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/fi.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/nl.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/sv.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/th.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/id.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/pl.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/cs.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/hu.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ro.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/sk.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/uk.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/bg.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/hr.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/sr.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/sl.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/et.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/lv.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/lt.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/am.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/zh-CN.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/zh-TW.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/sw.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/af.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/az.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/be.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/bn.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/bs.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ca.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/eu.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/lb.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/mk.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ne.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/nb.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/sq.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ta.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/uz.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/hy.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/kk.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ky.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/ms.i18n.json",
    "store-db/plugins/justdo-formulas/i18n/tg.i18n.json"
  ], both);

  // Time Tracker
  api.addFiles([
    "store-db/plugins/justdo-time-tracker/i18n/en.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ar.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/es.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/fr.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/he.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ja.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/km.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ko.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/pt-PT.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/pt-BR.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/vi.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ru.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/yi.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/it.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/de.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/hi.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/tr.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/el.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/da.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/fi.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/nl.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/sv.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/th.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/id.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/pl.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/cs.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/hu.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ro.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/sk.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/uk.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/bg.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/hr.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/sr.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/sl.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/et.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/lv.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/lt.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/am.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/zh-CN.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/zh-TW.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/sw.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/af.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/az.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/be.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/bn.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/bs.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ca.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/eu.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/lb.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/mk.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ne.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/nb.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/sq.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ta.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/uz.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/hy.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/kk.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ky.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/ms.i18n.json",
    "store-db/plugins/justdo-time-tracker/i18n/tg.i18n.json"
  ], both);

  // MailDo
  api.addFiles([
    "store-db/plugins/maildo/i18n/en.i18n.json",
    "store-db/plugins/maildo/i18n/ar.i18n.json",
    "store-db/plugins/maildo/i18n/es.i18n.json",
    "store-db/plugins/maildo/i18n/fr.i18n.json",
    "store-db/plugins/maildo/i18n/he.i18n.json",
    "store-db/plugins/maildo/i18n/ja.i18n.json",
    "store-db/plugins/maildo/i18n/km.i18n.json",
    "store-db/plugins/maildo/i18n/ko.i18n.json",
    "store-db/plugins/maildo/i18n/pt-PT.i18n.json",
    "store-db/plugins/maildo/i18n/pt-BR.i18n.json",
    "store-db/plugins/maildo/i18n/vi.i18n.json",
    "store-db/plugins/maildo/i18n/ru.i18n.json",
    "store-db/plugins/maildo/i18n/yi.i18n.json",
    "store-db/plugins/maildo/i18n/it.i18n.json",
    "store-db/plugins/maildo/i18n/de.i18n.json",
    "store-db/plugins/maildo/i18n/hi.i18n.json",
    "store-db/plugins/maildo/i18n/tr.i18n.json",
    "store-db/plugins/maildo/i18n/el.i18n.json",
    "store-db/plugins/maildo/i18n/da.i18n.json",
    "store-db/plugins/maildo/i18n/fi.i18n.json",
    "store-db/plugins/maildo/i18n/nl.i18n.json",
    "store-db/plugins/maildo/i18n/sv.i18n.json",
    "store-db/plugins/maildo/i18n/th.i18n.json",
    "store-db/plugins/maildo/i18n/id.i18n.json",
    "store-db/plugins/maildo/i18n/pl.i18n.json",
    "store-db/plugins/maildo/i18n/cs.i18n.json",
    "store-db/plugins/maildo/i18n/hu.i18n.json",
    "store-db/plugins/maildo/i18n/ro.i18n.json",
    "store-db/plugins/maildo/i18n/sk.i18n.json",
    "store-db/plugins/maildo/i18n/uk.i18n.json",
    "store-db/plugins/maildo/i18n/bg.i18n.json",
    "store-db/plugins/maildo/i18n/hr.i18n.json",
    "store-db/plugins/maildo/i18n/sr.i18n.json",
    "store-db/plugins/maildo/i18n/sl.i18n.json",
    "store-db/plugins/maildo/i18n/et.i18n.json",
    "store-db/plugins/maildo/i18n/lv.i18n.json",
    "store-db/plugins/maildo/i18n/lt.i18n.json",
    "store-db/plugins/maildo/i18n/am.i18n.json",
    "store-db/plugins/maildo/i18n/zh-CN.i18n.json",
    "store-db/plugins/maildo/i18n/zh-TW.i18n.json",
    "store-db/plugins/maildo/i18n/sw.i18n.json",
    "store-db/plugins/maildo/i18n/af.i18n.json",
    "store-db/plugins/maildo/i18n/az.i18n.json",
    "store-db/plugins/maildo/i18n/be.i18n.json",
    "store-db/plugins/maildo/i18n/bn.i18n.json",
    "store-db/plugins/maildo/i18n/bs.i18n.json",
    "store-db/plugins/maildo/i18n/ca.i18n.json",
    "store-db/plugins/maildo/i18n/eu.i18n.json",
    "store-db/plugins/maildo/i18n/lb.i18n.json",
    "store-db/plugins/maildo/i18n/mk.i18n.json",
    "store-db/plugins/maildo/i18n/ne.i18n.json",
    "store-db/plugins/maildo/i18n/nb.i18n.json",
    "store-db/plugins/maildo/i18n/sq.i18n.json",
    "store-db/plugins/maildo/i18n/ta.i18n.json",
    "store-db/plugins/maildo/i18n/uz.i18n.json",
    "store-db/plugins/maildo/i18n/hy.i18n.json",
    "store-db/plugins/maildo/i18n/kk.i18n.json",
    "store-db/plugins/maildo/i18n/ky.i18n.json",
    "store-db/plugins/maildo/i18n/ms.i18n.json",
    "store-db/plugins/maildo/i18n/tg.i18n.json"
  ], both);

  // Meetings
  api.addFiles([
    "store-db/plugins/meetings/i18n/en.i18n.json",
    "store-db/plugins/meetings/i18n/ar.i18n.json",
    "store-db/plugins/meetings/i18n/es.i18n.json",
    "store-db/plugins/meetings/i18n/fr.i18n.json",
    "store-db/plugins/meetings/i18n/he.i18n.json",
    "store-db/plugins/meetings/i18n/ja.i18n.json",
    "store-db/plugins/meetings/i18n/km.i18n.json",
    "store-db/plugins/meetings/i18n/ko.i18n.json",
    "store-db/plugins/meetings/i18n/pt-PT.i18n.json",
    "store-db/plugins/meetings/i18n/pt-BR.i18n.json",
    "store-db/plugins/meetings/i18n/vi.i18n.json",
    "store-db/plugins/meetings/i18n/ru.i18n.json",
    "store-db/plugins/meetings/i18n/yi.i18n.json",
    "store-db/plugins/meetings/i18n/it.i18n.json",
    "store-db/plugins/meetings/i18n/de.i18n.json",
    "store-db/plugins/meetings/i18n/hi.i18n.json",
    "store-db/plugins/meetings/i18n/tr.i18n.json",
    "store-db/plugins/meetings/i18n/el.i18n.json",
    "store-db/plugins/meetings/i18n/da.i18n.json",
    "store-db/plugins/meetings/i18n/fi.i18n.json",
    "store-db/plugins/meetings/i18n/nl.i18n.json",
    "store-db/plugins/meetings/i18n/sv.i18n.json",
    "store-db/plugins/meetings/i18n/th.i18n.json",
    "store-db/plugins/meetings/i18n/id.i18n.json",
    "store-db/plugins/meetings/i18n/pl.i18n.json",
    "store-db/plugins/meetings/i18n/cs.i18n.json",
    "store-db/plugins/meetings/i18n/hu.i18n.json",
    "store-db/plugins/meetings/i18n/ro.i18n.json",
    "store-db/plugins/meetings/i18n/sk.i18n.json",
    "store-db/plugins/meetings/i18n/uk.i18n.json",
    "store-db/plugins/meetings/i18n/bg.i18n.json",
    "store-db/plugins/meetings/i18n/hr.i18n.json",
    "store-db/plugins/meetings/i18n/sr.i18n.json",
    "store-db/plugins/meetings/i18n/sl.i18n.json",
    "store-db/plugins/meetings/i18n/et.i18n.json",
    "store-db/plugins/meetings/i18n/lv.i18n.json",
    "store-db/plugins/meetings/i18n/lt.i18n.json",
    "store-db/plugins/meetings/i18n/am.i18n.json",
    "store-db/plugins/meetings/i18n/zh-CN.i18n.json",
    "store-db/plugins/meetings/i18n/zh-TW.i18n.json",
    "store-db/plugins/meetings/i18n/sw.i18n.json",
    "store-db/plugins/meetings/i18n/af.i18n.json",
    "store-db/plugins/meetings/i18n/az.i18n.json",
    "store-db/plugins/meetings/i18n/be.i18n.json",
    "store-db/plugins/meetings/i18n/bn.i18n.json",
    "store-db/plugins/meetings/i18n/bs.i18n.json",
    "store-db/plugins/meetings/i18n/ca.i18n.json",
    "store-db/plugins/meetings/i18n/eu.i18n.json",
    "store-db/plugins/meetings/i18n/lb.i18n.json",
    "store-db/plugins/meetings/i18n/mk.i18n.json",
    "store-db/plugins/meetings/i18n/ne.i18n.json",
    "store-db/plugins/meetings/i18n/nb.i18n.json",
    "store-db/plugins/meetings/i18n/sq.i18n.json",
    "store-db/plugins/meetings/i18n/ta.i18n.json",
    "store-db/plugins/meetings/i18n/uz.i18n.json",
    "store-db/plugins/meetings/i18n/hy.i18n.json",
    "store-db/plugins/meetings/i18n/kk.i18n.json",
    "store-db/plugins/meetings/i18n/ky.i18n.json",
    "store-db/plugins/meetings/i18n/ms.i18n.json",
    "store-db/plugins/meetings/i18n/tg.i18n.json"
  ], both);

   // Private follow up
   api.addFiles([
    "store-db/plugins/private-follow-up/i18n/en.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ar.i18n.json",
    "store-db/plugins/private-follow-up/i18n/es.i18n.json",
    "store-db/plugins/private-follow-up/i18n/fr.i18n.json",
    "store-db/plugins/private-follow-up/i18n/he.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ja.i18n.json",
    "store-db/plugins/private-follow-up/i18n/km.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ko.i18n.json",
    "store-db/plugins/private-follow-up/i18n/pt-PT.i18n.json",
    "store-db/plugins/private-follow-up/i18n/pt-BR.i18n.json",
    "store-db/plugins/private-follow-up/i18n/vi.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ru.i18n.json",
    "store-db/plugins/private-follow-up/i18n/yi.i18n.json",
    "store-db/plugins/private-follow-up/i18n/it.i18n.json",
    "store-db/plugins/private-follow-up/i18n/de.i18n.json",
    "store-db/plugins/private-follow-up/i18n/hi.i18n.json",
    "store-db/plugins/private-follow-up/i18n/tr.i18n.json",
    "store-db/plugins/private-follow-up/i18n/el.i18n.json",
    "store-db/plugins/private-follow-up/i18n/da.i18n.json",
    "store-db/plugins/private-follow-up/i18n/fi.i18n.json",
    "store-db/plugins/private-follow-up/i18n/nl.i18n.json",
    "store-db/plugins/private-follow-up/i18n/sv.i18n.json",
    "store-db/plugins/private-follow-up/i18n/th.i18n.json",
    "store-db/plugins/private-follow-up/i18n/id.i18n.json",
    "store-db/plugins/private-follow-up/i18n/pl.i18n.json",
    "store-db/plugins/private-follow-up/i18n/cs.i18n.json",
    "store-db/plugins/private-follow-up/i18n/hu.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ro.i18n.json",
    "store-db/plugins/private-follow-up/i18n/sk.i18n.json",
    "store-db/plugins/private-follow-up/i18n/uk.i18n.json",
    "store-db/plugins/private-follow-up/i18n/bg.i18n.json",
    "store-db/plugins/private-follow-up/i18n/hr.i18n.json",
    "store-db/plugins/private-follow-up/i18n/sr.i18n.json",
    "store-db/plugins/private-follow-up/i18n/sl.i18n.json",
    "store-db/plugins/private-follow-up/i18n/et.i18n.json",
    "store-db/plugins/private-follow-up/i18n/lv.i18n.json",
    "store-db/plugins/private-follow-up/i18n/lt.i18n.json",
    "store-db/plugins/private-follow-up/i18n/am.i18n.json",
    "store-db/plugins/private-follow-up/i18n/zh-CN.i18n.json",
    "store-db/plugins/private-follow-up/i18n/zh-TW.i18n.json",
    "store-db/plugins/private-follow-up/i18n/sw.i18n.json",
    "store-db/plugins/private-follow-up/i18n/af.i18n.json",
    "store-db/plugins/private-follow-up/i18n/az.i18n.json",
    "store-db/plugins/private-follow-up/i18n/be.i18n.json",
    "store-db/plugins/private-follow-up/i18n/bn.i18n.json",
    "store-db/plugins/private-follow-up/i18n/bs.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ca.i18n.json",
    "store-db/plugins/private-follow-up/i18n/eu.i18n.json",
    "store-db/plugins/private-follow-up/i18n/lb.i18n.json",
    "store-db/plugins/private-follow-up/i18n/mk.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ne.i18n.json",
    "store-db/plugins/private-follow-up/i18n/nb.i18n.json",
    "store-db/plugins/private-follow-up/i18n/sq.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ta.i18n.json",
    "store-db/plugins/private-follow-up/i18n/uz.i18n.json",
    "store-db/plugins/private-follow-up/i18n/hy.i18n.json",
    "store-db/plugins/private-follow-up/i18n/kk.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ky.i18n.json",
    "store-db/plugins/private-follow-up/i18n/ms.i18n.json",
    "store-db/plugins/private-follow-up/i18n/tg.i18n.json"
  ], both);
  
  // Resource Management
  api.addFiles([
    "store-db/plugins/resource-management/i18n/en.i18n.json",
    "store-db/plugins/resource-management/i18n/ar.i18n.json",
    "store-db/plugins/resource-management/i18n/es.i18n.json",
    "store-db/plugins/resource-management/i18n/fr.i18n.json",
    "store-db/plugins/resource-management/i18n/he.i18n.json",
    "store-db/plugins/resource-management/i18n/ja.i18n.json",
    "store-db/plugins/resource-management/i18n/km.i18n.json",
    "store-db/plugins/resource-management/i18n/ko.i18n.json",
    "store-db/plugins/resource-management/i18n/pt-PT.i18n.json",
    "store-db/plugins/resource-management/i18n/pt-BR.i18n.json",
    "store-db/plugins/resource-management/i18n/vi.i18n.json",
    "store-db/plugins/resource-management/i18n/ru.i18n.json",
    "store-db/plugins/resource-management/i18n/yi.i18n.json",
    "store-db/plugins/resource-management/i18n/it.i18n.json",
    "store-db/plugins/resource-management/i18n/de.i18n.json",
    "store-db/plugins/resource-management/i18n/hi.i18n.json",
    "store-db/plugins/resource-management/i18n/tr.i18n.json",
    "store-db/plugins/resource-management/i18n/el.i18n.json",
    "store-db/plugins/resource-management/i18n/da.i18n.json",
    "store-db/plugins/resource-management/i18n/fi.i18n.json",
    "store-db/plugins/resource-management/i18n/nl.i18n.json",
    "store-db/plugins/resource-management/i18n/sv.i18n.json",
    "store-db/plugins/resource-management/i18n/th.i18n.json",
    "store-db/plugins/resource-management/i18n/id.i18n.json",
    "store-db/plugins/resource-management/i18n/pl.i18n.json",
    "store-db/plugins/resource-management/i18n/cs.i18n.json",
    "store-db/plugins/resource-management/i18n/hu.i18n.json",
    "store-db/plugins/resource-management/i18n/ro.i18n.json",
    "store-db/plugins/resource-management/i18n/sk.i18n.json",
    "store-db/plugins/resource-management/i18n/uk.i18n.json",
    "store-db/plugins/resource-management/i18n/bg.i18n.json",
    "store-db/plugins/resource-management/i18n/hr.i18n.json",
    "store-db/plugins/resource-management/i18n/sr.i18n.json",
    "store-db/plugins/resource-management/i18n/sl.i18n.json",
    "store-db/plugins/resource-management/i18n/et.i18n.json",
    "store-db/plugins/resource-management/i18n/lv.i18n.json",
    "store-db/plugins/resource-management/i18n/lt.i18n.json",
    "store-db/plugins/resource-management/i18n/am.i18n.json",
    "store-db/plugins/resource-management/i18n/zh-CN.i18n.json",
    "store-db/plugins/resource-management/i18n/zh-TW.i18n.json",
    "store-db/plugins/resource-management/i18n/sw.i18n.json",
    "store-db/plugins/resource-management/i18n/af.i18n.json",
    "store-db/plugins/resource-management/i18n/az.i18n.json",
    "store-db/plugins/resource-management/i18n/be.i18n.json",
    "store-db/plugins/resource-management/i18n/bn.i18n.json",
    "store-db/plugins/resource-management/i18n/bs.i18n.json",
    "store-db/plugins/resource-management/i18n/ca.i18n.json",
    "store-db/plugins/resource-management/i18n/eu.i18n.json",
    "store-db/plugins/resource-management/i18n/lb.i18n.json",
    "store-db/plugins/resource-management/i18n/mk.i18n.json",
    "store-db/plugins/resource-management/i18n/ne.i18n.json",
    "store-db/plugins/resource-management/i18n/nb.i18n.json",
    "store-db/plugins/resource-management/i18n/sq.i18n.json",
    "store-db/plugins/resource-management/i18n/ta.i18n.json",
    "store-db/plugins/resource-management/i18n/uz.i18n.json",
    "store-db/plugins/resource-management/i18n/hy.i18n.json",
    "store-db/plugins/resource-management/i18n/kk.i18n.json",
    "store-db/plugins/resource-management/i18n/ky.i18n.json",
    "store-db/plugins/resource-management/i18n/ms.i18n.json",
    "store-db/plugins/resource-management/i18n/tg.i18n.json"
  ], both);
  
  // Risk Management
  api.addFiles([
    "store-db/plugins/risk-management/i18n/en.i18n.json",
    "store-db/plugins/risk-management/i18n/ar.i18n.json",
    "store-db/plugins/risk-management/i18n/es.i18n.json",
    "store-db/plugins/risk-management/i18n/fr.i18n.json",
    "store-db/plugins/risk-management/i18n/he.i18n.json",
    "store-db/plugins/risk-management/i18n/ja.i18n.json",
    "store-db/plugins/risk-management/i18n/km.i18n.json",
    "store-db/plugins/risk-management/i18n/ko.i18n.json",
    "store-db/plugins/risk-management/i18n/pt-PT.i18n.json",
    "store-db/plugins/risk-management/i18n/pt-BR.i18n.json",
    "store-db/plugins/risk-management/i18n/vi.i18n.json",
    "store-db/plugins/risk-management/i18n/ru.i18n.json",
    "store-db/plugins/risk-management/i18n/yi.i18n.json",
    "store-db/plugins/risk-management/i18n/it.i18n.json",
    "store-db/plugins/risk-management/i18n/de.i18n.json",
    "store-db/plugins/risk-management/i18n/hi.i18n.json",
    "store-db/plugins/risk-management/i18n/tr.i18n.json",
    "store-db/plugins/risk-management/i18n/el.i18n.json",
    "store-db/plugins/risk-management/i18n/da.i18n.json",
    "store-db/plugins/risk-management/i18n/fi.i18n.json",
    "store-db/plugins/risk-management/i18n/nl.i18n.json",
    "store-db/plugins/risk-management/i18n/sv.i18n.json",
    "store-db/plugins/risk-management/i18n/th.i18n.json",
    "store-db/plugins/risk-management/i18n/id.i18n.json",
    "store-db/plugins/risk-management/i18n/pl.i18n.json",
    "store-db/plugins/risk-management/i18n/cs.i18n.json",
    "store-db/plugins/risk-management/i18n/hu.i18n.json",
    "store-db/plugins/risk-management/i18n/ro.i18n.json",
    "store-db/plugins/risk-management/i18n/sk.i18n.json",
    "store-db/plugins/risk-management/i18n/uk.i18n.json",
    "store-db/plugins/risk-management/i18n/bg.i18n.json",
    "store-db/plugins/risk-management/i18n/hr.i18n.json",
    "store-db/plugins/risk-management/i18n/sr.i18n.json",
    "store-db/plugins/risk-management/i18n/sl.i18n.json",
    "store-db/plugins/risk-management/i18n/et.i18n.json",
    "store-db/plugins/risk-management/i18n/lv.i18n.json",
    "store-db/plugins/risk-management/i18n/lt.i18n.json",
    "store-db/plugins/risk-management/i18n/am.i18n.json",
    "store-db/plugins/risk-management/i18n/zh-CN.i18n.json",
    "store-db/plugins/risk-management/i18n/zh-TW.i18n.json",
    "store-db/plugins/risk-management/i18n/sw.i18n.json",
    "store-db/plugins/risk-management/i18n/af.i18n.json",
    "store-db/plugins/risk-management/i18n/az.i18n.json",
    "store-db/plugins/risk-management/i18n/be.i18n.json",
    "store-db/plugins/risk-management/i18n/bn.i18n.json",
    "store-db/plugins/risk-management/i18n/bs.i18n.json",
    "store-db/plugins/risk-management/i18n/ca.i18n.json",
    "store-db/plugins/risk-management/i18n/eu.i18n.json",
    "store-db/plugins/risk-management/i18n/lb.i18n.json",
    "store-db/plugins/risk-management/i18n/mk.i18n.json",
    "store-db/plugins/risk-management/i18n/ne.i18n.json",
    "store-db/plugins/risk-management/i18n/nb.i18n.json",
    "store-db/plugins/risk-management/i18n/sq.i18n.json",
    "store-db/plugins/risk-management/i18n/ta.i18n.json",
    "store-db/plugins/risk-management/i18n/uz.i18n.json",
    "store-db/plugins/risk-management/i18n/hy.i18n.json",
    "store-db/plugins/risk-management/i18n/kk.i18n.json",
    "store-db/plugins/risk-management/i18n/ky.i18n.json",
    "store-db/plugins/risk-management/i18n/ms.i18n.json",
    "store-db/plugins/risk-management/i18n/tg.i18n.json"
  ], both);

  // Row Styling
  api.addFiles([
    "store-db/plugins/rows-styling/i18n/en.i18n.json",
    "store-db/plugins/rows-styling/i18n/ar.i18n.json",
    "store-db/plugins/rows-styling/i18n/es.i18n.json",
    "store-db/plugins/rows-styling/i18n/fr.i18n.json",
    "store-db/plugins/rows-styling/i18n/he.i18n.json",
    "store-db/plugins/rows-styling/i18n/ja.i18n.json",
    "store-db/plugins/rows-styling/i18n/km.i18n.json",
    "store-db/plugins/rows-styling/i18n/ko.i18n.json",
    "store-db/plugins/rows-styling/i18n/pt-PT.i18n.json",
    "store-db/plugins/rows-styling/i18n/pt-BR.i18n.json",
    "store-db/plugins/rows-styling/i18n/vi.i18n.json",
    "store-db/plugins/rows-styling/i18n/ru.i18n.json",
    "store-db/plugins/rows-styling/i18n/yi.i18n.json",
    "store-db/plugins/rows-styling/i18n/it.i18n.json",
    "store-db/plugins/rows-styling/i18n/de.i18n.json",
    "store-db/plugins/rows-styling/i18n/hi.i18n.json",
    "store-db/plugins/rows-styling/i18n/tr.i18n.json",
    "store-db/plugins/rows-styling/i18n/el.i18n.json",
    "store-db/plugins/rows-styling/i18n/da.i18n.json",
    "store-db/plugins/rows-styling/i18n/fi.i18n.json",
    "store-db/plugins/rows-styling/i18n/nl.i18n.json",
    "store-db/plugins/rows-styling/i18n/sv.i18n.json",
    "store-db/plugins/rows-styling/i18n/th.i18n.json",
    "store-db/plugins/rows-styling/i18n/id.i18n.json",
    "store-db/plugins/rows-styling/i18n/pl.i18n.json",
    "store-db/plugins/rows-styling/i18n/cs.i18n.json",
    "store-db/plugins/rows-styling/i18n/hu.i18n.json",
    "store-db/plugins/rows-styling/i18n/ro.i18n.json",
    "store-db/plugins/rows-styling/i18n/sk.i18n.json",
    "store-db/plugins/rows-styling/i18n/uk.i18n.json",
    "store-db/plugins/rows-styling/i18n/bg.i18n.json",
    "store-db/plugins/rows-styling/i18n/hr.i18n.json",
    "store-db/plugins/rows-styling/i18n/sr.i18n.json",
    "store-db/plugins/rows-styling/i18n/sl.i18n.json",
    "store-db/plugins/rows-styling/i18n/et.i18n.json",
    "store-db/plugins/rows-styling/i18n/lv.i18n.json",
    "store-db/plugins/rows-styling/i18n/lt.i18n.json",
    "store-db/plugins/rows-styling/i18n/am.i18n.json",
    "store-db/plugins/rows-styling/i18n/zh-CN.i18n.json",
    "store-db/plugins/rows-styling/i18n/zh-TW.i18n.json",
    "store-db/plugins/rows-styling/i18n/sw.i18n.json",
    "store-db/plugins/rows-styling/i18n/af.i18n.json",
    "store-db/plugins/rows-styling/i18n/az.i18n.json",
    "store-db/plugins/rows-styling/i18n/be.i18n.json",
    "store-db/plugins/rows-styling/i18n/bn.i18n.json",
    "store-db/plugins/rows-styling/i18n/bs.i18n.json",
    "store-db/plugins/rows-styling/i18n/ca.i18n.json",
    "store-db/plugins/rows-styling/i18n/eu.i18n.json",
    "store-db/plugins/rows-styling/i18n/lb.i18n.json",
    "store-db/plugins/rows-styling/i18n/mk.i18n.json",
    "store-db/plugins/rows-styling/i18n/ne.i18n.json",
    "store-db/plugins/rows-styling/i18n/nb.i18n.json",
    "store-db/plugins/rows-styling/i18n/sq.i18n.json",
    "store-db/plugins/rows-styling/i18n/ta.i18n.json",
    "store-db/plugins/rows-styling/i18n/uz.i18n.json",
    "store-db/plugins/rows-styling/i18n/hy.i18n.json",
    "store-db/plugins/rows-styling/i18n/kk.i18n.json",
    "store-db/plugins/rows-styling/i18n/ky.i18n.json",
    "store-db/plugins/rows-styling/i18n/ms.i18n.json",
    "store-db/plugins/rows-styling/i18n/tg.i18n.json"
  ], both);

  // Task Copy
  api.addFiles([
    "store-db/plugins/task-copy/i18n/en.i18n.json",
    "store-db/plugins/task-copy/i18n/ar.i18n.json",
    "store-db/plugins/task-copy/i18n/es.i18n.json",
    "store-db/plugins/task-copy/i18n/fr.i18n.json",
    "store-db/plugins/task-copy/i18n/he.i18n.json",
    "store-db/plugins/task-copy/i18n/ja.i18n.json",
    "store-db/plugins/task-copy/i18n/km.i18n.json",
    "store-db/plugins/task-copy/i18n/ko.i18n.json",
    "store-db/plugins/task-copy/i18n/pt-PT.i18n.json",
    "store-db/plugins/task-copy/i18n/pt-BR.i18n.json",
    "store-db/plugins/task-copy/i18n/vi.i18n.json",
    "store-db/plugins/task-copy/i18n/ru.i18n.json",
    "store-db/plugins/task-copy/i18n/yi.i18n.json",
    "store-db/plugins/task-copy/i18n/it.i18n.json",
    "store-db/plugins/task-copy/i18n/de.i18n.json",
    "store-db/plugins/task-copy/i18n/hi.i18n.json",
    "store-db/plugins/task-copy/i18n/tr.i18n.json",
    "store-db/plugins/task-copy/i18n/el.i18n.json",
    "store-db/plugins/task-copy/i18n/da.i18n.json",
    "store-db/plugins/task-copy/i18n/fi.i18n.json",
    "store-db/plugins/task-copy/i18n/nl.i18n.json",
    "store-db/plugins/task-copy/i18n/sv.i18n.json",
    "store-db/plugins/task-copy/i18n/th.i18n.json",
    "store-db/plugins/task-copy/i18n/id.i18n.json",
    "store-db/plugins/task-copy/i18n/pl.i18n.json",
    "store-db/plugins/task-copy/i18n/cs.i18n.json",
    "store-db/plugins/task-copy/i18n/hu.i18n.json",
    "store-db/plugins/task-copy/i18n/ro.i18n.json",
    "store-db/plugins/task-copy/i18n/sk.i18n.json",
    "store-db/plugins/task-copy/i18n/uk.i18n.json",
    "store-db/plugins/task-copy/i18n/bg.i18n.json",
    "store-db/plugins/task-copy/i18n/hr.i18n.json",
    "store-db/plugins/task-copy/i18n/sr.i18n.json",
    "store-db/plugins/task-copy/i18n/sl.i18n.json",
    "store-db/plugins/task-copy/i18n/et.i18n.json",
    "store-db/plugins/task-copy/i18n/lv.i18n.json",
    "store-db/plugins/task-copy/i18n/lt.i18n.json",
    "store-db/plugins/task-copy/i18n/am.i18n.json",
    "store-db/plugins/task-copy/i18n/zh-CN.i18n.json",
    "store-db/plugins/task-copy/i18n/zh-TW.i18n.json",
    "store-db/plugins/task-copy/i18n/sw.i18n.json",
    "store-db/plugins/task-copy/i18n/af.i18n.json",
    "store-db/plugins/task-copy/i18n/az.i18n.json",
    "store-db/plugins/task-copy/i18n/be.i18n.json",
    "store-db/plugins/task-copy/i18n/bn.i18n.json",
    "store-db/plugins/task-copy/i18n/bs.i18n.json",
    "store-db/plugins/task-copy/i18n/ca.i18n.json",
    "store-db/plugins/task-copy/i18n/eu.i18n.json",
    "store-db/plugins/task-copy/i18n/lb.i18n.json",
    "store-db/plugins/task-copy/i18n/mk.i18n.json",
    "store-db/plugins/task-copy/i18n/ne.i18n.json",
    "store-db/plugins/task-copy/i18n/nb.i18n.json",
    "store-db/plugins/task-copy/i18n/sq.i18n.json",
    "store-db/plugins/task-copy/i18n/ta.i18n.json",
    "store-db/plugins/task-copy/i18n/uz.i18n.json",
    "store-db/plugins/task-copy/i18n/hy.i18n.json",
    "store-db/plugins/task-copy/i18n/kk.i18n.json",
    "store-db/plugins/task-copy/i18n/ky.i18n.json",
    "store-db/plugins/task-copy/i18n/ms.i18n.json",
    "store-db/plugins/task-copy/i18n/tg.i18n.json"
  ], both);  

  // Workload Planner
  api.addFiles([
    "store-db/plugins/workload-planner/i18n/en.i18n.json",
    "store-db/plugins/workload-planner/i18n/ar.i18n.json",
    "store-db/plugins/workload-planner/i18n/es.i18n.json",
    "store-db/plugins/workload-planner/i18n/fr.i18n.json",
    "store-db/plugins/workload-planner/i18n/he.i18n.json",
    "store-db/plugins/workload-planner/i18n/ja.i18n.json",
    "store-db/plugins/workload-planner/i18n/km.i18n.json",
    "store-db/plugins/workload-planner/i18n/ko.i18n.json",
    "store-db/plugins/workload-planner/i18n/pt-PT.i18n.json",
    "store-db/plugins/workload-planner/i18n/pt-BR.i18n.json",
    "store-db/plugins/workload-planner/i18n/vi.i18n.json",
    "store-db/plugins/workload-planner/i18n/ru.i18n.json",
    "store-db/plugins/workload-planner/i18n/yi.i18n.json",
    "store-db/plugins/workload-planner/i18n/it.i18n.json",
    "store-db/plugins/workload-planner/i18n/de.i18n.json",
    "store-db/plugins/workload-planner/i18n/hi.i18n.json",
    "store-db/plugins/workload-planner/i18n/tr.i18n.json",
    "store-db/plugins/workload-planner/i18n/el.i18n.json",
    "store-db/plugins/workload-planner/i18n/da.i18n.json",
    "store-db/plugins/workload-planner/i18n/fi.i18n.json",
    "store-db/plugins/workload-planner/i18n/nl.i18n.json",
    "store-db/plugins/workload-planner/i18n/sv.i18n.json",
    "store-db/plugins/workload-planner/i18n/th.i18n.json",
    "store-db/plugins/workload-planner/i18n/id.i18n.json",
    "store-db/plugins/workload-planner/i18n/pl.i18n.json",
    "store-db/plugins/workload-planner/i18n/cs.i18n.json",
    "store-db/plugins/workload-planner/i18n/hu.i18n.json",
    "store-db/plugins/workload-planner/i18n/ro.i18n.json",
    "store-db/plugins/workload-planner/i18n/sk.i18n.json",
    "store-db/plugins/workload-planner/i18n/uk.i18n.json",
    "store-db/plugins/workload-planner/i18n/bg.i18n.json",
    "store-db/plugins/workload-planner/i18n/hr.i18n.json",
    "store-db/plugins/workload-planner/i18n/sr.i18n.json",
    "store-db/plugins/workload-planner/i18n/sl.i18n.json",
    "store-db/plugins/workload-planner/i18n/et.i18n.json",
    "store-db/plugins/workload-planner/i18n/lv.i18n.json",
    "store-db/plugins/workload-planner/i18n/lt.i18n.json",
    "store-db/plugins/workload-planner/i18n/am.i18n.json",
    "store-db/plugins/workload-planner/i18n/zh-CN.i18n.json",
    "store-db/plugins/workload-planner/i18n/zh-TW.i18n.json",
    "store-db/plugins/workload-planner/i18n/sw.i18n.json",
    "store-db/plugins/workload-planner/i18n/af.i18n.json",
    "store-db/plugins/workload-planner/i18n/az.i18n.json",
    "store-db/plugins/workload-planner/i18n/be.i18n.json",
    "store-db/plugins/workload-planner/i18n/bn.i18n.json",
    "store-db/plugins/workload-planner/i18n/bs.i18n.json",
    "store-db/plugins/workload-planner/i18n/ca.i18n.json",
    "store-db/plugins/workload-planner/i18n/eu.i18n.json",
    "store-db/plugins/workload-planner/i18n/lb.i18n.json",
    "store-db/plugins/workload-planner/i18n/mk.i18n.json",
    "store-db/plugins/workload-planner/i18n/ne.i18n.json",
    "store-db/plugins/workload-planner/i18n/nb.i18n.json",
    "store-db/plugins/workload-planner/i18n/sq.i18n.json",
    "store-db/plugins/workload-planner/i18n/ta.i18n.json",
    "store-db/plugins/workload-planner/i18n/uz.i18n.json",
    "store-db/plugins/workload-planner/i18n/hy.i18n.json",
    "store-db/plugins/workload-planner/i18n/kk.i18n.json",
    "store-db/plugins/workload-planner/i18n/ky.i18n.json",
    "store-db/plugins/workload-planner/i18n/ms.i18n.json",
    "store-db/plugins/workload-planner/i18n/tg.i18n.json"
  ], both);

  api.export("JustdoPluginStore", both);
});
