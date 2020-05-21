# Link Release Notes

 ## Version 2.1.0
  - [Link.Version](Link.Version.md) reports the current version number  
  - [Link.Break](Link.Break.md) now breaks all children namespaces by default, so that `Link.Break #` breaks all link in the workspace. This behaviour can be overriden with the **exact** flag which makes it unlink only argument directories and non of their children.
  - [Link.Break](Link.Break.md) also has a **all** flag to break all links
  - [Link.Create](Link.Create.md) has a **fastLoad** flag to reduce the load time by not inspecting source to detect name clashes
  - **beforeWrite** had been split into two callbacks : **beforeWrite** when actually about to write to file, and **getFilename** when querying the file name to use.
  - **beforeWrite** and **beforeRead** arguments have been refactored into a more consistent set.
  - Name class is reported as `¯9` for traditional namespaces (linked to directories)
    Scripted namespaces remain of name class `9.1` (linked to files)
    Use [Link.NameClass](Link.NameClass.md) to get it. Name class is also reported in **beforeWrite**, **beforeRead** and **getFilename** callbacks.

 ## Version 2.0.0
  - initial public release