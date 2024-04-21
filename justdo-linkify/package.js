Package.describe({
  name: 'justdoinc:justdo-linkify',
  version: '0.0.1',
  summary: ''
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.3');

  api.addFiles('lib/linkify/linkify.min.js', 'client');
  api.addFiles('lib/linkify/linkify-string.min.js', 'client');
  api.addFiles('lib/linkify/linkify-html.min.js', 'client');
});
