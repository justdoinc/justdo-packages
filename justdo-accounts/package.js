Package.describe({
  name: "justdoinc:justdo-accounts",
  version: "1.0.0",
  summary: "Takes care of accounts creation/registration/enrollment/password-reset/verification",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-accounts"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.use("coffeescript", both);
  api.use("mongo", both);
  api.use("check", both);
  api.use("underscore", both);
  api.use("accounts-base", both);
  api.use("accounts-password", both);
  api.use("tracker", client);
  api.use("http", both);
  api.use("ecmascript", both);

  api.use("sha", both);
  api.use("srp", both);

  api.use("justdoinc:justdo-aws-base", server, {unordered: true});

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use("tap:i18n", both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);
  api.use('justdoinc:justdo-legal-docs-versions@1.0.0', both);
  api.use('justdoinc:justdo-login-state@1.0.0', client);

  api.use('aldeed:simple-schema@1.3.1', both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use('risul:moment-timezone@0.5.0_5', client)

  api.use("matb33:collection-hooks@0.8.4", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles('lib/both/errors-types.coffee', both);
  api.addFiles('lib/both/meteor-accounts-configuration.coffee', both);
  api.addFiles('lib/both/schemas.coffee', both);
  api.addFiles('lib/both/api.coffee', both);

  api.addFiles("lib/server/init.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/collection-hooks.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/collection-hooks.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

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

  api.use("meteorspark:app@0.3.0", both);

  api.export("JustdoAccounts", both);
});
