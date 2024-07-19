Package.describe({
  name: "justdoinc:justdo-i18n",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-i18n"
});

Npm.depends({
  "excel4node": "1.8.2"
})

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
  //   }, 'justdoinc:justdo-i18n')
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
  api.use("iron:router@1.1.2", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);
  api.use("tap:i18n", both);
  api.use("momentjs:moment", both);
  api.use("rzymek:moment-locales", both);
  // Although we prefer tap:i18n, anti:i18n is used by other packages like meteor-accounts-ui-bootstrap-3
  api.use("anti:i18n@0.4.3", client, {weak: true}); 

  api.use("matb33:collection-hooks@0.8.4", both);
  api.use("meteorspark:app@0.3.0", both);

  api.use("reactive-var", both);
  api.use("tracker", client);
  api.use("astrocoders:handlebars-server@1.0.3", server);
  api.use("webapp", server);
  api.use("check", server)

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/router.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);

  api.addFiles("lib/client/modal-button-label/modal-button-label.html", client);

  api.addFiles("lib/client/lang-selector-dropdown/lang-selector-dropdown.sass", client);
  api.addFiles("lib/client/lang-selector-dropdown/lang-selector-dropdown.html", client);
  api.addFiles("lib/client/lang-selector-dropdown/lang-selector-dropdown.coffee", client);
  api.addFiles("lib/client/lang-selector-dropdown/user-preference-lang-selector.html", client);
  api.addFiles("lib/client/lang-selector-dropdown/user-preference-lang-selector.coffee", client);

  api.addFiles("lib/client/top-banner/top-banner.sass", client);
  api.addFiles("lib/client/top-banner/top-banner.html", client);
  api.addFiles("lib/client/top-banner/top-banner.coffee", client);

  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);
  
  // Always after templates
  // common
  api.addFiles([
    "i18n/common/en.i18n.json",
    "i18n/common/ar.i18n.json",
    "i18n/common/es.i18n.json",
    "i18n/common/fr.i18n.json",
    "i18n/common/he.i18n.json",
    "i18n/common/ja.i18n.json",
    "i18n/common/km.i18n.json",
    "i18n/common/ko.i18n.json",
    "i18n/common/pt-PT.i18n.json",
    "i18n/common/pt-BR.i18n.json",
    "i18n/common/vi.i18n.json",
    "i18n/common/ru.i18n.json",
    "i18n/common/yi.i18n.json",
    "i18n/common/it.i18n.json",
    "i18n/common/de.i18n.json",
    "i18n/common/hi.i18n.json",
    "i18n/common/tr.i18n.json",
    "i18n/common/el.i18n.json",
    "i18n/common/da.i18n.json",
    "i18n/common/fi.i18n.json",
    "i18n/common/nl.i18n.json",
    "i18n/common/sv.i18n.json",
    "i18n/common/th.i18n.json",
    "i18n/common/id.i18n.json",
    "i18n/common/pl.i18n.json",
    "i18n/common/cs.i18n.json",
    "i18n/common/hu.i18n.json",
    "i18n/common/ro.i18n.json",
    "i18n/common/sk.i18n.json",
    "i18n/common/uk.i18n.json",
    "i18n/common/bg.i18n.json",
    "i18n/common/hr.i18n.json",
    "i18n/common/sr.i18n.json",
    "i18n/common/sl.i18n.json",
    "i18n/common/et.i18n.json",
    "i18n/common/lv.i18n.json",
    "i18n/common/lt.i18n.json",
    "i18n/common/am.i18n.json",
    "i18n/common/zh-CN.i18n.json",
    "i18n/common/zh-TW.i18n.json",
    "i18n/common/sw.i18n.json",
    "i18n/common/af.i18n.json",
    "i18n/common/az.i18n.json",
    "i18n/common/be.i18n.json",
    "i18n/common/bn.i18n.json",
    "i18n/common/bs.i18n.json",
    "i18n/common/ca.i18n.json",
    "i18n/common/eu.i18n.json",
    "i18n/common/lb.i18n.json",
    "i18n/common/mk.i18n.json",
    "i18n/common/ne.i18n.json",
    "i18n/common/nb.i18n.json",
    "i18n/common/sq.i18n.json",
    "i18n/common/ta.i18n.json",
    "i18n/common/uz.i18n.json",
    "i18n/common/hy.i18n.json",
    "i18n/common/kk.i18n.json",
    "i18n/common/ky.i18n.json",
    "i18n/common/ms.i18n.json",
    "i18n/common/tg.i18n.json"
  ], both);

  // justdo-i18n
  api.addFiles([
    "i18n/justdo-i18n/justdo-i18n.en.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ar.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.es.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.fr.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.he.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ja.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.km.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ko.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.pt-PT.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.pt-BR.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.vi.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ru.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.yi.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.it.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.de.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.hi.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.tr.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.el.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.da.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.fi.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.nl.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sv.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.th.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.id.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.pl.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.cs.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.hu.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ro.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sk.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.uk.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.bg.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.hr.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sr.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sl.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.et.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.lv.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.lt.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.am.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.zh-CN.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.zh-TW.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sw.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.af.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.az.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.be.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.bn.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.bs.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ca.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.eu.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.lb.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.mk.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ne.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.nb.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sq.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ta.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.uz.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.hy.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.kk.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ky.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ms.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.tg.i18n.json"
  ], both);
  
  api.addFiles("i18n/loader/loader.en.i18n.json", both);
  api.addFiles("i18n/loader/loader.vi.i18n.json", both);
  api.addFiles("i18n/loader/loader.zh-TW.i18n.json", both);
  api.addFiles("i18n/title/title.en.i18n.json", both);
  api.addFiles("i18n/title/title.vi.i18n.json", both);
  api.addFiles("i18n/title/title.zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-task-pane/item-details/en.i18n.json", both);
  api.addFiles("i18n/justdo-task-pane/item-details/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-task-pane/item-details/vi.i18n.json", both);
  api.addFiles("i18n/justdo-task-pane/activity/en.i18n.json", both);
  api.addFiles("i18n/justdo-task-pane/activity/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-task-pane/activity/vi.i18n.json", both);
  api.addFiles("i18n/justdo-tasks-collection-manager/en.i18n.json", both);
  api.addFiles("i18n/justdo-tasks-collection-manager/vi.i18n.json", both);
  api.addFiles("i18n/justdo-tasks-collection-manager/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-chat/en.i18n.json", both);
  api.addFiles("i18n/justdo-chat/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-chat/vi.i18n.json", both);
  api.addFiles("i18n/justdo-tasks-changelog-manager/en.i18n.json", both);
  api.addFiles("i18n/justdo-tasks-changelog-manager/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-task-types/en.i18n.json", both);
  api.addFiles("i18n/justdo-task-types/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-task-types/vi.i18n.json", both);
  api.addFiles("i18n/justdo-private-follow-up/en.i18n.json", both);
  api.addFiles("i18n/justdo-private-follow-up/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-private-follow-up/vi.i18n.json", both);
  api.addFiles("i18n/justdo-webapp-layout/en.i18n.json", both);
  api.addFiles("i18n/justdo-webapp-layout/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-webapp-layout/vi.i18n.json", both);
  api.addFiles("i18n/justdo-files/en.i18n.json", both);
  api.addFiles("i18n/justdo-files/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-files/vi.i18n.json", both);
  api.addFiles("i18n/justdo-tab-switcher-dropdown-ui/en.i18n.json", both);
  api.addFiles("i18n/justdo-tab-switcher-dropdown-ui/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-tab-switcher-dropdown-ui/vi.i18n.json", both);
  api.addFiles("i18n/justdo-item-duplicate-control/en.i18n.json", both);
  api.addFiles("i18n/justdo-item-duplicate-control/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-item-duplicate-control/vi.i18n.json", both);
  api.addFiles("i18n/justdo-projects/en.i18n.json", both);
  api.addFiles("i18n/justdo-projects/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-projects/vi.i18n.json", both);
  api.addFiles("i18n/grid-control/zh-TW.i18n.json", both);
  api.addFiles("i18n/grid-control/en.i18n.json", both);
  api.addFiles("i18n/grid-control/vi.i18n.json", both);
  api.addFiles("i18n/justdo-orgs/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-orgs/en.i18n.json", both);
  api.addFiles("i18n/justdo-orgs/vi.i18n.json", both);
  api.addFiles("i18n/justdo-grid-views/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-grid-views/en.i18n.json", both);
  api.addFiles("i18n/justdo-grid-views/vi.i18n.json", both);
  api.addFiles("i18n/justdo-clipboard-import/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-clipboard-import/en.i18n.json", both);
  api.addFiles("i18n/justdo-clipboard-import/vi.i18n.json", both);
  api.addFiles("i18n/justdo-project-config-ui/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-project-config-ui/en.i18n.json", both);
  api.addFiles("i18n/justdo-project-config-ui/vi.i18n.json", both);
  api.addFiles("i18n/grid-control-custom-fields/zh-TW.i18n.json", both);
  api.addFiles("i18n/grid-control-custom-fields/en.i18n.json", both);
  api.addFiles("i18n/grid-control-custom-fields/vi.i18n.json", both);
  api.addFiles("i18n/justdo-project-config-ticket-queues/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-project-config-ticket-queues/en.i18n.json", both);
  api.addFiles("i18n/justdo-core-project-configurations/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-core-project-configurations/en.i18n.json", both);
  api.addFiles("i18n/justdo-core-project-configurations/vi.i18n.json", both);
  api.addFiles("i18n/justdo-tasks-context-menu/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-tasks-context-menu/en.i18n.json", both);
  api.addFiles("i18n/justdo-tasks-context-menu/vi.i18n.json", both);
  api.addFiles("i18n/justdo-planning-utilities/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-planning-utilities/en.i18n.json", both);
  api.addFiles("i18n/justdo-projects-health/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-projects-health/en.i18n.json", both);
  api.addFiles("i18n/justdo-resources-availability/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-resources-availability/en.i18n.json", both);
  api.addFiles("i18n/justdo-print-grid/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-print-grid/en.i18n.json", both);
  api.addFiles("i18n/justdo-emails/zh-TW.i18n.json", both);
  api.addFiles("i18n/justdo-emails/en.i18n.json", both);

  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.export("JustdoI18n", both);
});
