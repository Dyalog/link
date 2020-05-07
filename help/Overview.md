As described on the [Home](Home) page, each link maps a namespace in the active workspace to a file directory. If the directory
has sub-directories, similarly named sub-namespaces will be exist in the workspace. Each file within the directory structure maps to a single 
named item (variable, function, operator, scripted namespace or class). Depending on which synchronisation options have been
selected, Link will synchronise changes in none, one or both directions.

### Creating Links

Links are created using [`Link.Create`](Link.Create), or the corresponding user command `]LINK.Create`.
Both of these take two arguments: the name of a namespace and the corresponding directory 
that it should be linked to. So long as there is only content in either the namespace or
the directory (or neither), pre-existing content will be replicated on the other side of the link,
and all available synchronisation will be enabled depending on the platform.

If both the namspace and the directory have pre-existing content, the `source` option 
*must* be specified as one of `ns`, `dir`, or `none`, and content will be copied in one direction,
potentially overwriting any content on the other side. Use this with caution!

### Create a Directory from a Namespace

To get started, we will create a namespace and populate it with three defined functions in order to 
have something to work with. In this example, the functions are created under program control; under normal use
the functions would probably be created using the editor:
```apl
      'stats' ⎕NS ⍬
      stats.⎕FX 'Root←{⍺←2' '⍵*÷⍺}'
      stats.⎕FX 'mean←Mean vals;sum' 'sum←+⌿,vals' 'mean←sum÷1⌈⍴,vals'
      stats.StdDev←{2 Root(+.×⍨÷⍴),⍵-Mean ⍵}
```
Assuming that the directory /tmp/stats is empty or does not exist, we can now link the stats
namespace to it using the [`Link.Create`](Link.Create) API function, or as in this case using
the user command with the same name:
```apl
      ]LINK.Create stats /tmp/stats -source=ns
Linked: #.stats ←→ C:\tmp\stats
```
The double arrow `←→` in the output indicates that bi-directional synchronisation is active.
We can verify that the three expected files have been created:
```apl
      ls←⎕NINFO⍠1 ⍝ List files, allowing wildcards
      ls '/tmp/stats/*'
  /tmp/stats/Mean.aplf  /tmp/stats/Root.aplf  /tmp/stats/StdDev.aplf  
```
### Start or Resume Work based on a Directory

Once the directory exists and contains our source code, we can start work in an APL session using exactly the same
command as we used to create the directory, but there's no need to specify the source since `dir` is the default. This time (so long
as the target namespace does not exist in the active
workspace), the directory is used as the source:

```apl
      )CLEAR
clear ws
      ]LINK.Create stats /tmp/stats
Linked: stats ←→ C:\tmp\stats
      stats.⎕NL -3 ⍝ Verify functions were loaded as expected
 Mean  Root  StdDev
```

### Adding Content

Since bi-directional synchronisation has been set up, we are free to add content either by
adding new source files in the directory, or using the editor inside the APL session.
For example, we could add a `Median` function:

```apl
      )ED stats.Median
```

In the Edit window, we complete the function:

```apl
Median←{
     asc←⍋vals←,⍵
     Mean vals[asc[⌈2÷⍨0 1+⍴vals]]
 }
```

Closing the edit window (using the <kbd>Esc</kbd> key) will not only fix the definition of the
function in the namespace, it will also cause a new file to be created containing the
source code for the new function.


```apl
      ls '/tmp/stats/*'
  /tmp/stats/Mean.aplf  /tmp/stats/Median.aplf  /tmp/stats/Root.aplf  /tmp/stats/StdDev.aplf  
```

If full synchronisation is not enabled,
[`Link.Refresh`](Link.Refresh) can be used to re-synchronise
the namespace and directory.

### Changes made Under Program control

Note that external source files are only updated when items are modified using the editor.
Changes made under program control using assignment (`←`) or system functions 
like `⎕CY`, `⎕NS`, `⎕EX`, `⎕FX` or `⎕FIX` will ***NOT*** trigger synchronisation.
This is intentional and not expected to change. 

The API functions [`Link.Fix`](Link.Fix) and [`Link.Expunge`](Link.Expunge)
can be used to inform link that a change which has been made under program control should be
considered a change to application source, and cause synchronisation. Similarly,
[`Link.Notify`](Link.Notify) can be used to bring an external change into the active workspace, even though
synchronisation is not active.

### Current Limitations

* The detection of external changes to files and directories is currently only supported under Microsoft Windows. However, changes to a file will be reflected in the namespace if the file's item is opened in APL's editor, on all platforms.
* The detection of external changes to files and directories is currently only supported if `source` was not set to `ns`
* Changes made using the del editor (`∇`) are not currently detected.
* Functions, operators and namespaces without text source (`⎕NC` of 3.3 or 4.3, 
namely derived functions/operators, trains and named primitives), are not supported.

### Tips and Recommendations
When creating a namespace for use with Link, it is recommend to use named namespaces (created using dyadic `⎕NS`)