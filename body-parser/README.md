# Add a POST body-parser middleware to the internal WebApp server

Sometimes you might want to accept url-encoded form POST requests on your Meteor WebApp server, without using Iron Router, such as in the code below:

```javascript
var Fiber = Npm.require('fibers');

WebApp.connectHandlers
.use('/mail', function (req, res) {
    var that = this;
    Fiber(function () {

        var body = req.body;
        ...
        
    }).run();
});
```

This unfortunately does not work out of the box, because there is no body-parser middleware included in the standard Meteor WebApp configuration.

#### How do you make it work? 

Install the `pbastowski:body-parser` package and the above example will work as shown.


### Install:

    meteor add pbastowski:body-parser
    
