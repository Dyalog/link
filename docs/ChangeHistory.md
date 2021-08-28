# Change History
This appendix details the changes made at each version of Link since the release of version 2.0

For a discussion of key differences between 2.0 and 3.0, see [Upgrading to Link 3.0](Upgradeto30.md).

## Version 3.0
* When specifying a directory, a trailing slash is reserved for future extension
  - Public functions now throw errors rather than return an error message when they fail.
  - [Link.Pause](API/Link.Pause.md) has been added
  - Link.List has been renamed to [Link.Status](API/Link.Status.md)
  - [Link.Create](API/Link.Create.md): `source`=`both` has been removed. It used to copy from namespace to directory, then the other way.
  - [Link.Create](API/Link.Create.md): `source`=`auto` has been added. It uses the non-empty side of the link as the source.
  - [Link.Break](API/Link.Break.md) has a `recursive` flag to break all children namespaces if they are linked to their own directories
  - [Link.Import](API/Link.Import.md) and [Link.Export](API/Link.Export.md) have an `overwrite` flag to allow overwriting a non-empty destination
  - [Link.Create](API/Link.Create.md) and [Link.Export](API/Link.Export.md) have an `arrays` modifier to export arrays and a `sysVars` modifier to export namespace-scoped system variables
  - [Link.Create](API/Link.Create.md) has a `fastLoad` flag to reduce the load time by not inspecting source to detect name clashes
  - `beforeWrite` had been split into two callbacks : `beforeWrite` when actually about to write to file, and `getFilename` when querying the file name to use (see the [Link.Create documentation](API/Link.Create.md) for more details).
  - `beforeWrite` and `beforeRead` arguments have been refactored into a more consistent set.
  - [Link.Fix](API/Link.Fix.md) now correctly expects text source for arrays (as produced by ⎕SE.Dyalog.Array.Serialise), as documented, whereas Link 2.0 expected the array itself. Similarly, the source (rather than the array itself) is correctly reported by the `beforeWrite` callback.
- Dyalog APL v18.1 or newer is required for the fixes to the following issues 
  - [#155 Require keyword does not work](https://github.com/Dyalog/link/issues/155)
  - [#149 Link induce status messages](https://github.com/Dyalog/link/issues/149)
  - [#148: Fixing linked function removes all monitor/trace points in it](https://github.com/Dyalog/link/issues/148)
  - [#144: Link can produce unloadable files](https://github.com/Dyalog/link/issues/144)

## Version 2.1

Version 3.0 was labelled version 2.1 during most of its development, until the end of March 2021. It was renumbered just before the beginning of the distribution of official Beta releases of Dyalog Version 18.1. In other words: if you have version 2.1 installed, this is an early version of what became 3.0 and you should upgrade at your earliest convenience.

## Version 2.0

  - [Link.Break](API/Link.Break.md) has an `all` flag to break all links
  - [Link.Version](API/Link.Version.md) reports the current version number  
  - Initial public release