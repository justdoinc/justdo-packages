Package.describe({
  name: 'coffeescript',
  summary: 'JavaScript dialect with fewer braces and semicolons',
  // This package version should track the version of the `coffeescript-compiler`
  // package, because people will likely only have this one added to their apps;
  // so bumping the version of this package will be how they get newer versions
  // of `coffeescript-compiler`. If you change this, make sure to also update
  // ../coffeescript-compiler/package.js to match.
  version: '2.4.1'
});

Package.registerBuildPlugin({
  name: 'compile-coffeescript',
  use: ['caching-compiler@1.2.1', 'ecmascript@0.12.7', 'coffeescript-compiler@2.4.1'],
  sources: ['compile-coffeescript.js'],
  npmDependencies: {
    // A breaking change was introduced in @babel/runtime@7.0.0-beta.56
    // with the removal of the @babel/runtime/helpers/builtin directory.
    // Since the compile-coffeescript plugin is bundled and published with
    // a specific version of babel-compiler and babel-runtime, it also
    // needs to have a reliable version of the @babel/runtime npm package,
    // rather than delegating to the one installed in the application's
    // node_modules directory, so the coffeescript package can work in
    // Meteor 1.7.1 apps as well as 1.7.0.x and earlier.
    '@babel/runtime': '7.6.0'
  }
});

Package.onUse(function (api) {
  api.versionsFrom("1.8.1");
  api.use('isobuild:compiler-plugin@1.0.0');

  // Because the CoffeeScript plugin now calls
  // BabelCompiler.prototype.processOneFileForTarget for any ES2015+
  // JavaScript or JavaScript enclosed by backticks, it must provide the
  // same runtime environment that the 'ecmascript' package provides.
  // The following api.imply calls should match those in ../../ecmascript/package.js,
  // except that coffeescript does not api.imply('modules').
  api.imply('ecmascript-runtime');
  api.imply('babel-runtime');
  api.imply('promise');
  api.imply('dynamic-import');
});
