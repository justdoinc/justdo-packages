Package.describe({
  name: "mizzao:tutorials",
  summary: "Create super cool animated tutorials for your Meteor app",
  version: "0.6.7",
  git: "https://github.com/mizzao/meteor-tutorials.git"
});

Package.onUse(function (api) {
  api.versionsFrom("1.2.0.1");

  api.use(['jquery', 'coffeescript'], 'client');
  api.use(['ui', 'templating'], 'client');

  api.use("fourseven:scss@3.2.0", client);

  // Weak dependencies on the most popular bootstrap packages
  api.use("twbs:bootstrap@3.3.5", 'client', {weak: true});
  api.use("nemo64:bootstrap@3.3.5_2", 'client', {weak: true});

  api.addFiles('templates.html', 'client');
  api.addFiles('tutorial.sass', 'client');

  api.addFiles('drags.js', 'client');

  api.addFiles('tutorial.coffee', 'client');
  api.addFiles('helpers.coffee', 'client');
});
