Package.describe({
  name: "justdoinc:justdo-webapp-layout",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-webapp-layout"
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

  // api.use("stevezhu:lodash@4.17.2", client);
  api.use("templating@1.3.2", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("froala:editor@2.9.5", both);

  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", client);

  api.use("reactive-var", client);
  api.use("tracker", client);

  api.use("justdoinc:justdo-avatar", client);
  api.use("tap:i18n", both);
  api.use("justdoinc:justdo-i18n", both);

  api.use("ecmascript", both);

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/client/global-sass/global-vars.sass", "client");
  api.addFiles("lib/client/global-sass/tooltips-style.sass", "client");
  api.addFiles("lib/client/global-sass/outline-remover.sass", "client");
  api.addFiles("lib/client/global-sass/justdo-bootstrap-extensions.sass", "client");

  api.addFiles("lib/client/dashboard/dashboard-footer/footer.html", "client");
  api.addFiles("lib/client/dashboard/dashboard-footer/footer.sass", "client");
  api.addFiles("lib/client/dashboard/dashboard.coffee", "client");
  api.addFiles("lib/client/dashboard/dashboard.html", "client");
  api.addFiles("lib/client/dashboard/dashboard.sass", "client");
  api.addFiles("lib/client/dashboard/projects/dashboard-projects.coffee", "client");
  api.addFiles("lib/client/dashboard/projects/dashboard-projects.html", "client");
  api.addFiles("lib/client/dashboard/projects/dashboard-projects.sass", "client");

  api.addFiles("lib/client/general-loading-indicator/general-loading-indicator.html", "client");
  api.addFiles("lib/client/general-loading-indicator/general-loading-indicator.sass", "client");

  api.addFiles("lib/client/global-templates/user-profile-pic/user-profile-pic.html", "client");

  api.addFiles("lib/client/loading/loading.html", "client");

  api.addFiles("lib/client/login/login.html", "client");

  api.addFiles("lib/client/project/grid/grid.coffee", "client");
  api.addFiles("lib/client/project/grid/grid.html", "client");
  api.addFiles("lib/client/project/grid/grid.sass", "client");
  api.addFiles("lib/client/project/grid/owners-management/owners-management.coffee", "client");
  api.addFiles("lib/client/project/grid/owners-management/owners-management.html", "client");
  api.addFiles("lib/client/project/grid/owners-management/owners-management.sass", "client");
  api.addFiles("lib/client/project/header/header.coffee", "client");
  api.addFiles("lib/client/project/header/header.html", "client");
  api.addFiles("lib/client/project/header/header.sass", "client");
  api.addFiles("lib/client/project/header/members-dropdown/members-dropdown-button.coffee", "client");
  api.addFiles("lib/client/project/header/members-dropdown/members-dropdown-button.html", "client");
  api.addFiles("lib/client/project/header/members-dropdown/members-dropdown-button.sass", "client");
  api.addFiles("lib/client/project/header/plugins-store-button/plugins-store-button.coffee", "client");
  api.addFiles("lib/client/project/header/plugins-store-button/plugins-store-button.html", "client");
  api.addFiles("lib/client/project/header/plugins-store-button/plugins-store-button.sass", "client");
  api.addFiles("lib/client/project/header/plugins-store-button/plugins-store-layout/plugins-store-layout.html", "client");
  api.addFiles("lib/client/project/header/plugins-store-button/plugins-store-layout/plugins-store-layout.coffee", "client");
  api.addFiles("lib/client/project/header/plugins-store-button/plugins-store-layout/plugins-store-layout.sass", "client");
  api.addFiles("lib/client/project/header/members-dropdown/members-dropdown-menu/members-dropdown-menu.coffee", "client");
  api.addFiles("lib/client/project/header/members-dropdown/members-dropdown-menu/members-dropdown-menu.html", "client");
  api.addFiles("lib/client/project/header/members-dropdown/members-dropdown-menu/members-dropdown-menu.sass", "client");
  api.addFiles("lib/client/project/header/members-dropdown/members-dropdown-menu/members-dropdown-invite/members-dropdown-invite.coffee", "client");
  api.addFiles("lib/client/project/header/members-dropdown/members-dropdown-menu/members-dropdown-invite/members-dropdown-invite.html", "client");
  api.addFiles("lib/client/project/header/members-dropdown/members-dropdown-menu/members-dropdown-invite/members-dropdown-invite.sass", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/nullary-operations.coffee", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/operations-toolbar.html", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/operations-toolbar.sass", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/operations-toolbar.coffee", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/print-grid/print-grid.coffee", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/print-grid/print-grid.html", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/priority-slider/priority-slider.coffee", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/priority-slider/priority-slider.html", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/priority-slider/priority-slider.sass", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/ticket-entry/ticket-entry.coffee", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/ticket-entry/ticket-entry.html", "client");
  api.addFiles("lib/client/project/header/operations-toolbar/ticket-entry/ticket-entry.sass", "client");
  api.addFiles("lib/client/project/header/project-remove/project-remove.coffee", "client");
  api.addFiles("lib/client/project/header/project-remove/project-remove.html", "client");
  api.addFiles("lib/client/project/header/project-remove/project-remove.sass", "client");
  api.addFiles("lib/client/project/header/required-actions/required-actions-dropdown/required-actions-dropdown.coffee", "client");
  api.addFiles("lib/client/project/header/required-actions/required-actions-dropdown/required-actions-dropdown.html", "client");
  api.addFiles("lib/client/project/header/required-actions/required-actions-dropdown/required-actions-dropdown.sass", "client");
  api.addFiles("lib/client/project/header/required-actions/required-actions.coffee", "client");
  api.addFiles("lib/client/project/header/required-actions/required-actions.html", "client");
  api.addFiles("lib/client/project/header/required-actions/required-actions.sass", "client");
  api.addFiles("lib/client/project/project.coffee", "client");
  api.addFiles("lib/client/project/project.html", "client");
  api.addFiles("lib/client/project/project.sass", "client");

  api.addFiles("lib/client/webapp-layout/application-layout.coffee", "client");
  api.addFiles("lib/client/webapp-layout/application-layout.html", "client");
  api.addFiles("lib/client/webapp-layout/application-layout.sass", "client");
  api.addFiles("lib/client/webapp-layout/header/bugmuncher/bugmuncher.coffee", "client");
  api.addFiles("lib/client/webapp-layout/header/bugmuncher/bugmuncher.html", "client");
  api.addFiles("lib/client/webapp-layout/header/bugmuncher/bugmuncher.sass", "client");
  api.addFiles("lib/client/webapp-layout/header/header.coffee", "client");
  api.addFiles("lib/client/webapp-layout/header/header.html", "client");
  api.addFiles("lib/client/webapp-layout/header/header.sass", "client");
  api.addFiles("lib/client/webapp-layout/header/drawer-projects/drawer-projects.sass", "client");
  api.addFiles("lib/client/webapp-layout/header/drawer-projects/drawer-projects.html", "client");
  api.addFiles("lib/client/webapp-layout/header/drawer-projects/drawer-projects.coffee", "client");
  api.addFiles("lib/client/dual-frame-settings-page-layout/dual-frame-settings-page-layout.sass", "client");
  api.addFiles("lib/client/dual-frame-settings-page-layout/dual-frame-settings-page-layout.html", "client");
  api.addFiles("lib/client/dual-frame-settings-page-layout/dual-frame-settings-page-layout.coffee", "client");
  api.addFiles("lib/client/dual-frame-settings-page-layout/menu-item/menu-item.sass", "client");
  api.addFiles("lib/client/dual-frame-settings-page-layout/menu-item/menu-item.html", "client");
  api.addFiles("lib/client/dual-frame-settings-page-layout/menu-item/menu-item.coffee", "client");

  api.addAssets("lib/client/assets/layout-sprite.png", "client");
  api.addAssets("lib/client/project/header/members-dropdown/members-dropdown-menu/members-dropdown-invite/assets/set_task_as_project.mp4", "client");

  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);

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

  // owners-management
  api.addFiles([
    "i18n/owners-management/en.i18n.json",
    "i18n/owners-management/ar.i18n.json",
    "i18n/owners-management/es.i18n.json",
    "i18n/owners-management/fr.i18n.json",
    "i18n/owners-management/he.i18n.json",
    "i18n/owners-management/ja.i18n.json",
    "i18n/owners-management/km.i18n.json",
    "i18n/owners-management/ko.i18n.json",
    "i18n/owners-management/pt-PT.i18n.json",
    "i18n/owners-management/pt-BR.i18n.json",
    "i18n/owners-management/vi.i18n.json",
    "i18n/owners-management/ru.i18n.json",
    "i18n/owners-management/yi.i18n.json",
    "i18n/owners-management/it.i18n.json",
    "i18n/owners-management/de.i18n.json",
    "i18n/owners-management/hi.i18n.json",
    "i18n/owners-management/tr.i18n.json",
    "i18n/owners-management/el.i18n.json",
    "i18n/owners-management/da.i18n.json",
    "i18n/owners-management/fi.i18n.json",
    "i18n/owners-management/nl.i18n.json",
    "i18n/owners-management/sv.i18n.json",
    "i18n/owners-management/th.i18n.json",
    "i18n/owners-management/id.i18n.json",
    "i18n/owners-management/pl.i18n.json",
    "i18n/owners-management/cs.i18n.json",
    "i18n/owners-management/hu.i18n.json",
    "i18n/owners-management/ro.i18n.json",
    "i18n/owners-management/sk.i18n.json",
    "i18n/owners-management/uk.i18n.json",
    "i18n/owners-management/bg.i18n.json",
    "i18n/owners-management/hr.i18n.json",
    "i18n/owners-management/sr.i18n.json",
    "i18n/owners-management/sl.i18n.json",
    "i18n/owners-management/et.i18n.json",
    "i18n/owners-management/lv.i18n.json",
    "i18n/owners-management/lt.i18n.json",
    "i18n/owners-management/am.i18n.json",
    "i18n/owners-management/zh-CN.i18n.json",
    "i18n/owners-management/zh-TW.i18n.json",
    "i18n/owners-management/sw.i18n.json",
    "i18n/owners-management/af.i18n.json",
    "i18n/owners-management/az.i18n.json",
    "i18n/owners-management/be.i18n.json",
    "i18n/owners-management/bn.i18n.json",
    "i18n/owners-management/bs.i18n.json",
    "i18n/owners-management/ca.i18n.json",
    "i18n/owners-management/eu.i18n.json",
    "i18n/owners-management/lb.i18n.json",
    "i18n/owners-management/mk.i18n.json",
    "i18n/owners-management/ne.i18n.json",
    "i18n/owners-management/nb.i18n.json",
    "i18n/owners-management/sq.i18n.json",
    "i18n/owners-management/ta.i18n.json",
    "i18n/owners-management/uz.i18n.json",
    "i18n/owners-management/hy.i18n.json",
    "i18n/owners-management/kk.i18n.json",
    "i18n/owners-management/ky.i18n.json",
    "i18n/owners-management/ms.i18n.json",
    "i18n/owners-management/tg.i18n.json"
  ], both);

  // required-actions-dropdown
  api.addFiles([
    "i18n/required-actions-dropdown/en.i18n.json",
    "i18n/required-actions-dropdown/ar.i18n.json",
    "i18n/required-actions-dropdown/es.i18n.json",
    "i18n/required-actions-dropdown/fr.i18n.json",
    "i18n/required-actions-dropdown/he.i18n.json",
    "i18n/required-actions-dropdown/ja.i18n.json",
    "i18n/required-actions-dropdown/km.i18n.json",
    "i18n/required-actions-dropdown/ko.i18n.json",
    "i18n/required-actions-dropdown/pt-PT.i18n.json",
    "i18n/required-actions-dropdown/pt-BR.i18n.json",
    "i18n/required-actions-dropdown/vi.i18n.json",
    "i18n/required-actions-dropdown/ru.i18n.json",
    "i18n/required-actions-dropdown/yi.i18n.json",
    "i18n/required-actions-dropdown/it.i18n.json",
    "i18n/required-actions-dropdown/de.i18n.json",
    "i18n/required-actions-dropdown/hi.i18n.json",
    "i18n/required-actions-dropdown/tr.i18n.json",
    "i18n/required-actions-dropdown/el.i18n.json",
    "i18n/required-actions-dropdown/da.i18n.json",
    "i18n/required-actions-dropdown/fi.i18n.json",
    "i18n/required-actions-dropdown/nl.i18n.json",
    "i18n/required-actions-dropdown/sv.i18n.json",
    "i18n/required-actions-dropdown/th.i18n.json",
    "i18n/required-actions-dropdown/id.i18n.json",
    "i18n/required-actions-dropdown/pl.i18n.json",
    "i18n/required-actions-dropdown/cs.i18n.json",
    "i18n/required-actions-dropdown/hu.i18n.json",
    "i18n/required-actions-dropdown/ro.i18n.json",
    "i18n/required-actions-dropdown/sk.i18n.json",
    "i18n/required-actions-dropdown/uk.i18n.json",
    "i18n/required-actions-dropdown/bg.i18n.json",
    "i18n/required-actions-dropdown/hr.i18n.json",
    "i18n/required-actions-dropdown/sr.i18n.json",
    "i18n/required-actions-dropdown/sl.i18n.json",
    "i18n/required-actions-dropdown/et.i18n.json",
    "i18n/required-actions-dropdown/lv.i18n.json",
    "i18n/required-actions-dropdown/lt.i18n.json",
    "i18n/required-actions-dropdown/am.i18n.json",
    "i18n/required-actions-dropdown/zh-CN.i18n.json",
    "i18n/required-actions-dropdown/zh-TW.i18n.json",
    "i18n/required-actions-dropdown/sw.i18n.json",
    "i18n/required-actions-dropdown/af.i18n.json",
    "i18n/required-actions-dropdown/az.i18n.json",
    "i18n/required-actions-dropdown/be.i18n.json",
    "i18n/required-actions-dropdown/bn.i18n.json",
    "i18n/required-actions-dropdown/bs.i18n.json",
    "i18n/required-actions-dropdown/ca.i18n.json",
    "i18n/required-actions-dropdown/eu.i18n.json",
    "i18n/required-actions-dropdown/lb.i18n.json",
    "i18n/required-actions-dropdown/mk.i18n.json",
    "i18n/required-actions-dropdown/ne.i18n.json",
    "i18n/required-actions-dropdown/nb.i18n.json",
    "i18n/required-actions-dropdown/sq.i18n.json",
    "i18n/required-actions-dropdown/ta.i18n.json",
    "i18n/required-actions-dropdown/uz.i18n.json",
    "i18n/required-actions-dropdown/hy.i18n.json",
    "i18n/required-actions-dropdown/kk.i18n.json",
    "i18n/required-actions-dropdown/ky.i18n.json",
    "i18n/required-actions-dropdown/ms.i18n.json",
    "i18n/required-actions-dropdown/tg.i18n.json"
  ], both);

  api.export("JustdoWebappLayout", client);
});
