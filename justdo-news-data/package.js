Package.describe({
  name: "justdoinc:justdo-news-data",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-news-data"
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
  // Add to the peer dependencies checks to one of the JS/Coffee files of your package,
  // Example:
  //
  //   import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"
  //
  //   checkNpmVersions({
  //     'colors': '1.1.x'
  //   }, 'justdoinc:justdo-news-data')
  // api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", client);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);
  api.use("iron:router@1.1.2", both);

  api.use("reactive-var", client);
  api.use("tracker", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.use("justdoinc:justdo-news@1.0.0", both);
  api.use("tap:i18n", both);
  api.use("justdoinc:justdo-i18n@1.0.0", both);
  
  api.addFiles("lib/both/news-category-registrar.coffee", both);

  api.addFiles("lib/client/news-common.sass", client);
  api.addFiles("lib/client/templates/version-release/version-release.html", client);
  api.addFiles("lib/client/templates/version-release/version-release.coffee", client);

  // v3.133.x (Fake for package testing purpose, do not commit uncommentted!)
  // api.addAssets([
  //   "lib/both/news/v3-133/assets/2023_03_10_6.jpg"
  // ], client)
  // api.addFiles("lib/both/news/v3-133/v3-133.coffee", both);

  // v3.142
  api.addAssets([
    "lib/both/news/v3-142/assets/1-min.jpg",
    "lib/both/news/v3-142/assets/2-min.jpg"
  ], client);
  api.addFiles("lib/both/news/v3-142/v3-142.coffee", both);
  api.addFiles([
    "lib/both/news/v3-142/i18n/en.i18n.json",
    "lib/both/news/v3-142/i18n/ar.i18n.json",
    "lib/both/news/v3-142/i18n/es.i18n.json",
    "lib/both/news/v3-142/i18n/fr.i18n.json",
    "lib/both/news/v3-142/i18n/he.i18n.json",
    "lib/both/news/v3-142/i18n/ja.i18n.json",
    "lib/both/news/v3-142/i18n/km.i18n.json",
    "lib/both/news/v3-142/i18n/ko.i18n.json",
    "lib/both/news/v3-142/i18n/pt-PT.i18n.json",
    "lib/both/news/v3-142/i18n/pt-BR.i18n.json",
    "lib/both/news/v3-142/i18n/vi.i18n.json",
    "lib/both/news/v3-142/i18n/ru.i18n.json",
    "lib/both/news/v3-142/i18n/yi.i18n.json",
    "lib/both/news/v3-142/i18n/it.i18n.json",
    "lib/both/news/v3-142/i18n/de.i18n.json",
    "lib/both/news/v3-142/i18n/hi.i18n.json",
    "lib/both/news/v3-142/i18n/tr.i18n.json",
    "lib/both/news/v3-142/i18n/el.i18n.json",
    "lib/both/news/v3-142/i18n/da.i18n.json",
    "lib/both/news/v3-142/i18n/fi.i18n.json",
    "lib/both/news/v3-142/i18n/nl.i18n.json",
    "lib/both/news/v3-142/i18n/sv.i18n.json",
    "lib/both/news/v3-142/i18n/th.i18n.json",
    "lib/both/news/v3-142/i18n/id.i18n.json",
    "lib/both/news/v3-142/i18n/pl.i18n.json",
    "lib/both/news/v3-142/i18n/cs.i18n.json",
    "lib/both/news/v3-142/i18n/hu.i18n.json",
    "lib/both/news/v3-142/i18n/ro.i18n.json",
    "lib/both/news/v3-142/i18n/sk.i18n.json",
    "lib/both/news/v3-142/i18n/uk.i18n.json",
    "lib/both/news/v3-142/i18n/bg.i18n.json",
    "lib/both/news/v3-142/i18n/hr.i18n.json",
    "lib/both/news/v3-142/i18n/sr.i18n.json",
    "lib/both/news/v3-142/i18n/sl.i18n.json",
    "lib/both/news/v3-142/i18n/et.i18n.json",
    "lib/both/news/v3-142/i18n/lv.i18n.json",
    "lib/both/news/v3-142/i18n/lt.i18n.json",
    "lib/both/news/v3-142/i18n/am.i18n.json",
    "lib/both/news/v3-142/i18n/zh-CN.i18n.json",
    "lib/both/news/v3-142/i18n/zh-TW.i18n.json",
    "lib/both/news/v3-142/i18n/sw.i18n.json",
    "lib/both/news/v3-142/i18n/af.i18n.json",
    "lib/both/news/v3-142/i18n/az.i18n.json",
    "lib/both/news/v3-142/i18n/be.i18n.json",
    "lib/both/news/v3-142/i18n/bn.i18n.json",
    "lib/both/news/v3-142/i18n/bs.i18n.json",
    "lib/both/news/v3-142/i18n/ca.i18n.json",
    "lib/both/news/v3-142/i18n/eu.i18n.json",
    "lib/both/news/v3-142/i18n/lb.i18n.json",
    "lib/both/news/v3-142/i18n/mk.i18n.json",
    "lib/both/news/v3-142/i18n/ne.i18n.json",
    "lib/both/news/v3-142/i18n/nb.i18n.json",
    "lib/both/news/v3-142/i18n/sq.i18n.json",
    "lib/both/news/v3-142/i18n/ta.i18n.json",
    "lib/both/news/v3-142/i18n/uz.i18n.json",
    "lib/both/news/v3-142/i18n/hy.i18n.json",
    "lib/both/news/v3-142/i18n/kk.i18n.json",
    "lib/both/news/v3-142/i18n/ky.i18n.json",
    "lib/both/news/v3-142/i18n/ms.i18n.json",
    "lib/both/news/v3-142/i18n/tg.i18n.json"
  ], both);

  // v3.140
  api.addAssets([
    "lib/both/news/v3-140/assets/1.jpg",
    "lib/both/news/v3-140/assets/2.jpg",
    "lib/both/news/v3-140/assets/3.jpg",
    "lib/both/news/v3-140/assets/4.jpg",
    "lib/both/news/v3-140/assets/5.jpg",
    "lib/both/news/v3-140/assets/6.jpg"
  ], client);
  api.addFiles("lib/both/news/v3-140/v3-140.coffee", both);
  api.addFiles([
    "lib/both/news/v3-140/i18n/en.i18n.json",
    "lib/both/news/v3-140/i18n/ar.i18n.json",
    "lib/both/news/v3-140/i18n/es.i18n.json",
    "lib/both/news/v3-140/i18n/fr.i18n.json",
    "lib/both/news/v3-140/i18n/he.i18n.json",
    "lib/both/news/v3-140/i18n/ja.i18n.json",
    "lib/both/news/v3-140/i18n/km.i18n.json",
    "lib/both/news/v3-140/i18n/ko.i18n.json",
    "lib/both/news/v3-140/i18n/pt-PT.i18n.json",
    "lib/both/news/v3-140/i18n/pt-BR.i18n.json",
    "lib/both/news/v3-140/i18n/vi.i18n.json",
    "lib/both/news/v3-140/i18n/ru.i18n.json",
    "lib/both/news/v3-140/i18n/yi.i18n.json",
    "lib/both/news/v3-140/i18n/it.i18n.json",
    "lib/both/news/v3-140/i18n/de.i18n.json",
    "lib/both/news/v3-140/i18n/hi.i18n.json",
    "lib/both/news/v3-140/i18n/tr.i18n.json",
    "lib/both/news/v3-140/i18n/el.i18n.json",
    "lib/both/news/v3-140/i18n/da.i18n.json",
    "lib/both/news/v3-140/i18n/fi.i18n.json",
    "lib/both/news/v3-140/i18n/nl.i18n.json",
    "lib/both/news/v3-140/i18n/sv.i18n.json",
    "lib/both/news/v3-140/i18n/th.i18n.json",
    "lib/both/news/v3-140/i18n/id.i18n.json",
    "lib/both/news/v3-140/i18n/pl.i18n.json",
    "lib/both/news/v3-140/i18n/cs.i18n.json",
    "lib/both/news/v3-140/i18n/hu.i18n.json",
    "lib/both/news/v3-140/i18n/ro.i18n.json",
    "lib/both/news/v3-140/i18n/sk.i18n.json",
    "lib/both/news/v3-140/i18n/uk.i18n.json",
    "lib/both/news/v3-140/i18n/bg.i18n.json",
    "lib/both/news/v3-140/i18n/hr.i18n.json",
    "lib/both/news/v3-140/i18n/sr.i18n.json",
    "lib/both/news/v3-140/i18n/sl.i18n.json",
    "lib/both/news/v3-140/i18n/et.i18n.json",
    "lib/both/news/v3-140/i18n/lv.i18n.json",
    "lib/both/news/v3-140/i18n/lt.i18n.json",
    "lib/both/news/v3-140/i18n/am.i18n.json",
    "lib/both/news/v3-140/i18n/zh-CN.i18n.json",
    "lib/both/news/v3-140/i18n/zh-TW.i18n.json",
    "lib/both/news/v3-140/i18n/sw.i18n.json",
    "lib/both/news/v3-140/i18n/af.i18n.json",
    "lib/both/news/v3-140/i18n/az.i18n.json",
    "lib/both/news/v3-140/i18n/be.i18n.json",
    "lib/both/news/v3-140/i18n/bn.i18n.json",
    "lib/both/news/v3-140/i18n/bs.i18n.json",
    "lib/both/news/v3-140/i18n/ca.i18n.json",
    "lib/both/news/v3-140/i18n/eu.i18n.json",
    "lib/both/news/v3-140/i18n/lb.i18n.json",
    "lib/both/news/v3-140/i18n/mk.i18n.json",
    "lib/both/news/v3-140/i18n/ne.i18n.json",
    "lib/both/news/v3-140/i18n/nb.i18n.json",
    "lib/both/news/v3-140/i18n/sq.i18n.json",
    "lib/both/news/v3-140/i18n/ta.i18n.json",
    "lib/both/news/v3-140/i18n/uz.i18n.json",
    "lib/both/news/v3-140/i18n/hy.i18n.json",
    "lib/both/news/v3-140/i18n/kk.i18n.json",
    "lib/both/news/v3-140/i18n/ky.i18n.json",
    "lib/both/news/v3-140/i18n/ms.i18n.json",
    "lib/both/news/v3-140/i18n/tg.i18n.json"
  ], both);

  // v3.138.x
  api.addAssets([
    "lib/both/news/v3-138/assets/1.jpg",
    "lib/both/news/v3-138/assets/2.jpg",
    "lib/both/news/v3-138/assets/3.jpg"
  ], client);
  api.addFiles("lib/both/news/v3-138/v3-138.coffee", both);
  api.addFiles([
    "lib/both/news/v3-138/i18n/en.i18n.json",
    "lib/both/news/v3-138/i18n/ar.i18n.json",
    "lib/both/news/v3-138/i18n/es.i18n.json",
    "lib/both/news/v3-138/i18n/fr.i18n.json",
    "lib/both/news/v3-138/i18n/he.i18n.json",
    "lib/both/news/v3-138/i18n/ja.i18n.json",
    "lib/both/news/v3-138/i18n/km.i18n.json",
    "lib/both/news/v3-138/i18n/ko.i18n.json",
    "lib/both/news/v3-138/i18n/pt-PT.i18n.json",
    "lib/both/news/v3-138/i18n/pt-BR.i18n.json",
    "lib/both/news/v3-138/i18n/vi.i18n.json",
    "lib/both/news/v3-138/i18n/ru.i18n.json",
    "lib/both/news/v3-138/i18n/yi.i18n.json",
    "lib/both/news/v3-138/i18n/it.i18n.json",
    "lib/both/news/v3-138/i18n/de.i18n.json",
    "lib/both/news/v3-138/i18n/hi.i18n.json",
    "lib/both/news/v3-138/i18n/tr.i18n.json",
    "lib/both/news/v3-138/i18n/el.i18n.json",
    "lib/both/news/v3-138/i18n/da.i18n.json",
    "lib/both/news/v3-138/i18n/fi.i18n.json",
    "lib/both/news/v3-138/i18n/nl.i18n.json",
    "lib/both/news/v3-138/i18n/sv.i18n.json",
    "lib/both/news/v3-138/i18n/th.i18n.json",
    "lib/both/news/v3-138/i18n/id.i18n.json",
    "lib/both/news/v3-138/i18n/pl.i18n.json",
    "lib/both/news/v3-138/i18n/cs.i18n.json",
    "lib/both/news/v3-138/i18n/hu.i18n.json",
    "lib/both/news/v3-138/i18n/ro.i18n.json",
    "lib/both/news/v3-138/i18n/sk.i18n.json",
    "lib/both/news/v3-138/i18n/uk.i18n.json",
    "lib/both/news/v3-138/i18n/bg.i18n.json",
    "lib/both/news/v3-138/i18n/hr.i18n.json",
    "lib/both/news/v3-138/i18n/sr.i18n.json",
    "lib/both/news/v3-138/i18n/sl.i18n.json",
    "lib/both/news/v3-138/i18n/et.i18n.json",
    "lib/both/news/v3-138/i18n/lv.i18n.json",
    "lib/both/news/v3-138/i18n/lt.i18n.json",
    "lib/both/news/v3-138/i18n/am.i18n.json",
    "lib/both/news/v3-138/i18n/zh-CN.i18n.json",
    "lib/both/news/v3-138/i18n/zh-TW.i18n.json",
    "lib/both/news/v3-138/i18n/sw.i18n.json",
    "lib/both/news/v3-138/i18n/af.i18n.json",
    "lib/both/news/v3-138/i18n/az.i18n.json",
    "lib/both/news/v3-138/i18n/be.i18n.json",
    "lib/both/news/v3-138/i18n/bn.i18n.json",
    "lib/both/news/v3-138/i18n/bs.i18n.json",
    "lib/both/news/v3-138/i18n/ca.i18n.json",
    "lib/both/news/v3-138/i18n/eu.i18n.json",
    "lib/both/news/v3-138/i18n/lb.i18n.json",
    "lib/both/news/v3-138/i18n/mk.i18n.json",
    "lib/both/news/v3-138/i18n/ne.i18n.json",
    "lib/both/news/v3-138/i18n/nb.i18n.json",
    "lib/both/news/v3-138/i18n/sq.i18n.json",
    "lib/both/news/v3-138/i18n/ta.i18n.json",
    "lib/both/news/v3-138/i18n/uz.i18n.json",
    "lib/both/news/v3-138/i18n/hy.i18n.json",
    "lib/both/news/v3-138/i18n/kk.i18n.json",
    "lib/both/news/v3-138/i18n/ky.i18n.json",
    "lib/both/news/v3-138/i18n/ms.i18n.json",
    "lib/both/news/v3-138/i18n/tg.i18n.json"
  ], both);

  // v3.136.x
  api.addAssets([
    "lib/both/news/v3-136/assets/2023_03_10_1.jpg",
    "lib/both/news/v3-136/assets/2023_03_10_3.jpg",
    "lib/both/news/v3-136/assets/2023_03_10_5.jpg",
    "lib/both/news/v3-136/assets/2023_03_10_6.jpg",
  ], client);
  api.addFiles("lib/both/news/v3-136/v3-136.coffee", both);
  api.addFiles([
    "lib/both/news/v3-136/i18n/en.i18n.json",
    "lib/both/news/v3-136/i18n/ar.i18n.json",
    "lib/both/news/v3-136/i18n/es.i18n.json",
    "lib/both/news/v3-136/i18n/fr.i18n.json",
    "lib/both/news/v3-136/i18n/he.i18n.json",
    "lib/both/news/v3-136/i18n/ja.i18n.json",
    "lib/both/news/v3-136/i18n/km.i18n.json",
    "lib/both/news/v3-136/i18n/ko.i18n.json",
    "lib/both/news/v3-136/i18n/pt-PT.i18n.json",
    "lib/both/news/v3-136/i18n/pt-BR.i18n.json",
    "lib/both/news/v3-136/i18n/vi.i18n.json",
    "lib/both/news/v3-136/i18n/ru.i18n.json",
    "lib/both/news/v3-136/i18n/yi.i18n.json",
    "lib/both/news/v3-136/i18n/it.i18n.json",
    "lib/both/news/v3-136/i18n/de.i18n.json",
    "lib/both/news/v3-136/i18n/hi.i18n.json",
    "lib/both/news/v3-136/i18n/tr.i18n.json",
    "lib/both/news/v3-136/i18n/el.i18n.json",
    "lib/both/news/v3-136/i18n/da.i18n.json",
    "lib/both/news/v3-136/i18n/fi.i18n.json",
    "lib/both/news/v3-136/i18n/nl.i18n.json",
    "lib/both/news/v3-136/i18n/sv.i18n.json",
    "lib/both/news/v3-136/i18n/th.i18n.json",
    "lib/both/news/v3-136/i18n/id.i18n.json",
    "lib/both/news/v3-136/i18n/pl.i18n.json",
    "lib/both/news/v3-136/i18n/cs.i18n.json",
    "lib/both/news/v3-136/i18n/hu.i18n.json",
    "lib/both/news/v3-136/i18n/ro.i18n.json",
    "lib/both/news/v3-136/i18n/sk.i18n.json",
    "lib/both/news/v3-136/i18n/uk.i18n.json",
    "lib/both/news/v3-136/i18n/bg.i18n.json",
    "lib/both/news/v3-136/i18n/hr.i18n.json",
    "lib/both/news/v3-136/i18n/sr.i18n.json",
    "lib/both/news/v3-136/i18n/sl.i18n.json",
    "lib/both/news/v3-136/i18n/et.i18n.json",
    "lib/both/news/v3-136/i18n/lv.i18n.json",
    "lib/both/news/v3-136/i18n/lt.i18n.json",
    "lib/both/news/v3-136/i18n/am.i18n.json",
    "lib/both/news/v3-136/i18n/zh-CN.i18n.json",
    "lib/both/news/v3-136/i18n/zh-TW.i18n.json",
    "lib/both/news/v3-136/i18n/sw.i18n.json",
    "lib/both/news/v3-136/i18n/af.i18n.json",
    "lib/both/news/v3-136/i18n/az.i18n.json",
    "lib/both/news/v3-136/i18n/be.i18n.json",
    "lib/both/news/v3-136/i18n/bn.i18n.json",
    "lib/both/news/v3-136/i18n/bs.i18n.json",
    "lib/both/news/v3-136/i18n/ca.i18n.json",
    "lib/both/news/v3-136/i18n/eu.i18n.json",
    "lib/both/news/v3-136/i18n/lb.i18n.json",
    "lib/both/news/v3-136/i18n/mk.i18n.json",
    "lib/both/news/v3-136/i18n/ne.i18n.json",
    "lib/both/news/v3-136/i18n/nb.i18n.json",
    "lib/both/news/v3-136/i18n/sq.i18n.json",
    "lib/both/news/v3-136/i18n/ta.i18n.json",
    "lib/both/news/v3-136/i18n/uz.i18n.json",
    "lib/both/news/v3-136/i18n/hy.i18n.json",
    "lib/both/news/v3-136/i18n/kk.i18n.json",
    "lib/both/news/v3-136/i18n/ky.i18n.json",
    "lib/both/news/v3-136/i18n/ms.i18n.json",
    "lib/both/news/v3-136/i18n/tg.i18n.json"
  ], both);

  // v3.134
  api.addAssets([
    "lib/both/news/v3-134/assets/2023_04_10_1.png",
    "lib/both/news/v3-134/assets/2023_04_10_2.png",
    "lib/both/news/v3-134/assets/2023_04_10_3.png",
  ], client);
  api.addFiles("lib/both/news/v3-134/v3-134.coffee", both);
  api.addFiles([
    "lib/both/news/v3-134/i18n/en.i18n.json",
    "lib/both/news/v3-134/i18n/ar.i18n.json",
    "lib/both/news/v3-134/i18n/es.i18n.json",
    "lib/both/news/v3-134/i18n/fr.i18n.json",
    "lib/both/news/v3-134/i18n/he.i18n.json",
    "lib/both/news/v3-134/i18n/ja.i18n.json",
    "lib/both/news/v3-134/i18n/km.i18n.json",
    "lib/both/news/v3-134/i18n/ko.i18n.json",
    "lib/both/news/v3-134/i18n/pt-PT.i18n.json",
    "lib/both/news/v3-134/i18n/pt-BR.i18n.json",
    "lib/both/news/v3-134/i18n/vi.i18n.json",
    "lib/both/news/v3-134/i18n/ru.i18n.json",
    "lib/both/news/v3-134/i18n/yi.i18n.json",
    "lib/both/news/v3-134/i18n/it.i18n.json",
    "lib/both/news/v3-134/i18n/de.i18n.json",
    "lib/both/news/v3-134/i18n/hi.i18n.json",
    "lib/both/news/v3-134/i18n/tr.i18n.json",
    "lib/both/news/v3-134/i18n/el.i18n.json",
    "lib/both/news/v3-134/i18n/da.i18n.json",
    "lib/both/news/v3-134/i18n/fi.i18n.json",
    "lib/both/news/v3-134/i18n/nl.i18n.json",
    "lib/both/news/v3-134/i18n/sv.i18n.json",
    "lib/both/news/v3-134/i18n/th.i18n.json",
    "lib/both/news/v3-134/i18n/id.i18n.json",
    "lib/both/news/v3-134/i18n/pl.i18n.json",
    "lib/both/news/v3-134/i18n/cs.i18n.json",
    "lib/both/news/v3-134/i18n/hu.i18n.json",
    "lib/both/news/v3-134/i18n/ro.i18n.json",
    "lib/both/news/v3-134/i18n/sk.i18n.json",
    "lib/both/news/v3-134/i18n/uk.i18n.json",
    "lib/both/news/v3-134/i18n/bg.i18n.json",
    "lib/both/news/v3-134/i18n/hr.i18n.json",
    "lib/both/news/v3-134/i18n/sr.i18n.json",
    "lib/both/news/v3-134/i18n/sl.i18n.json",
    "lib/both/news/v3-134/i18n/et.i18n.json",
    "lib/both/news/v3-134/i18n/lv.i18n.json",
    "lib/both/news/v3-134/i18n/lt.i18n.json",
    "lib/both/news/v3-134/i18n/am.i18n.json",
    "lib/both/news/v3-134/i18n/zh-CN.i18n.json",
    "lib/both/news/v3-134/i18n/zh-TW.i18n.json",
    "lib/both/news/v3-134/i18n/sw.i18n.json",
    "lib/both/news/v3-134/i18n/af.i18n.json",
    "lib/both/news/v3-134/i18n/az.i18n.json",
    "lib/both/news/v3-134/i18n/be.i18n.json",
    "lib/both/news/v3-134/i18n/bn.i18n.json",
    "lib/both/news/v3-134/i18n/bs.i18n.json",
    "lib/both/news/v3-134/i18n/ca.i18n.json",
    "lib/both/news/v3-134/i18n/eu.i18n.json",
    "lib/both/news/v3-134/i18n/lb.i18n.json",
    "lib/both/news/v3-134/i18n/mk.i18n.json",
    "lib/both/news/v3-134/i18n/ne.i18n.json",
    "lib/both/news/v3-134/i18n/nb.i18n.json",
    "lib/both/news/v3-134/i18n/sq.i18n.json",
    "lib/both/news/v3-134/i18n/ta.i18n.json",
    "lib/both/news/v3-134/i18n/uz.i18n.json",
    "lib/both/news/v3-134/i18n/hy.i18n.json",
    "lib/both/news/v3-134/i18n/kk.i18n.json",
    "lib/both/news/v3-134/i18n/ky.i18n.json",
    "lib/both/news/v3-134/i18n/ms.i18n.json",
    "lib/both/news/v3-134/i18n/tg.i18n.json"
  ], both);

  // v5
  api.addAssets([
    "lib/both/news/v5/assets/1.jpg",
    "lib/both/news/v5/assets/2.jpg"
  ], client);
  api.addFiles("lib/both/news/v5/v5.coffee", both);
  api.addFiles([
    "lib/both/news/v5/i18n/en.i18n.json",
    "lib/both/news/v5/i18n/ar.i18n.json",
    "lib/both/news/v5/i18n/es.i18n.json",
    "lib/both/news/v5/i18n/fr.i18n.json",
    "lib/both/news/v5/i18n/he.i18n.json",
    "lib/both/news/v5/i18n/ja.i18n.json",
    "lib/both/news/v5/i18n/km.i18n.json",
    "lib/both/news/v5/i18n/ko.i18n.json",
    "lib/both/news/v5/i18n/pt-PT.i18n.json",
    "lib/both/news/v5/i18n/pt-BR.i18n.json",
    "lib/both/news/v5/i18n/vi.i18n.json",
    "lib/both/news/v5/i18n/ru.i18n.json",
    "lib/both/news/v5/i18n/yi.i18n.json",
    "lib/both/news/v5/i18n/it.i18n.json",
    "lib/both/news/v5/i18n/de.i18n.json",
    "lib/both/news/v5/i18n/hi.i18n.json",
    "lib/both/news/v5/i18n/tr.i18n.json",
    "lib/both/news/v5/i18n/el.i18n.json",
    "lib/both/news/v5/i18n/da.i18n.json",
    "lib/both/news/v5/i18n/fi.i18n.json",
    "lib/both/news/v5/i18n/nl.i18n.json",
    "lib/both/news/v5/i18n/sv.i18n.json",
    "lib/both/news/v5/i18n/th.i18n.json",
    "lib/both/news/v5/i18n/id.i18n.json",
    "lib/both/news/v5/i18n/pl.i18n.json",
    "lib/both/news/v5/i18n/cs.i18n.json",
    "lib/both/news/v5/i18n/hu.i18n.json",
    "lib/both/news/v5/i18n/ro.i18n.json",
    "lib/both/news/v5/i18n/sk.i18n.json",
    "lib/both/news/v5/i18n/uk.i18n.json",
    "lib/both/news/v5/i18n/bg.i18n.json",
    "lib/both/news/v5/i18n/hr.i18n.json",
    "lib/both/news/v5/i18n/sr.i18n.json",
    "lib/both/news/v5/i18n/sl.i18n.json",
    "lib/both/news/v5/i18n/et.i18n.json",
    "lib/both/news/v5/i18n/lv.i18n.json",
    "lib/both/news/v5/i18n/lt.i18n.json",
    "lib/both/news/v5/i18n/am.i18n.json",
    "lib/both/news/v5/i18n/zh-CN.i18n.json",
    "lib/both/news/v5/i18n/zh-TW.i18n.json",
    "lib/both/news/v5/i18n/sw.i18n.json",
    "lib/both/news/v5/i18n/af.i18n.json",
    "lib/both/news/v5/i18n/az.i18n.json",
    "lib/both/news/v5/i18n/be.i18n.json",
    "lib/both/news/v5/i18n/bn.i18n.json",
    "lib/both/news/v5/i18n/bs.i18n.json",
    "lib/both/news/v5/i18n/ca.i18n.json",
    "lib/both/news/v5/i18n/eu.i18n.json",
    "lib/both/news/v5/i18n/lb.i18n.json",
    "lib/both/news/v5/i18n/mk.i18n.json",
    "lib/both/news/v5/i18n/ne.i18n.json",
    "lib/both/news/v5/i18n/nb.i18n.json",
    "lib/both/news/v5/i18n/sq.i18n.json",
    "lib/both/news/v5/i18n/ta.i18n.json",
    "lib/both/news/v5/i18n/uz.i18n.json",
    "lib/both/news/v5/i18n/hy.i18n.json",
    "lib/both/news/v5/i18n/kk.i18n.json",
    "lib/both/news/v5/i18n/ky.i18n.json",
    "lib/both/news/v5/i18n/ms.i18n.json",
    "lib/both/news/v5/i18n/tg.i18n.json"
  ], both);

  // v5.06
  api.addAssets([
    "lib/both/news/v5-06/assets/1.jpeg",
    "lib/both/news/v5-06/assets/2.jpeg"
  ], client);
  api.addFiles("lib/both/news/v5-06/v5-06.coffee", both);
  api.addFiles([
    "lib/both/news/v5-06/i18n/en.i18n.json",
    "lib/both/news/v5-06/i18n/ar.i18n.json",
    "lib/both/news/v5-06/i18n/es.i18n.json",
    "lib/both/news/v5-06/i18n/fr.i18n.json",
    "lib/both/news/v5-06/i18n/he.i18n.json",
    "lib/both/news/v5-06/i18n/ja.i18n.json",
    "lib/both/news/v5-06/i18n/km.i18n.json",
    "lib/both/news/v5-06/i18n/ko.i18n.json",
    "lib/both/news/v5-06/i18n/pt-PT.i18n.json",
    "lib/both/news/v5-06/i18n/pt-BR.i18n.json",
    "lib/both/news/v5-06/i18n/vi.i18n.json",
    "lib/both/news/v5-06/i18n/ru.i18n.json",
    "lib/both/news/v5-06/i18n/yi.i18n.json",
    "lib/both/news/v5-06/i18n/it.i18n.json",
    "lib/both/news/v5-06/i18n/de.i18n.json",
    "lib/both/news/v5-06/i18n/hi.i18n.json",
    "lib/both/news/v5-06/i18n/tr.i18n.json",
    "lib/both/news/v5-06/i18n/el.i18n.json",
    "lib/both/news/v5-06/i18n/da.i18n.json",
    "lib/both/news/v5-06/i18n/fi.i18n.json",
    "lib/both/news/v5-06/i18n/nl.i18n.json",
    "lib/both/news/v5-06/i18n/sv.i18n.json",
    "lib/both/news/v5-06/i18n/th.i18n.json",
    "lib/both/news/v5-06/i18n/id.i18n.json",
    "lib/both/news/v5-06/i18n/pl.i18n.json",
    "lib/both/news/v5-06/i18n/cs.i18n.json",
    "lib/both/news/v5-06/i18n/hu.i18n.json",
    "lib/both/news/v5-06/i18n/ro.i18n.json",
    "lib/both/news/v5-06/i18n/sk.i18n.json",
    "lib/both/news/v5-06/i18n/uk.i18n.json",
    "lib/both/news/v5-06/i18n/bg.i18n.json",
    "lib/both/news/v5-06/i18n/hr.i18n.json",
    "lib/both/news/v5-06/i18n/sr.i18n.json",
    "lib/both/news/v5-06/i18n/sl.i18n.json",
    "lib/both/news/v5-06/i18n/et.i18n.json",
    "lib/both/news/v5-06/i18n/lv.i18n.json",
    "lib/both/news/v5-06/i18n/lt.i18n.json",
    "lib/both/news/v5-06/i18n/am.i18n.json",
    "lib/both/news/v5-06/i18n/zh-CN.i18n.json",
    "lib/both/news/v5-06/i18n/zh-TW.i18n.json",
    "lib/both/news/v5-06/i18n/sw.i18n.json",
    "lib/both/news/v5-06/i18n/af.i18n.json",
    "lib/both/news/v5-06/i18n/az.i18n.json",
    "lib/both/news/v5-06/i18n/be.i18n.json",
    "lib/both/news/v5-06/i18n/bn.i18n.json",
    "lib/both/news/v5-06/i18n/bs.i18n.json",
    "lib/both/news/v5-06/i18n/ca.i18n.json",
    "lib/both/news/v5-06/i18n/eu.i18n.json",
    "lib/both/news/v5-06/i18n/lb.i18n.json",
    "lib/both/news/v5-06/i18n/mk.i18n.json",
    "lib/both/news/v5-06/i18n/ne.i18n.json",
    "lib/both/news/v5-06/i18n/nb.i18n.json",
    "lib/both/news/v5-06/i18n/sq.i18n.json",
    "lib/both/news/v5-06/i18n/ta.i18n.json",
    "lib/both/news/v5-06/i18n/uz.i18n.json",
    "lib/both/news/v5-06/i18n/hy.i18n.json",
    "lib/both/news/v5-06/i18n/kk.i18n.json",
    "lib/both/news/v5-06/i18n/ky.i18n.json",
    "lib/both/news/v5-06/i18n/ms.i18n.json",
    "lib/both/news/v5-06/i18n/tg.i18n.json"
  ], both);

  api.export("JustdoNewsData", both);
});
