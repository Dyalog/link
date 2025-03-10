# History of source files as text in Dyalog

Link is another step in the journey from binary workspaces to APL source in text files.

### Workspaces

Historically, APL systems have used *saved workspaces* as the way to store the current state of the interpreter in a binary file which contains a collection of code and data. In many ways, a workspace is similar to a workbook saved by a spreadsheet application; a very convenient package that contains everything the application needs to run. Saving the workspace at the end of a run preserves updated data, as well as any code changes that might have been made.

### Component Files and SQL Databases

Workspaces are very convenient, but the binary format makes them awkward if you want to compare, or otherwise manage, different versions of the source code - or the data, for that matter. Users preferred to store their data in component files or other storage mechanisms. As teams started writing larger systems, many development teams also created their own source code management systems (SCMs), typically storing multiple versions of code in component files or SQL tables.

These SCMs served large developer teams well for several decades. However, none of them became tools that were shared by the APL community, and they all suffered from the fundamental problem of using binary formats.

*[SQL]: Structured Query Language
*[SCM]: Source Code Manager
*[SCMs]: Source Code Managers

### SALT - the Simple APL Library Toolkit

In 2006, Dyalog APL Version 11.0 introduced Classes and the ability to represent Namespaces as text "scripts". With that release, Dyalog APL included a tool known as [SALT](https://docs.dyalog.com/latest/SALT%20User%20Guide.pdf), which supported the use of Unicode text files as backing for the source of not only classes and namespaces, but functions, operators and variables as well. At the same time, a component named SPICE added user commands to Dyalog APL, using text source files which implemented a specific API, based on SALT's file handling.

SALT is Link's direct predecessor, and has many of the same features as Link:

* The ability to load entire directory structures into the workspace as namespaces
* A tool called "Snap", which would write all or selected parts of a workspace to corresponding source files.
* A hook in the APL system editor, which would update source files as soon as code was edited, without requiring a separate save operation.
* Startup processing of files with a `.dyapp` extension, to allow launching applications from text files without requiring a "boot workspace".

### Link 2.0

After SALT had grown organically for more than a decade, it was decided that this functionality should be re-implemented in a new system: the Link project began. The first version of Link that was released to the general public was 2.0. The main differences between Link and SALT are:

* Link delegates the task of maintaining information about external source files to the APL interpreter, rather than using a trailing comment in functions and operators or "hidden" namespaces for classes and namespaces to track this information.
  * New interpreter functionality based on `2 ⎕FIX` makes it possible for the interpreter to preserve source code exactly as typed, when an external source file is used.
* A file system watcher added support for using external editors and immediately replicating the effect of SCM system actions, such as a git pull or revert operation, inside the active workspace.
* Rather than using the extension `.dyalog` for all source, Link uses different extensions for different types of source, such as `.aplf` for functions, `.apln` for namespaces, and `.apla` for arrays.
* Use of a model of the proposed [Literal Array Notation](https://aplwiki.com/wiki/Array_notation) to represent arrays, rather than the notation used by SALT.
  * We hope to add support for the array notation to the Dyalog APL interpreter in a future release.

*  Link has no source code management features; the expectation is that users who require SCM will combine Link with an external SCM such as Git or SVN
  * SALT included a simple mechanism for storing and comparing multiple versions of the source for an object by injecting digits into the file name.

### Link 3.0 (Dyalog version 18.2, 2022)

Link 3.0 is the first major revision of Link. It added:

* Support for saving workspaces containing links and resuming work after a break.
* Support for names which differ only in case (for example, `FOO` vs `Foo`) in case-insensitive file systems, by adding "case coding" information to the file name.
* The `Link.LaunchDir` API function, makes it straightforward to determine the folder that APL was launched on, simplifying the task of  launching the interpreter using a configuration file or single APL source file.
* Dyalog version 18.2, released at the same time as Link 3.0, supports identifying a directory with the `LOAD=` parameter - as an alternative to a workspace, APL source file, or a configuration file. When `LOAD` identifies a directory, a link will be created on startup (and the function `Run` invoked, if it exists).

A more complete description of Link 3.0 and the differences between Link 2.0 and 3.0 can be found in the [Link 3.0 documentation](https://dyalog.github.io/link/3.0/).

### Link 4.0 (Dyalog version 19.0, 2024)

Link 4.0 was the companion release to Dyalog version 19.0 in 2024. The most important new features are:

* Configuration files to store options for a user or a source code folder
* The ability to store multi-line character data in plain text files
* Support for linking a single source file defining a namespace or class

More details regarding the new features of Link 4.0 can be found in the [Release Notes](../ReleaseNotes40.md). 

Link 4.0 is upwards compatible with Link 3.0, and can also be used with Dyalog version 18.2.

### Link 4.1 (Dyalog version 20.0, 2025)

Link 4.1 was the companion release to Dyalog version 20.0 in 2025. In this release, we've focused on improving stability and preformance, expecially when a large number files are changed simultaneously. We've also fixed a number of bugs.

Link 4.1 is upwards compatible with Link 4.0, and can also be used with Dyalog version 19.0.

