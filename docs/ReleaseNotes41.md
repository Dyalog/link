# Version 4.1 Release Notes

Link version 4.1 is distributed with Dyalog APL version 20.0 and is supported with version 19.0.
You can select documentation for other versions of Link using the dropdown in the title bar.

Apart from these release notes and minor corrections to the documentation, the documentation for version 4.1
is identical to 4.0. Version 4.1 is primarily a bug fix release. A couple of significant groups of
fixes are discussed below,
and the [version 4.1 milestone on GitHub](https://github.com/Dyalog/link/milestone/5?closed=1) documents the full
set of issues that are resolved by version 4.1.

## Control Reformatting

In addition to fixes, Link 4.1 recognises a new environment setting `ALWAYSREFORMAT`,
which turns on automatic reformatting of all source code as it is written to source files.
The following values are accepted:

* ALWAYSREFORMAT=0: Do not reformat the source code
* ALWAYSREFORMAT=1: Reformat using standard tab settings (4), as returned by (`61 ⎕ATX`)
* ALWAYSREFORMAT=2: Use user-configured tab settings, as returned by `⎕CR` or `⎕NR`.

## Link.Create ignores local names

`Link.Create` ignores local names in calling functions when determining whether the target namespace
is empty. This makes it much easier to write functions that load code into a workspace at the 
start of an application. 

## Link.Create -preloaded Allows Optimised Development Environments

If an application uses thousands (or tens of thousands) of source files, `Link.Create` can take a
a significant amount of time. The `-preloaded` switch allows you to build a development workspace
using `Link.Create`, and save this workspace or export the contents a shared code file. At the start
of a development session, you can call `Link.Create` with the `-preloaded` switch, which will
re-establish all metadata related to the link, but skip loading the source code.

## Significant fixes

### Improved Error Messages

Several error messages have been improved. For example, when a file
cannot be imported to a classic interpreter due to a TRANSLATION ERROR,
the file and the offending character is identified.

### Improved File System Watcher

The most significant improvement in version 4.1 is a complete rewrite of the code 
that handles file system watcher events, which increased the performance and the
robustness of Link, when faced with several more or less simultaneous file updates.

For example, when using a source code management system like Git, a branch switch
or a revert operation may cause a flurry of change to files. In Link 4.0, this
could sometimes lead to functions disappearing, or failing to disappear when they should,
as a result of processing messages in the wrong order.

Although Link 4.1 is very much more robust than Link 4.0 in this regard, it is still not
recommended to copy or unzip hundreds or thousands of files with an active file system
watcher.
