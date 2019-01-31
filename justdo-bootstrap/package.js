Package.describe({
  name: "twbs:bootstrap",
  summary: "A fork of Nemo64's meteor-bootstrap package disguised as twbs:bootstrap", 
  // Note We desguided this pack as twbs:bootstrap so packages that depends on
  // it won't cause it to load and override our rules
  version: "3.3.5" // Should be same as the bootstrap version in use
});

bootstrap_data_pack = 'justdoinc:bootstrap-data@3.3.5'
var pluginOptions = {
  name: 'bootstrap-configurator',
  use: [
    'underscore@1.0.2',
    bootstrap_data_pack
  ],
  sources: [
    'module-definitions.js',
    'distributed-configuration.js',
    'bootstrap-configurator.js'
  ],
  npmDependencies: {}
};

Package._transitional_registerBuildPlugin(pluginOptions);

Package.on_use(function (api) {
  api.versionsFrom("METEOR@0.9.2.2");
  api.use([
    'jquery',
    bootstrap_data_pack
  ], 'client');
});
