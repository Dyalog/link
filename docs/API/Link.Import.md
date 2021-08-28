# Link.Import

    ]LINK.Import <ns> <dir> [-overwrite] [-flatten] [-fastload] 
    
    msg ← {opts} ⎕SE.Link.Import (ns dir)

This function takes the same arguments as [Link.Create](Link.Create.md), but loads a directory containing source files into a namespace without creating a permanent link.

If source is a directory, then its contents are imported into the destination namespace.

If source is a single file, then the corresponding APL name is created in the destination namespace.

#### Arguments

- destination: namespace
- source: directory or file name

#### Options

- `overwrite`: Allow overwriting APL names in the destination namespace
- other options have same effect as in [Link.Create](Link.Create.md)

#### Result

- String describing the imported destination and source, along with possible failures