jquery-autosize
======================

jQuery Autosize **updated for meteor 0.9.0** ("a plugin to automatically adjust textarea height") repackaged for Meteor.

## Installation

1. `meteor add copleykj:jquery-autosize`
1. Call `$(selector).autosize()` in your `Template.templateName.rendered` callback, where `selector` is a jQuery selector.

Example:

````javascript
$textarea = ('#textarea-selector', $(this.firstNode)); // Second argument establishes jQuery context
$textarea.autosize();
````

## Documentation

http://www.jacklmoore.com/autosize/

## Original package

https://github.com/jackmoore/autosize/

## Author

The Meteor repackage was created by Spendflow and updated by Kelly Copley (@copleykj) for the new 0.9.0 packaging system.
