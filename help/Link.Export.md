# Link.Export

    ]LINK.Export <ns> <dir> [-overwrite] [-casecode] [-arrays{=name1,name2,...}] [-sysvars]

    msg ← {opts} ⎕SE.Link.Export (ns dir) 

This function takes the same arguments as [Link.Create](Link.Create.md) but saves the contents of a namespace to directory without maintaining a Link.

If the source is an unscripted namespace, then the destination is taken as a directory.

If the source is anything else, then the destination is taken as a directory (and a correctly named file will be created there) unless it ends with a recognised extension, in which case it's taken as a file name.

#### Arguments

- source : unscripted namespace or APL name
- destination: directory or file name

#### Options

- `overwrite`: Allow overwriting files in the destination directory
- other options have same effect as in [Link.Create](Link.Create.md)

#### Result

- String describing the exported source and destination, along with possible failures