# Version 4.2 Release Notes

Link version 4.2 is distributed with Dyalog APL version 21.0.
You can select documentation for other versions of Link using the dropdown in the title bar.

Link 4.2 changes how stop and trace settings are recorded, and includes a number of bug fixes.
For differences between Link 4.0 and 4.1, see the [Version 4.1 Release Notes](https://dyalog.github.io/link/4.1/ReleaseNotes41/).

## Recording Stop and Trace Settings is Now Optional

In Link 4.1, `⎕STOP` and `⎕TRACE` settings for functions and operators in a linked directory were always
recorded in the `SourceFlags` section of the directory's [configuration file](Usage/ConfigFiles.md#stop-and-trace-flags).
In Link 4.2, this is controlled by a new [`recordFlags`](API/Link.Create.md#recordflags) setting, which is **off** by default.

To keep recording stop and trace settings for a directory, set `recordFlags` in its configuration file:

```
      ]link.configure c:\tmp\linkdemo recordFlags:1
```

or set it in your user configuration file to turn it on for all links:

```
      ]link.configure * recordFlags:1
```

Stop and trace settings are not recorded for links to a single file.

## Behaviour Changes

### Link.Create -source=dir into a namespace that is not empty

`Link.Create` with `source` set to `dir` no longer refuses to link a namespace that already contains items which
are not defined by the directory. Items defined by source files are replaced by the file contents; other items
are left in place, and are reported by `Link.Diff` as having no corresponding file.
This allows, for example, a partial checkout of a repository to be linked into a workspace that already contains the whole application
([#788](https://github.com/Dyalog/link/issues/788)).

With `source` set to `auto`, a non-empty namespace can still only be linked to a non-empty directory if the contents are identical;
otherwise, you must specify `source` explicitly.

### Items are tied to their files when watch=ns

When `watch` is set to `ns` (which is the only option available when .NET is not available), items are now tied to their source files,
as they are when `watch` is set to `both`. Previously, editing an item in a link created with `-flatten`
wrote a new file to the root of the linked directory instead of updating the original file
([#789](https://github.com/Dyalog/link/issues/789)).
Files which contain a `:Require` keyword can now be used with `watch=ns`, not only with `watch=both`.

## Significant Fixes

### Flattened links

* `Link.Diff` and `Link.Resync` reported every item and every file as unmatched in links created with `-flatten`.
  As a consequence, `Link.Create` after `Link.Break` failed with "Destination namespace not empty"
  ([#782](https://github.com/Dyalog/link/issues/782)).
* A directory and a file with the same name in a flattened link were incorrectly reported as clashing APL names
  ([#781](https://github.com/Dyalog/link/issues/781)).

### Stop and trace settings

* Stops were lost when a linked file was independently fixed using `2 ⎕FIX` and edited
  ([#771](https://github.com/Dyalog/link/issues/771)).
* If stop or trace settings cannot be recorded after an item is edited, the warning now includes the reason.

### Other fixes

* `⎕SE.Link.LaunchDir` signalled a DOMAIN ERROR in a clear workspace ([#748](https://github.com/Dyalog/link/issues/748)).
* The file system watcher could fail when a batch of rename events contained no renamed files which still exist
  ([#774](https://github.com/Dyalog/link/issues/774)).

The changes for issues #748, #781, #782, #788 and #789 are also included in Link 4.1.10.
