# Basic Usage
These sections cover the most commonly used commands. For more advanced usage, please consult the [API documentation](../API/index.md).

## Starting from an existing folder containing text files
Use [Link.Create](../API/Link.Create.md) to Link a directory containing text source to a namespace in the active workspace.

The following example loads APL code from the folder **/users/sally/myapp** into a namespace called `myapp`.

```APL
      ⎕SE.Link.Create myapp '/users/sally/myapp'
```

For ad hoc use in an interactive session, it might be more convenient to use the user command:
```APL
      ]LINK.Create myapp /users/sally/myapp
```

## Linking a directory on startup
If you are using Dyalog version 18.2 or later, you can cause a link to be created to the root of your workspace (`#`) as APL starts, by setting the `LOAD` parameter on the command line or as an environment variable. After establishing the link, the system will call the function `Run` with a right argument containing the name of the directory. You can disable the call to `Run` by including the `-x` switch on the command line (in the same way that the `-x` switch inhibits the execution of the latent expression when loading a workspace).

With a standard Dyalog 18.2 installation under Microsoft Windows, you can also right click on a directory and select "Open with Dyalog" or "Run with Dyalog" to create a link on startup and optionally call `Run`.

## Importing code without creating a link

Sometimes you want to load some code in order to run it, without intending to make any modifications - or you might want to experiment and make modifications to the code, but want to be sure that the source files are not updated. Use [Link.Import](../API/Link.Import.md) to bring code from text source files into the active workspace without creating a link. The syntax of Import is almost identical to Create. The important difference being that changes to code in the workspace or in source files are not tracked or acted upon following an Import. For example:

```apl
      ]LINK.Import myapp /users/sally/myapp
```

## Starting a new project
If you are starting a completely new project, you can either create a namespace in the active workspace, or a folder on the file system (or both), and use [Link.Create](../API/Link.Create.md), naming the namespace and the folder, as in the example at the start of this page.

- If neither of them exist, Link.Create will reject the request on suspicion that there is a typo, in order to avoid silently creating an empty directory by mistake.
- If both of them exist AND contain code, and the code is not identical on both sides, Link.Create will fail and you will need to specify the  `source` option, whether the namespace or the directory should be considered to be the source. Incorrectly specifying the source will potentially overwrite existing content on the other side, so use this with extreme caution!

To illustrate, we will create a namespace and populate it with two dfns and one tradfn, in order to have something to work with. In this example, the functions are created using APL expressions; under normal use the functions would probably be created using the editor, or perhaps loaded or copied from an existing workspace.

```apl
      'stats' ⎕NS ⍬ ⍝ Create an empty namespace
      stats.⎕FX 'mean←Mean vals;sum' 'sum←+⌿,vals' 'mean←sum÷1⌈⍴,vals'
      stats.Root←{⍺←2 ⋄ ⍵*÷⍺}
      stats.StdDev←{2 Root(+.×⍨÷⍴),⍵-Mean ⍵}
```
We could now create a source directory using [Link.Export](../API/Link.Export.md), and then use [Link.Create](../API/Link.Create.md) to create a link to it. However, [Link.Create](../API/Link.Create.md) can do this in one step: assuming that the directory `/users/sally/stats` is empty or does not exist, the following command will detect that there is code in the namespace but not in the directory, and create a link based on the namespace that we just populated with our functions:

```apl
      ]LINK.Create stats /users/sally/stats
Linked: #.stats ←→ C:\tmp\stats
```
The double arrow `←→` in the output indicates that synchronisation is bi-directional. If .NET is not available, the default will be to only replicate changes in the namespace to file, which will be indicated by a `→`. We can check that the three expected files have been created:

```apl
      ls←⎕NINFO⍠1 ⍝ List files, allowing wildcards
      ls '/users/sally/stats/*'
  /users/sally/stats/Mean.aplf  /users/sally/stats/Root.aplf  
  /users/sally/stats/StdDev.aplf  
```
We can also verify that the new source directory can be used to re-build the original namespace::

```apl
      )CLEAR
clear ws
      ]LINK.Create stats /users/sally/stats
Linked: stats ←→ users/sally/stats
      stats.⎕NL -3 ⍝ Verify functions were loaded as expected
 Mean  Root  StdDev
```

## Starting a project from a workspace

If your existing code is in a workspace rather than in text files, you should read the section on [converting a workspace to source files](WStoLink.md) before continuing.

## Saving your work
Once a link is set up using [Link.Create](../API/Link.Create.md), you can work with your code using the Dyalog exactly as you would if you were not using Link; the only difference being that Link will ensure that any changes you make (using the APL editor) to the code within the `stats` namespace are instantly copied to the corresponding source file.

In the context of this document, the term *Dyalog IDE* includes both the Windows IDE and the Remote IDE (RIDE), which is tightly integrated with the interpreter.

The use of a source code management system like Git is recommended. If you do that, then you effectively save your work by doing a commit.

Conversely, if you are new to Dyalog APL, and have a favourite editor, you can use it to edit the source files directly, and any changes that you make will be replicated in the active workspace - assuming that .NET (Framework, or 6.0 and later versions) is available and your APL system is configured to use it.

!!! Note 
	Note that, although a so-called .NET *File System Watcher* (FSW) is useful for immediately picking up changes made using an external editor, a FSW is *NOT* a reliable mechanism for deployment of new code to running systems. For example, running a server with an active link and patching it simply by modifying linked source files IS *NOT RECOMMENDED*.

If you use editors inside or outside the APL system to add new functions, operators, namespaces or classes,  the corresponding change will be made on the other side of the link. For example, we could add a `Median` function to the namespace we created earlier:

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
      ls '/users/sally/stats/*'
  /users/sally/stats/Mean.aplf  /users/sally/stats/Root.aplf  
  /users/sally/stats/StdDev.aplf /users/stats/StdDev.aplf  
```

## Viewing the status of links
The function (and corresponding user command) [Link.Status](../API/Link.Status.md) will show namespaces that are currently linked and the folders to which they are linked. For example:

```apl
       ]link.status
 Namespace  Source               Files
 #.stats    /users/sally/stats       4  
```

## Un-Linking a namespace
To continue using code in the active workspace without the risk of updating text source files or picking up changes made using external editors, use [Link.Break](../API/Link.Break.md).

Clearing the workspace, for example using `)CLEAR`, or exiting Dyalog, for example with `)OFF`, will also break all links in the active workspace.

See the [technical details on breaking links](../Discussion/TechDetails.md#breaking-links) for more information, for example about what happens when you delete a linked namespace from the active workspace.

## Changes made outside the Editor

When changes are made using the editor which is built-in to Dyalog APL (Windows IDE or RIDE), source files are updated immediately. Changes made outside the editor will not immediately be picked up. This includes:

* Definitions created or changed using assignment (`←`), `⎕FX`  or `⎕FIX`.
* Definitions moved between workspaces or namespaces using `⎕CY`, `⎕NS` or `)COPY`.
* Definitions erased using `⎕EX`or `)ERASE`

If you write tools which modify source code under program control, such as linters or search/replace tools, you should call the API functions [Link.Fix](../API/Link.Fix.md) or [Link.Expunge](../API/Link.Expunge.md) to update the definitions, so that Link can take appropriate action such as updating source files.

If you update the source files under program control and inbound synchronisation is not enabled, you can use [Link.Notify](../API/Link.Notify.md) to let Link know about an external change that you would like to bring into the workspace.

## Arrays

By default, Link does not consider arrays to be part of the source code of an application and will not write arrays to source files unless you explicitly request it. Link is not intended to be used as a database management system; if you have arrays that are modified during the normal running of your application, we recommend that you store that data in an RDBMS or other files that are managed by the application code, rather than using Link for this.

However, if you have arrays that represent error tables, range definitions or other *constant* definitions that it makes sense to conside to be part of the source code, you can add them using [Link.Add](../API/Link.Add.md):

```apl
      stats.Directions←'North' 'South' 'East' 'West'
      ]Link.Add stats.Directions
Added: #.stats.Directions
```

By default, Link uses *APL Array Notation* to store arrays in text files. Link 4.0 introduced experimental support for storing multi-line character data in simple text files. For more information, see the section on [array formats](../Usage/Arrays.md).

Once you have created a source file for an array, Link *will* update that file if you use the editor to modify the array. Only if you modify the array using assignment or other means than the editor will you need to call [Link.Add](../API/Link.Add.md) to force an update of the source file.

Changes made to source files, including the addition of new `.apla`files, will always be reflected in the workspace, if the link has been set up to watch the file system.

## Setting up Development and Runtime Environments

We have seen how to use `]Link.Create`to load textual source into the workspace in order to work with it. As your project grows, you will probably want to split your code into modules, for example application code in one directory and shared utilities in another - and maybe also run some code to get things set up.

Next, we will look at [Setting up Development and Runtime Environments](Setup.md), so that you don't have to type the same sequence of things over and over again to get started with development - or running the application.
