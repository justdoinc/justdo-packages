Package.describe({
  name:    'francocatena:status',
  git:     'https://github.com/francocatena/meteor-status',
  summary: 'Displays the connection status between browser and server',
  version: '1.5.3'
})

Package.onUse(function (api) {
  var client = 'client'
  var both   = ['client', 'server']

  api.versionsFrom('1.0')

  api.use('deps',         client)
  api.use('templating',   client)
  api.use('underscore',   client)
  api.use('reactive-var', client)

  api.use('tap:i18n', both)
  api.imply('tap:i18n')

  api.addFiles('lib/status.html',            client)
  api.addFiles('templates/bootstrap3.html',  client)
  api.addFiles('templates/semantic_ui.html', client)
  api.addFiles('templates/materialize.html', client)
  api.addFiles('templates/uikit.html',       client)
  api.addFiles('templates/foundation.html',  client)

  // Always after templates
  this.addI18nFiles(api, "i18n/{}.i18n.json");

  api.addFiles('status.js',     client)
  api.addFiles('lib/status.js', client)

  api.export('Status', client)
})

Package.onTest(function (api) {
  var client = 'client'

  api.use('francocatena:status', client)
  api.use('tinytest',            client)
  api.use('test-helpers',        client)

  api.addFiles('test/status_tests.js', client)
})
