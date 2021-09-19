# Link.GetItemName 

    items ←  ⎕SE.Link.GetItemName files 

Returns the name of the fully qualified APL item that is linked to a file. See also [⎕SE.Link.GetFileName](Link.GetFileName.md).

#### Arguments

- A simple vector containing a file name, or a vector of enclosed names. The result will have the same structure as the argument.

#### Result

- For each file name:
  - if file does not exist or does not belong to a linked directory: empty vector
  - otherwise : item name that the file is linked to
