# Link.GetFileName

    files ←  ⎕SE.Link.GetFileName items

Returns the fully qualified name of the file containing the source of the given APL item.  See also [GetItemName](Link.GetItemName.md).

#### Arguments

- APL item name(s)

#### Result

- for each APL item name: 
  - if item does not exist or does not belong to a linked namespace: empty vector
  - otherwise: file name that the item is linked to