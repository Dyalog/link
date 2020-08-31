# Link Release Notes

 ## Version 2.1.0
  - [Link.Create](Link.Create.md): `source`=`both` has been removed. It used to copy from namespace to directory, then the other way.
  - [Link.Create](Link.Create.md): `source`=`auto` has been added. It uses the non-empty side of the link as the source.
  - Link.List has been renamed to [Link.Status](Link.Status.md)
  - [Link.Fix](Link.Fix.md) now correctly expects text source for arrays (as produced by ⎕SE.Dyalog.Array.Serialise), as documented, whereas Link 2.0 expected the array itself. Similarly, the source (rather than the array itself) is correctly reported by the `beforeWrite` callback.
  - [Link.Break](Link.Break.md) has a `recursive` flag to break all children namespaces if they are linked to their own directories
  - [Link.Create](Link.Create.md) has a `fastLoad` flag to reduce the load time by not inspecting source to detect name clashes
  - `beforeWrite` had been split into two callbacks : `beforeWrite` when actually about to write to file, and `getFilename` when querying the file name to use (see the [Link.Create documentation](Link.Create.md) for more details).
  - `beforeWrite` and `beforeRead` arguments have been refactored into a more consistent set.

 ## Version 2.0.0
  - [Link.Break](Link.Break.md) has an `all` flag to break all links
  - [Link.Version](Link.Version.md) reports the current version number  
  - Initial public release