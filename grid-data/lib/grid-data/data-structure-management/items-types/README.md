Items Types Settings
====================

The following settings can be provided for each item type:

* metadataGenerator: read documentation in @registerItemTypeGenerator().
* is_collection_item: if true, items of this type will be regarded as collection
                      items. We'll look for their _id field to trigger all the
                      reactivity capabilities the items of the default type has.
* getForcedItemFields(): Optional method that returns an object. If provided, when the grid
                         will access items of this type it will appear as if they have the
                         fields returned by the object, will override existing fields with the
                         same key.