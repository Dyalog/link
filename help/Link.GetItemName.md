# Link.GetItemName 

    items ←  ⎕SE.Link.GetItemName files 

Returns the name of the fully qualified APL item that is linked to a file. See also the inverse function [Link.GetFileName](Link.GetFileName.md).

#### Arguments

- file name(s) specifying the full path(s) to files or folders within a linked directory

#### Result

- for each file name:
  - if file does not exist or does not belong to a linked directory: empty vector
  - otherwise : item name that the file is linked to
