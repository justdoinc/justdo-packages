Package.describe({
  summary: 'Style with attitude. Sass and SCSS support for Meteor.js.',
  version: "3.10.0",
  git: "https://github.com/fourseven/meteor-scss.git",
  name: "fourseven:scss"
});

Package.registerBuildPlugin({
  name: "compileScssBatch",
  use: ['caching-compiler@1.1.7', 'ecmascript@0.5.8', 'underscore@1.0.9'],
  sources: [
    'plugin/compile-scss.js'
  ],
  npmDependencies: {
    'node-sass': '4.5.3'
  }
});

Package.onUse(function (api) {
  api.versionsFrom("1.4.1");
  api.use('isobuild:compiler-plugin@1.0.0');
});
