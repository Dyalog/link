
#### Arguments

- **namespace** name of, or reference to a namespace
- **directory** name of a file system directory (without trailing slash or backslash — the plan is to let these indicate that the directory name is to be inferred from the namespace name)

#### Result

- If linking was successful, a matrix of messages, else a vector containing an error message.

#### Common Options

- **flatten** (default off) Do not create sub-namespaces
  > **flatten** will load all items into the root of the linked namespace, without creating any sub-namespaces,
  > even if the source code is arranged into sub-directories. This is typically used for old applications
  > which have been divided into source modules, but still need
  > all code to be loaded into a single namespace.
  >
  > Note that if **flatten** is set, new items need special treatment:
  > - If a function or operator is renamed in the editor, the new item will be placed in the
  > same folder as the original item.
  > - If a new item is created, it will be placed in the root of the linked directory.
  > - It is also possible to use the **beforeWrite** setting to add application-specific logic to determine the file name to be used.

- **caseCode** (default off) Adds a suffix to file names on write
  > If your application contains items with names that differ only in case
  > (for example `Debug` and `DEBUG`), and your file system is case-insensitive
  > (for example, under Microsoft Windows), then enabling **caseCode** will
  > cause a suffix to be added to file names, containing
  > an octal encoding of the location of uppercase letters in the name.
  >
  > For example, with caseCode on, two functions named `Debug` and `DEBUG` will be written to files named
  > `Debug-1.aplf` and `DEBUG-37.aplf`.
  >
  > Note: you will probably want to enable **forceFilenames** if you enable **caseCode**.

- **forceExtensions** (default off) force correct extensions
  > If enabled, file extensions will be renamed when an item is defined in the workspace from an external file,
  > so that the file extension accurately reflects the type of the item according to **typeExtensions**.

- **forceFilenames** (default off) force correct filenames
  > If enabled, file names will be adjusted so that they match the item name, when an item is defined 
  > in the workspace from an external file, so that the file extension accurately reflects the name of the item.
  >
  > Note that by default, although Link will always create files with the same name as items added to the
  > active workspace, it will not insist that file names match item names when importing items from a directory.
  > Unless **forceFilenames** is set, Link will write updates to the same file that an item was loaded from,
  > even though the file name does not match the item name.

- **source**	{ns|**dir**|both}  
  > Whether to consider the ns or dir as the authoritative source when [creating](Link.Create) or [refreshing](Link.Refresh) the link.
  > - `dir` means that items in the namespace will be overwritten by items in files.
  > - `ns` means that items in files will be overwritten by items in the namespace.
  > - `both` will first copy from ns to dir, and then the other way.
  >
  > \
  > Defaults to `dir`.

 - **watch**	{none|ns|dir|**both**} 
   > Specifies which sides of the link to watch for changes (and synchronise).
   > - `ns` will mirror namespace changes (done with the editor) to files. Note that it will **not** reflect changes using assignment, ⎕FX, ⎕FIX, ⎕CY, ⎕NS, etc. If you want to programmatically change an item so that the change is reflected to files, you need to use [Fix](Link.Fix)
   > - `dir` will mirror file changes (done with any software) into the namespace. Note that massive file changes (e.g. git checkout or git pull) may fail and leave the link in an unsynchronised state, in which case you will get a warning message. Therefore it is desirable to [break](Link.Break) the link before doing massive changes to files, then re-[create](Link.Create) the link.
   > - `both` will do both.
   >
   > \
   > Watching a `dir` (or `both`) is currently only supported under Microsoft Windows, but cross-platform support is planned.
   > Defaults to `both` where supported, else `ns`.  

#### "Advanced" Options

- **beforeWrite** `ns.hookname` name of function to call before writing to file

  > You can override default Link behaviour by nominating a function to be called before Link writes to an external source file.
  > This allows you to support custom data formats used by your application. 
  >
  > Your function will be called with a nested right argument containing the following elements:
  >
  > [1] Filename that Link intends to use\
  > [2] The source code that Link intends to write to file\
  > [3] The item name\
  > [4] The old name, if this write is due to a rename\
  > [5] Reference to the namespace containing the item\
  > [6] Name class of the item (with decimal fraction)\
  > [7] Reference to a namespace containing link options for the active link.\
  > [8] Boolean: Is this call a file name request?\
  > Note: Do not assume a specific length, more elements may be added in the future.\
  > \
  > Your callback function must return one of the following results:
  >
  >  - `0` The **beforeWrite** function has completed all necessary actions. Link should not update any files.
  >  - `1` The **beforeWrite** function wishes to "pass" on this write: Link should proceed as planned.
  >
  > \
  > _**However**_, if `args[8]=1` then the call was a file name request and the callback function must return a suggested file name to use.

- **beforeRead** `ns.hookname` name of function to call before before reading a file

  > If you specify a **beforeRead** function, it will be called before Link processes a change to an extenal source file.
  > Your function will be called with the following arguments:
  >
  >  [1] Name of the file that was changed\
  >  [2] Name of the directory containing the file that was changed\
  >  [3] The namespace that Link has identified as the target, based on the directory name\
  >  [4] Reference to a namespace containing link options for the active link.\
  >  [5] Currently Unused.\
  > Note: Do not assume a specific length, more elements may be added in the future.\
  > \
  >Your callback function must return one of the following:
  >
  >  - `0` The **beforeRead** function has completed all necessary actions. Link should not update the workspace.
  >  - `1` The **beforeRead** function wishes to "pass" on this write: Link should proceed as planned.

- **codeExtensions** File extensions that are expected to contain source code
  > When reacting to changes in a watched directory, Link will only process files
  > if the changed file has one of the listed extensions.
  > 
  > The default is `'aplf' 'aplo' 'apln' 'aplc' 'apli' 'dyalog' 'apl' 'mipage'`
  >
  > See **customExtensions** and **typeExtensions** for more information.

- **customExtensions** Specifies additional file extensions handled by **beforeRead** functions
  > If you have specified a **beforeRead** handler function, and your code
  > supports the use of custom file extensions to store source data in application-specific
  > formats, you need to set **customExtensions** so that Link does not ignore changes
  > to these file types.
  >
  > default is `''` - no custom extensions

- **typeExtensions** Specify the file extensions to use for each name class
  > The **typeExtensions** table specifies the default extension
  > that should be used when creating a new file to contain the
  > source for an item of a given type. 
  >
  > **typeExtensions** is a two-column matrix with numeric name class numbers in the first column
  > and corresponding file extensions in the second column.
  >
  > Note that the **forceExtensions**
  > switch can be used to correct all extensions on pre-existing files when a link is created.
  >
  > The default is:
  >
  > | Type | extension |
  > | ---- | --------- |
  > | 2    | apla      |
  > | 3    | aplf      |
  > | 4    | aplo      |
  > | 9.1  | apln      |
  > | 9.4  | aplc      |
  > | 9.5  | apli      |

