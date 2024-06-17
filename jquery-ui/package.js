Package.describe({
  name: "mizzao:jquery-ui",
  summary: "Simple lightweight pull-in for jQuery UI in Meteor",
  version: "1.11.4",
  git: "https://github.com/mizzao/meteor-jqueryui.git"
});

Package.onUse(function (api) {
  api.versionsFrom("1.0");

  api.use('jquery', 'client');

  api.addFiles('lib/jquery-ui.js', 'client');

  api.addFiles('lib/themes/smoothness/jquery-ui.min.css', 'client');

  api.addAssets('./lib/themes/smoothness/images/ui-icons_cd0a0a_256x240.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-icons_888888_256x240.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-bg_glass_75_dadada_1x400.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-icons_2e83ff_256x240.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-bg_glass_75_e6e6e6_1x400.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-bg_glass_65_ffffff_1x400.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-bg_glass_95_fef1ec_1x400.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-icons_222222_256x240.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-bg_highlight-soft_75_cccccc_1x100.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-bg_glass_55_fbf9ee_1x400.png', 'client');
  api.addAssets('./lib/themes/smoothness/images/ui-icons_454545_256x240.png', 'client');

  api.addFiles('justdo-modifications/datepicker.js', 'client');

  api.addFiles("lib/i18n/datepicker-af.js", client);
  api.addFiles("lib/i18n/datepicker-ar-DZ.js", client);
  api.addFiles("lib/i18n/datepicker-ar.js", client);
  api.addFiles("lib/i18n/datepicker-az.js", client);
  api.addFiles("lib/i18n/datepicker-be.js", client);
  api.addFiles("lib/i18n/datepicker-bg.js", client);
  api.addFiles("lib/i18n/datepicker-bs.js", client);
  api.addFiles("lib/i18n/datepicker-ca.js", client);
  api.addFiles("lib/i18n/datepicker-cs.js", client);
  api.addFiles("lib/i18n/datepicker-cy-GB.js", client);
  api.addFiles("lib/i18n/datepicker-da.js", client);
  api.addFiles("lib/i18n/datepicker-de-AT.js", client);
  api.addFiles("lib/i18n/datepicker-de.js", client);
  api.addFiles("lib/i18n/datepicker-el.js", client);
  api.addFiles("lib/i18n/datepicker-en-AU.js", client);
  api.addFiles("lib/i18n/datepicker-en-GB.js", client);
  api.addFiles("lib/i18n/datepicker-en-NZ.js", client);
  api.addFiles("lib/i18n/datepicker-eo.js", client);
  api.addFiles("lib/i18n/datepicker-es.js", client);
  api.addFiles("lib/i18n/datepicker-et.js", client);
  api.addFiles("lib/i18n/datepicker-eu.js", client);
  api.addFiles("lib/i18n/datepicker-fa.js", client);
  api.addFiles("lib/i18n/datepicker-fi.js", client);
  api.addFiles("lib/i18n/datepicker-fo.js", client);
  api.addFiles("lib/i18n/datepicker-fr-CA.js", client);
  api.addFiles("lib/i18n/datepicker-fr-CH.js", client);
  api.addFiles("lib/i18n/datepicker-fr.js", client);
  api.addFiles("lib/i18n/datepicker-gl.js", client);
  api.addFiles("lib/i18n/datepicker-he.js", client);
  api.addFiles("lib/i18n/datepicker-hi.js", client);
  api.addFiles("lib/i18n/datepicker-hr.js", client);
  api.addFiles("lib/i18n/datepicker-hu.js", client);
  api.addFiles("lib/i18n/datepicker-hy.js", client);
  api.addFiles("lib/i18n/datepicker-id.js", client);
  api.addFiles("lib/i18n/datepicker-is.js", client);
  api.addFiles("lib/i18n/datepicker-it-CH.js", client);
  api.addFiles("lib/i18n/datepicker-it.js", client);
  api.addFiles("lib/i18n/datepicker-ja.js", client);
  api.addFiles("lib/i18n/datepicker-ka.js", client);
  api.addFiles("lib/i18n/datepicker-kk.js", client);
  api.addFiles("lib/i18n/datepicker-km.js", client);
  api.addFiles("lib/i18n/datepicker-ko.js", client);
  api.addFiles("lib/i18n/datepicker-ky.js", client);
  api.addFiles("lib/i18n/datepicker-lb.js", client);
  api.addFiles("lib/i18n/datepicker-lt.js", client);
  api.addFiles("lib/i18n/datepicker-lv.js", client);
  api.addFiles("lib/i18n/datepicker-mk.js", client);
  api.addFiles("lib/i18n/datepicker-ml.js", client);
  api.addFiles("lib/i18n/datepicker-ms.js", client);
  api.addFiles("lib/i18n/datepicker-nb.js", client);
  api.addFiles("lib/i18n/datepicker-nl-BE.js", client);
  api.addFiles("lib/i18n/datepicker-nl.js", client);
  api.addFiles("lib/i18n/datepicker-nn.js", client);
  api.addFiles("lib/i18n/datepicker-no.js", client);
  api.addFiles("lib/i18n/datepicker-pl.js", client);
  api.addFiles("lib/i18n/datepicker-pt-BR.js", client);
  api.addFiles("lib/i18n/datepicker-pt.js", client);
  api.addFiles("lib/i18n/datepicker-rm.js", client);
  api.addFiles("lib/i18n/datepicker-ro.js", client);
  api.addFiles("lib/i18n/datepicker-ru.js", client);
  api.addFiles("lib/i18n/datepicker-sk.js", client);
  api.addFiles("lib/i18n/datepicker-sl.js", client);
  api.addFiles("lib/i18n/datepicker-sq.js", client);
  api.addFiles("lib/i18n/datepicker-sr-SR.js", client);
  api.addFiles("lib/i18n/datepicker-sr.js", client);
  api.addFiles("lib/i18n/datepicker-sv.js", client);
  api.addFiles("lib/i18n/datepicker-ta.js", client);
  api.addFiles("lib/i18n/datepicker-th.js", client);
  api.addFiles("lib/i18n/datepicker-tj.js", client);
  api.addFiles("lib/i18n/datepicker-tr.js", client);
  api.addFiles("lib/i18n/datepicker-uk.js", client);
  api.addFiles("lib/i18n/datepicker-vi.js", client);
  api.addFiles("lib/i18n/datepicker-zh-CN.js", client);
  api.addFiles("lib/i18n/datepicker-zh-HK.js", client);
  api.addFiles("lib/i18n/datepicker-zh-TW.js", client);

});
