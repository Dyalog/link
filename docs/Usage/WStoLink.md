# Converting an Existing Workspace to use Link

## Exporting APL names from the active workspace
By using [Link.Create](/API/Link.Create), the contents of the namespace argument will be written to text files in the specified empty folder and a link will be established between that folder and the namespace. Changes made to the code in the active workspace using the Dyalog editor (invoked, for example, using `)ED`) will be reflected automatically in the text files, and changes made to the text files will be reflected in the active workspace.

By using [Link.Export](/API/Link.Export), the contents of the namespace argument will be written to text files in the specified empty folder but a link will not be established. Changes made to the text files will only be in the text files, and changes made in the active workspace will only be in the active workspace.

In principle, it should be possible to write the entire contents of any workspace to an empty folder called `/folder/name` using the following:

```APL
      'options'⎕NS⍬
      options.(arrays sysVars)←1
      options ⎕SE.Link.Create # /folder/name
```

or equivalently, using the user command:

```APL
      ]LINK.Create # /folder/name -arrays -sysVars
```

## Options

### -arrays

By default, Link assumes that the "source code", only includes functions, operators, namespaces and classes. Variables are assumed to contain data which can either be erased or stored in some kind of database, rather than being part of the source. The `-arrays` causes all arrays in the workspace to be writte to source files as well (see the documentation for [Link.Create](/API/Link.Create.md) for more options).

### -sysVars

By default, Link will assume that you do **not** wish to record the settings for system variables, because your source will be loaded into an environment that already has the desired settings. If you want to be 100% sure to re-create your workspace exactly as it is, you can use `-sysVars` to record the values of system variables from each namespace in source files.

Beware that this might add a *lot* of mostly redundant files to your repository. It is probably a better idea to analyse your workspace carefully and only write system variables to file if you really need them, using the [Link.Add](/API/Link.Add.md).

## Workspaces containing Namespaces

If your workspace is logically divided up into namespaces and you are happy for them all to end up in the same directory, you can use a single call to [Link.Create](/API/Link.Create.md) like the one at the beginning of this section to write everything out at once. If you don't want the workspace to end up as a single directory tree, you can either restructure things afterwards using file explorers or command line tools, or you can make several calls to [Link.Create](/API/Link.Create.md) to write the contents to different locations.

If you create more than one source directory, you will need make more than one call to Link.Create or Link.Import in order to re-create the workspace in order to run your code.

## Flat Workspaces and the `-flatten` Switch

If your workspace is not divided into namespaces, but all your code and data are in the root (or #) namespace, it probably still consists of more than logically distinct sets of code ("modules"), that you wish to manage separately. In this case, all the source files will end up in the same folder.

If you subsequently separate the code into separate folders in order to make the source more manageable, a `-flatten`switch allows you to bring them everything back into the original "flat" workspace structure, so that the application will run without requiring code changes.

The mappings to source files will be preserved, so that you synchronisation will work if you edit the code in the APL system or using an external editor. However, if you create a new name inside the workspace, Link will not know which folder to write it to, and will prompt you to specify a target folder.

## Recreating the Workspace

In order to recreate the workspace from source, you will need to make one or more calls to `Link.Create` or `Link.Import`. For some ideas on how to set this up, see [Setting up your Environment](Setup.md).