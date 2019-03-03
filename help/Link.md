# Getting started with `Link`

`Link` streamlines working with code in text files by mapping workspace content and filesystem content in a one-to-one relationship. Each unscripted namespace (created by `⎕NS` rather than `⎕FIX`) is associated with a directory of matching name while other workspace content (defined functions and scripted objects) are associated with one file per item.

## Scope

By default, `Link` will update files with changes made in a Dyalog Edit window (not not through `←`, `⎕NS`, `⎕FX`, `⎕FIX` or the APL line "del" editor). Under Microsoft Windows, it will also watch the file system for changes to the linked directory, modifying the linked namespace accordingly. Watching the file system is planned for other operating systems in the near future.

Variables (`⎕NC` of 2.1) and functions/operators without a text source (`⎕NC` of 3.3 or 4.3, namely derived functions, trains and covers for primitives) are not currently supported outside defined functions and scripted objects, but support for these is planned in the near future.

When creating an unscripted namespace, we recommend using `⎕NS` dyadically to name the created namespace (for example `'myproject'⎕NS⍬` rather than `myproject←⎕NS⍬`). This avoids a generic display form (for example `#.myproject` rather than `#.[namespace]`) and makes reference errors less likely.

## Syntax

`Link` provides a set of utility functions (see [the wiki](https://github.com/Dyalog/link/wiki) for a list) in the namespace `⎕SE.Link`, and if SALT and user commands are enabled then, additionally, a `LINK` group of user commands are available.

For performance and ease of debugging, we recommend avoiding the invocation of user commands under program control. Use the utility functions directly instead.

### Utility functions

The general syntax of the utility functions is

```apl
options FnName arg
```
where `options` is a namespace with variables named according to the option they set, containing their corresponding values. `arg` is a simple character vector or a two element vector of character vectors, depending on the specific function.

### User commands

The corresponding user commands have the general syntax
```apl
]LINK.CmdName arg1 [arg2] [-name[=value] ...]
```
where `arg2`'s presence depends on the specific command, and `-name` is a flag enabling the specific option and `-name=value` sets the specific option to a specific value. The value of the two options requiring array values (`codeExtensions` and `typeExtensions`) are instead the *name* of a variable containing the need array.

## Usage

In most cases, it is unnecessary to use any custom options. `Link` will infer what to do in the first three of the following four cases:

1. The namespace is empty or doesn't exist and the directory is empty or doesn't exist.
1. The namespace is empty or doesn't exist but the directory has content
1. The namespace has content but the directory is empty or doesn't exist
1. The namespace has content and the directory has content

In the first three cases (where no more than one side has content), `Link` will export/import any content to the other side, and set up tracking of future changes. In the last case, the `source` option must be specified as `ns`, `dir`, or `none` , and the selected side's content will overwrite the other side. Use this with caution!

### Basic example

#### Workspace to filesystem

We create a namespace in the workspace, and populate it with a couple of defined functions. We could use the Edit window, but for the clarity of this example, we will define the functions straight in the session:
```apl
      'stats'⎕NS⍬
      stats.⎕FX 'Root←{⍺←2' '⍵*÷⍺}'
      stats.⎕FX 'mean←Mean vals;sum' 'sum←+⌿,vals' 'mean←sum÷1⌈⍴,vals'
      stats.StdDev←{2 Root(+.×⍨÷⍴),⍵-Mean ⍵}
```
We can now establish our namespace on the disk as follows:
```apl
      ]LINK.Create stats /tmp/stats
Linked: #.stats ←→ C:\tmp\stats
```
The double arrow, `←→`, indicates that changes on both sides (namespace and directory) will be synchronised to the other side:
```apl
      ⎕NINFO⍠1⊢'/tmp/stats/*'
  /tmp/stats/Mean.aplf  /tmp/stats/Root.aplf  /tmp/stats/StdDev.aplf  
```
#### Filesystem to workspace

Beginning with a new APL session, we can link a populated directory with any non-existing or empty namespace:

```apl
      )CLEAR
clear ws
      ]LINK.Create newstats /tmp/stats
Linked: newstats ←→ C:\tmp\stats
```

#### Adding more content

Now we want to add one more function, using the Edit window:

```apl
      )ED newstats.Median
```

In the Edit window, we complete the function:

```apl
Median←{
     asc←⍋vals←,⍵
     Mean vals[asc[⌈2÷⍨0 1+⍴vals]]
 }
```

Closing the edit window (using the <kbd>Esc</kbs> key) silently creates an additional file:

```apl
      ⎕NINFO⍠1⊢'/tmp/stats/*'
  /tmp/stats/Mean.aplf  /tmp/stats/Median.aplf  /tmp/stats/Root.aplf  /tmp/stats/StdDev.aplf  
```