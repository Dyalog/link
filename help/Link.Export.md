# Link.Export

This function takes the same arguments as [Create](Link.Create.md) but saves the contents of a namespace to directory without
creating a Link.

If the source is an unscripted namespace, then the destination is taken as a directory.

If the source is anything else, then the destination is taken as a directory (and a correctly named file will be created there) unless it ends with a recognised extension, in which case it's taken as a file name.

#### Arguments

- source : unscripted namespace or APL name
- destination: directory or file name

#### Options

- `overwrite`: Allow overwriting files in the destination directory

#### Result

- String describing the exported source and destination, along with possible failures