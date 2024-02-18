# Array Formats

By default, Link uses *APL Array Notation (APLAN)* to store arrays in text files. While APLAN is a good format for describing numeric data, nested arrays and many high rank arrays, it is not ideal for storing character data. Link 4.0 introduces experimental support for storing multi-line character data in simple text files.

The configuration setting `noTextFiles` can be used to disable this support: If `noTextFiles` is set to 1, all arrays will be store using APLAN. You can set this option when a link is created, or using [`Link.Configure`](../API/Link.Configure).

## File Extensions for Simple Text Files

Text files which are not in APLAN format will have a penultimate section in the file name which records the format of the original array in the workspace:

| File Extension | Array format                         |
| -------------- | ------------------------------------ |
| .nl.apla       | Simple Vector delimited by ⎕UCS 10   |
| .cr.apla       | Simple vector delimited by ⎕UCS 13   |
| .vec.apla      | Vector of enclosed character vectors |
| .mat.apla      | Character matrix                     |
|  .apla         |Without one of the above extensions, the file is in APLAN and could represent any APL array.|

