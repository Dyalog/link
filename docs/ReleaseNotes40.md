# Version 4.0 Release Notes

!!! Note
     This page describes differences between Link version 3.0 and 4.0. 
     Change history for earlier releases,
     and instructions on migrating to Link from SALT, can be found in the
     [Link version 3.0 documentation](https://dyalog.github.io/link/3.0/).

Link version 4.0 is distributed with Dyalog APL version 19.0 and can be used with version 18.2. For instructions on using Link 4.0 with APL version 18.2, see the [installation instructions](Usage/Installation.md).

This page describes the most important enhancements to Link, delivered in version 4.0. For a complete list of changes, see the [version 4.0 milestone on GitHub](https://github.com/Dyalog/link/milestone/2).

## New Features

The following features have been implemented:

* [Configuration files](Usage/ConfigFiles.md):
    - A user configuration file for recording preferences that apply to all links, for example link creation options like -watch=
    - Directory configuration files store options that should be re-applied when the directory is subsequently linked, including stop and trace settings
    - If you are investigating problems in Link, you can turn off error trapping within Link API functions, or receive notification in the APL session each time Link performs an action related to external files.

!!! Note
     Link.Create, Import and Export have a new switch -ignoreconfig, which allows you
     to ignore a damaged or otherwise inappropriate configuration file.

* Creating a Link from single class or namespace files in addition to linking directories.
  
    - Note that configuration files cannot be created for single-file links

* Link.Create, Import and Export will default to the current namespace if no namespace is specified. For example,

```
      )cs #
      ]link.export /tmp/myapp
```

... will export everything in the current workspace to a folder called `/tmp/myapp`.

* Link.Create and Import will search the Dyalog `Library` folders and user folder specified using `DYALOG_LIB_PATH` for source files. Specifying the file extension is not required, if there is no ambiguity. For example,

```
      ]link.import HttpCommand
Imported: #.HttpCommand ← C:\Program Files\Dyalog\Dyalog APL-64 19.0 Unicode\Library\Conga\HttpCommand.dyalog
```

- Multi-line character data stored in character vectors, character matrices, and vectors of character vectors can optionally be stored in plain text files (as opposed to using APL Array Notation). See [Array Formats](Usage/Arrays.md) for more information.

- When defining functions or operators in the active workspace, `Link.Create` will update information about the most recent change using file information reported by the operating system. This information is reported by `⎕AT`, `20 21 22 ⎕ATX`, and the Workspace Explorer. 

!!! Note
     This is not the information that would be reported by a source code management system like Git - you need to use a Git, SVN or similar client to view more detailed information about changes to the source.

- Link.Add can evaluate an expression and assign to items before the items are added to the workspace.

```
      ]link.add name←expression 
```

## Deferred Features

The following features were originally in the Link 4.0 milestone, but have been moved to Link 5.0, which will be developed early in 2024.

* The so-called crawler, which will periodically scan for differences between the active workspace and the linked source files, will be implemented immediately after the release of Link 4.0. This feature will detect changes made to the workspace using other mechanisms than the editor, and also make Link independent of having a file system watcher available.
* Using a `.linkignore` file to list names in the active workspace which should be ignored by Link and in particular the crawler.
* The ability to re-establish broken links.
