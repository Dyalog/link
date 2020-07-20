# Link Release Notes

 ## Version 2.1.0
  - [Link.Fix](Link.Fix.md) now correctly expects text source for arrays (as produced by ⎕SE.Dyalog.Array.Serialise), as documented, whereas Link 2.0 expected the array itself. Similarly, the source (rather than the array itself) is correctly reported by the `beforeWrite` callback.
  - [Link.Version](Link.Version.md) reports the current version number  
  - [Link.Break](Link.Break.md) now breaks all children namespaces by default, so that `Link.Break #` breaks all link in the workspace. This behaviour can be overriden with the `exact` flag which makes it unlink only argument directories and none of their children.
  - [Link.Break](Link.Break.md) also has an `all` flag to break all links (equivalent to `Link.Break # ⎕SE`)
  - [Link.Create](Link.Create.md) has a `fastLoad` flag to reduce the load time by not inspecting source to detect name clashes
  - `beforeWrite` had been split into two callbacks : `beforeWrite` when actually about to write to file, and `getFilename` when querying the file name to use (see the [Link.Create documentation](Link.Create.md) for more details).
  - `beforeWrite` and `beforeRead` arguments have been refactored into a more consistent set.
  - Name class is reported as `¯9` for traditional namespaces (linked to directories).
    Scripted namespaces remain of name class `9.1` (linked to files).
    Use [Link.NameClass](Link.NameClass.md) to get it. Name class is also reported in `beforeWrite`, `beforeRead` and `getFilename` callbacks.

 ## Version 2.0.0
  - initial public release