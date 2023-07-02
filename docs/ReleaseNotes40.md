# Version 4.0 Release Notes

!!! Note
     This page describes differences between Link version 3.0 and 4.0. 
     Change history for earlier releases,
     and instructions on migrating to Link from SALT, can be found in the
     [Link version 3.0 documentation](https://dyalog.github.io/link/3.0/).

Link version 4.0 is distributed with Dyalog APL version 19.0 and can be used with version 18.2. For instructions on using
Ling 4.0 with APL version 18.2, see the [installation instructions](Installation.md).

The the most important enhancements are described on this page. For a complete list of changes, see the [version 4.0 milestone on GitHub](https://github.com/Dyalog/link/milestone/2).

## Implemented Features

The following features have been implemented in the master branch:

* Version 4.0 adds [configuration files](Usage/ConfigFiles.md):
- A user configuration file for recording preferences that apply to all links, for example link creation options like -watch=
- Directory configuration files store options that should be re-applied when the directory is subsequently linked, including stop and trace settings
- If you are investigating problems in Link, you can turn off error trapping within Link API functions, or receive noticiation in the APL session each time Link performs an action related to external files.

## Upcoming Features

* Storing multi-line character data in "flat" text files.
* Creating Links from single source files in addition to linking a folder to a namespace.
* Transfer information about who last changed a source file from Git to `⎕AT` within APL.
* Use a `.linkignore` to list names in the active workspace which should be ignored by Link.

## Deferred Features

* The so-called crawler, which will periodically scan for differences between the active workspace and the linked source files, will be implemented immediately after the release of Link 4.0
