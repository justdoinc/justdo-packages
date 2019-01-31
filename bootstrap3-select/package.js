Package.describe({
    name: 'stemcapital:bootstrap3-select',
    summary: 'Bootstrap 3 "select" styling, based on https://github.com/silviomoreto/bootstrap-select, forked from: https://github.com/leebenson/bootstrap3-select/',
    version: '1.1.0'
});

Package.onUse(function(api) {
    var path = Npm.require('path');
    var assets = path.join('bootstrap-select', 'dist');

    api.addFiles([
        path.join(assets, 'css', 'bootstrap-select.css'),
        path.join('bootstrap-select/js/bootstrap-select.js')
    ], 'client');
});
