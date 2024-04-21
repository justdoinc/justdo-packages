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

});
