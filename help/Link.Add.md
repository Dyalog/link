# Link.Add

    ]LINK.Add <items>

    msg ← ⎕SE.Link.Add items                                      

This function allows you to add one or more existing APL items to the link, creating the appropriate representation in the linked directory. The file will be created/updated whether the linked namespace is watched or not.

This is useful to add arrays to a linked directory, because arrays are ignored by default (unless using the `-arrays` modifier with [Link.Create](Link.Create.md) and [Link.Export](Link.Export.md)). Since array files are never ignored, the Add needs to be done only once, then subsequent load from directory will always get the linked arrays.

This is also useful to force updating a linked file from the current APL definition, for example if not watching the namespace, or if modified an array by running APL code.

Note: You can create or update an item from source while adding it to the Link by calling [Link.Fix](Link.Fix.md)

#### Arguments

- APL item name(s)

#### Result

- String describing items that were:
  - added (they belong in a linked namespace and were successfully added)
  - not linked (they do not belong to a linked namespace)
  - not found (the name doesn't exist at all)