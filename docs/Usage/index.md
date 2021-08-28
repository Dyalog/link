# Basic Usage
These sections cover the most commonly used commands. For more advanced usage, please consult the [API documentation](/API).

## Starting from text files
Use [Link.Create](/API/Link.Create) to Link a directory containing text source to a namespace in the active workspace.

The following example loads APL code from the folder **/home/sally/myapp** into a namespace called `myapp`.

```APL
      ⎕SE.Link.Create myapp '/home/sally/myapp'
```

For every day use in the session, it might be more convenient to use the user command:
```APL
      ]LINK.Create myapp /home/sally/myapp
```

## Starting from a workspace
If your existing code is in a workspace rather than in source files, you might want to read the section on [converting a workspace to source files](WStoLink.md) before continuing.

## Importing code without creating a link
Sometimes you want to experiment and make modifications to your code without saving those changes. Use [Link.Import](/API/Link.Import) to bring code from text source files into the active workspace without creating a link.

## Starting a new project
If you are starting a completely new project, create either a namespace in the active workspace or a folder on the file system (or both). For [Link.Create](/API/Link.Create) to successfully establish a link, at least one of those must exist and exactly one of them needs to contain some code?

- If neither of them exist, Link.Create will reject the request on suspicion that there is a typo, in order to avoid silently creating an empty directory by mistake.
- If both of them exist AND contain code, and the code is not identical on both sides, Link.Create will fail and you will need to specify the  `source` option, whether the namespace or the directory should be considered to be the source. Incorrectly specifying the source will potentially overwrite existing content on the other side, so use this with extreme caution!

To illustrate, we will create a namespace and populate it with two dfns and one tradfn, in order to have something to work with. In this example, the functions are created using APL expressions; under normal use the functions would probably be created using the editor, or perhaps loaded or copied from an existing workspace.

```apl
      'stats' ⎕NS ⍬ ⍝ Create an empty namespace
      stats.⎕FX 'mean←Mean vals;sum' 'sum←+⌿,vals' 'mean←sum÷1⌈⍴,vals'
      stats.Root←{⍺←2 ⋄ ⍵*÷⍺}
      stats.StdDev←{2 Root(+.×⍨÷⍴),⍵-Mean ⍵}
```
We could now create a source directory using [Link.Export](/API/Link.Export.md), and then use [Link.Create](/API/Link.Create.md) to create a link to it. However, [Link.Create](/API/Link.Create.md) can do this in one step: assuming that the directory `/tmp/stats` is empty or does not exist, the following command will detect that there is code in the workspace but not in the directory, and create a link based on the namespace that we just created:

```apl
      ]LINK.Create stats /tmp/stats -source=ns
Linked: #.stats ←→ C:\tmp\stats
```
The double arrow `←→` in the output indicates that synchronisation is bi-directional. We can verify that the three expected files have been created:

```apl
      ls←⎕NINFO⍠1 ⍝ List files, allowing wildcards
      ls '/tmp/stats/*'
  /tmp/stats/Mean.aplf  /tmp/stats/Root.aplf  /tmp/stats/StdDev.aplf  
```
Let's verify that our source directory can be used to re-build the original namespace::

```apl
      )CLEAR
clear ws
      ]LINK.Create stats /tmp/stats
Linked: stats ←→ C:\tmp\stats
      stats.⎕NL -3 ⍝ Verify functions were loaded as expected
 Mean  Root  StdDev
```

If you have an existing workspace containing several namespaces, code in the root of the workspace, or variables, you will want to read about [converting your workspace to text source](WStoLink.md).

## Saving your work
Once a link is set up using [Link.Create](/API/Link.Create), you can work with your code using the Dyalog IDE exactly as you would if you were not using Link; the only difference being that Link will ensure that any changes you make to the code, using the Dyalog editor, within the `stats` namespace are instantly copied to the corresponding source file. 

!!! Note
	In the context of this document, the term *Dyalog IDE* includes both the Windows IDE and the Remote IDE (RIDE), which is tightly integrated with the interpreter.

Conversely, if you are new to Dyalog APL, and have a favourite editor, you can use it to edit the source files directly, and any change that you make will be replicated in the active workspace. If you do not have a File System Watcher available on your platform, it may be a few seconds before the [Crawler](/Crawler.md) kicks in and detects external changes.

If you use editors inside or outside the APL system to add new functions, operators, namespaces or classes,  the corresponding change will be made on the other side of the link. For example, we could add a `Median` function:

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

When the editor fixes the definition of the function in the workspace, Link will create a new file:


```apl
      ls '/tmp/stats/*'
  /tmp/stats/Mean.aplf  /tmp/stats/Median.aplf  /tmp/stats/Root.aplf  /tmp/stats/StdDev.aplf  
```

## Viewing the status of links
The function [Link.Status](../API/Link.Status.md) will show namespaces that are currently linked and the folders to which they are linked. The user command `]LINK.Status` is a convenient way to use this.

## Unlinking a namespace
To continue using code in the active workspace, but without updating text source files, use [Link.Break](../API/Link.Break.md) (or its user command equivalent.

Clearing the workspace, for example using `)CLEAR`, or exiting Dyalog, for example with `)OFF`, will also break all links in the active workspace.

See the [technical details on breaking links](/Discussion/TechDetails/#breaking-links) for more information, for example about what happens when you delete a linked namespace from the active workspace.

## Changes made Outside the Editor

When changes are made using the editor which is built-in to Dyalog IDE (which includes RIDE), source files are updated immediately. Changes made outside the editor will not immediately be picked up. This includes:

* Definitions created or changed using assignment (`←`), `⎕FX`  or `⎕FIX` - or the APL line "`∇`" editor.
* Definitions moved between workspaces or namespaces using `⎕CY`, `⎕NS` or `)COPY`.
* Definitions erased using `⎕EX`or `)ERASE`

If you write tools which modify source code under program control, it is a good idea to call the API functions [Link.Fix](/API/Link.Fix.md) or [Link.Expunge](/API/Link.Expunge.md) to inform Link that you have made the change.

If you update the source files under program control and inbound synchronisation is not enabled, you can use [Link.Notify](/API/Link.Notify.md) to let Link know about an external change that you would like to bring into the workspace.

## Arrays

By default, Link does not consider arrays to be part of the source code of an application and will not write arrays to source files unless you explicitly request it. Link is not intended to be used as a database management system; if you have arrays that are modified during the normal running of your application, we recommend that you store that data in an RDBMS or other files that are managed by the application code, rather than using Link for this.

However, if you have arrays that represent error tables, range definitions or other *constant* definitions that it makes sense to conside to be part of the source code, you can add them using [Link.Add](/API/Link.Add.md):

```apl
      stats.Directions←'North' 'South' 'East' 'West'
      ]Link.Add stats.Directions
Added: #.stats.Directions
```

Once you have created a source file for an array, Link *will* update that file if you use the editor to modify the array. Note that if you modify the array using assignment or other means than the editor, you will need to call [Link.Add](/API/Link.Add.md) to force and update of the source file.

Changes made to source files, including the addition of new `.apla`files, will always be reflected in the workspace, if the link has been set up to watch the file system.

## Setting up Development and Runtime Environments

We have seen how to use `]Link.Create`to load textual source into the workspace in order to work with it. As your project grows, you will probably want to split your code into modules, for example application code in one directory and shared utilities in another - and maybe also run some code to get things set up.

Next, we will look at [Setting up Development and Runtime Environments](Setup.md), so that you don't have to type the same sequence of things over and over again to get started with development - or running the application.
