# Link.GetItemName 

Returns the name of the fully qualified APL item that is linked to a file. See also [GetFileName](Link.GetFileName.md).

#### Arguments

- file name(s)

#### Result

- for each file name:
  - if file does not exist or does not belong to a linked directory: empty vector
  - otherwise : item name that the file is linked to
