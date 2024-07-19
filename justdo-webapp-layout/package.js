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

  api.export("JustdoWebappLayout", client);
});
