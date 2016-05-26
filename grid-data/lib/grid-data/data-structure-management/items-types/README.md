Items Types Settings
====================

The following settings can be provided for each item type:

* metadataGenerator: read documentation in @registerItemTypeGenerator().
* is_collection_item: if true, items of this type will be regarded as collection
                      items. We'll look for their _id field to trigger all the
                      reactivity capabilities the items of the default type has.