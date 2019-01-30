Modules Model
=============

Each module should be defined in its own folder. Example: required-actions/

Modules should extend PACK.modules with a new obj property named after the underscored model name. Example:

    _.extend PACK.modules,
      required_actions:

You *can* attach 3 methods to this property:

    _.extend PACK.modules,
      required_actions:
        initBoth: ->
        initServer: ->
        initClient: ->

These methods will be called in the context relevant to their names,
with the `this` keyword set as an object that prototypicaly inherits
from the projects object constructed by the Projects constructor.

All the properties defined in the module definition (under PACK.modules.module_name) will be available under `this` keyword as well (will be part of the "module object").

This object will be available under the main projects object under:
projects.modules[module_name]

*Notes:*

    * Properties set by modules won't be set on the main projects object but only under the module object (due to the proto-inherit nature).
    * Avoid setting initServer in a file available for client - for security.
    * Each module object is initialized with a distinguished logger
    * initBoth will always be called first.