# Converting an Existing Workspace to use Link

In order to start using Link to maintain code that resides in a workspace, you first need to export the code in the workspace to one or more folders.

The simplest way to do this is to use [Link.Export](../API/Link.Export.md). In principle, it should be possible to write the entire contents of any workspace to an empty folder called `/folder/name` using the following:

```APL
      'options' ⎕NS ⍬
      options.(arrays sysVars)←1
      options ⎕SE.Link.Export # '/folder/name'
```

or equivalently, using the user command:

```APL
      ]link.export # /folder/name -arrays -sysvars
```

You can also use [Link.Create](../API/Link.Create.md) with the same arguments, if you want an active link to exist after the export has been done.

## Options

### -arrays

By default, Link assumes that the "source code" only consists of functions, operators, namespaces and classes. Variables are assumed to contain data which is transient and thus not part of the source. The `-arrays` causes all arrays in the workspace to be written to source files as well. You can also write selected variables to file, see the documentation for [Link.Create](../API/Link.Create.md) for more options.

### -sysVars

By default, Link will assume that you do **not** wish to record the settings for system variables, because your source will be loaded into an environment that already has the desired settings. If you want to be 100% sure to re-create your workspace exactly as it is, you can use `-sysVars` to record the values of system variables from each namespace in source files.

Beware that this will add a *lot* of mostly redundant files to your repository. It is probably a better idea to analyse your workspace carefully and only write system variables to file if you really need them, using [Link.Add](../API/Link.Add.md).

## Workspaces containing Namespaces

If your workspace is logically divided up into namespaces and you are happy for them all to end up in the same directory, you can use a single call to [Link.Export](../API/Link.Export.md) or [Link.Create](../API/Link.Create.md) like the one at the beginning of this section to write everything out at once. If you don't want the workspace to end up as a single directory tree, you can either restructure things afterwards using file explorers or command line tools, or you can make several separate calls to Export or Create to write the contents of individual namespaces to different locations.

Of course, if you create more than one source directory, you will need make more than one call to Link.Create or Link.Import in order to re-create the workspace in order to run your code.

## Flat Workspaces and the `-flatten` Switch

If your workspace is not divided into namespaces, but all your code and data are in the root (or #) namespace, it probably still consists of more than logically distinct sets of code ("modules"), that you might wish to manage separately. If you Export such a workspace, all the source files will obviously end up in the same folder.

If you subsequently separate the source files into separate folders in order to make the source more manageable, you can still load it all into a single "flat" namespace using the `-flatten`switch. This allows the code to run unchanged, although you have created a structure for the source.

The mappings to source files will be recorded, so that synchronisation will work if you edit the code in the APL system or using an external editor. If you create a new name inside the workspace, Link will obviously not know which folder to write it to, and will prompt you to specify a target folder.

## Recreating the Workspace

In order to recreate the workspace from source, you will need to make one or more calls to `Link.Create` or `Link.Import`, depending on the structure that you have created. For some ideas on how to set this up, see [Setting up your Environment](Setup.md).