# Link.GetFileName

    files ←  ⎕SE.Link.GetFileName items

Returns the fully qualified name of the file containing the source of the given APL item.  See also [⎕SE.Link.GetItemName](Link.GetItemName.md).

#### Arguments

- A simple vector with an APL item name, or a vector enclosed names. The result will have the same structure as the argument.

#### Result

- For each APL item name: 
  - if item does not exist or does not belong to a linked namespace: empty vector
  - otherwise: file name that the item is linked to