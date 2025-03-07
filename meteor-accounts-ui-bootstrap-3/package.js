Package.describe({
  name: 'ian:accounts-ui-bootstrap-3',
  summary: 'Bootstrap-styled accounts-ui with multi-language support.',
  version: '1.2.89',
  git: "https://github.com/ianmartorell/meteor-accounts-ui-bootstrap-3"
});

client = "client";
server = "server";
both = [client, server];

Package.onUse(function (api) {
  api.use(['session@1.0.0',
    'spacebars@1.0.0',
    'accounts-base',
    'underscore@1.0.0',
    'templating@1.0.0'
    ],'client')

  api.use("coffeescript", both);
  api.use("justdoinc:justdo-i18n@1.0.0", both);
  api.use("tap:i18n", both);

  api.use("tracker", client);

  api.use("ecmascript", both);

  api.imply('accounts-base', ['client', 'server']);

  // Allows the user of this package to choose their own Bootstrap
  // implementation.
  api.use(['twbs:bootstrap@3.3.1',
          'nemo64:bootstrap@3.3.1_1'],
          'client', {weak: true});
  // Allows us to call Accounts.oauth.serviceNames, if there are any OAuth
  // services.
  api.use('accounts-oauth@1.0.0', {weak: true});
  // Allows us to directly test if accounts-password (which doesn't use
  // Accounts.oauth.registerService) exists.
  api.use('accounts-password', {weak: true});

  api.use('fourseven:scss@3.2.0', "client");

  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);

  api.use("justdoinc:justdo-avatar@1.0.0", client);

  api.addFiles([
    'accounts_ui.js',

    'login_buttons.html',
    'login_buttons_single.html',
    'login_buttons_dialogs.html',

    'login_buttons_session.js',
    'login_buttons.js',
    'login_buttons_single.js',

    'login_buttons_dialogs.js',
    'accounts_ui.sass',

    // Most of JustDo modifications starts here
    'dropdown/login_buttons_dropdown.html',
    'dropdown/login_buttons_dropdown.js',
    'dropdown/login_buttons_dropdown.sass',

    'dropdown/user_avatar_area/user_avatar_area.html',
    'dropdown/user_avatar_area/user_avatar_area.coffee',
    'dropdown/user_avatar_area/user_avatar_area.sass',

    'dropdown/change_password_button/change_password_button.html',
    'dropdown/change_password_button/change_password_button.coffee',

    'dropdown/change_email_button/change_email_button.html',
    'dropdown/change_email_button/change_email_button.coffee',

    'dropdown/name_and_email_area/name_and_email_area.html',
    'dropdown/name_and_email_area/name_and_email_area.coffee',
    'dropdown/name_and_email_area/name_and_email_area.sass',

    'dropdown/change_avatar_colors_button/change_avatar_colors_button.html',
    'dropdown/change_avatar_colors_button/change_avatar_colors_button.coffee',
    'dropdown/change_avatar_colors_button/change_avatar_colors_button.sass'
    ], 'client');

    this.addI18nFiles(api, "i18n/{}.i18n.json");

  api.export('accountsUIBootstrap3', 'client');

  // Media
  api.addAssets('media/icons.png', 'client');
})
