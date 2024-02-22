# Link.Import

    ]LINK.Import [ns] <dir> [-overwrite] [-flatten] [-fastload] [-ignoreconfig]
    
    msg ← {opts} ⎕SE.Link.Import (ns dir)

!!! ucmdhelp "Show User Command information in the session with `]LINK.Import -?`"

This function takes the same arguments as [Link.Create](Link.Create.md), but loads a directory containing source files into a namespace without creating an active link.

If source is a directory, then its contents are imported into the destination namespace.

If source is a single file, then the corresponding APL name is created in the destination namespace.

#### Arguments

- ns: namespace. If `ns` is not provided, it defaults to the current namespace.
- dir: directory or file name

#### Options

- `overwrite`: Allow overwriting APL names in the destination namespace
- other options have same effect as in [Link.Create](Link.Create.md)

#### Result

- String describing the imported destination and source, along with possible failures
