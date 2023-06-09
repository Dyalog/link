# Link.Create

## Syntax
    ]LINK.Create <ns> <dir> [-source={ns|dir|auto}] [-watch={none|ns|dir|both}] [-casecode] [-forceextensions] [-forcefilenames] [-arrays] [-sysvars] [-flatten] [-beforeread=<fn>] [-beforewrite=<fn>] [-getfilename=<fn>] [-codeextensions=<var>] [-typeextensions=<var>] [-fastload] 
    
    message ← {options} ⎕SE.Link.Create (namespace directory)

!!! ucmdhelp "Show User Command information in the session with `]LINK.Create -?`"

## Arguments

- `namespace` is either a reference to, or a simple character vector containing the name of a namespace.  
	In the user command `<ns>` is simply the name of the namespace. If a reference is used, it must refer to a namespace which has a display form which has name class 9 and can be used to locate the namespace (as opposed to an "anonymous" space with a name containing `[namespace]` or similar segments).
- `directory` is a simple character vector containing the path to a file system directory without any trailing slash or backslash.  
	In the user command, `<dir>` is the path to the file system directory.

## Result

- `message` is a simple character vector describing the established link, along with possible failures

- If `namespace` is `#` and the current workspace is isn't associated with a file (`⎕WSID≡'CLEAR WS'`) then `⎕WSID` will be set to `directory`. The value will be *with* a trailing slash or backslash to prevent being mistaken for a file name. The default titlebar caption of RIDE and the Windows IDE can then be used to keep track of which session is linked to which directory and a custom titlebar captions can use the `{WSID}` tag to include the value.
## Common options

### **source**
Default: **auto**

The **source** option specifies whether to consider the namespace in the active workspace (ns) or directory on the file system (dir) as the source (also used by a subsequent [Refresh](Link.Refresh.md)).

`source` is a simple character vector, one of `'ns'`, `'dir'` or `'auto'`.

- **dir** means that the namespace must be non-existent or empty and will be populated from source files.
- **ns** means that the directory must be non-existent or empty and will be populated by source files for the items in the namespace.
- **auto** will use whichever of ns or dir that is not empty. If both are empty, it will use **dir** on a subsequent [Refresh](Link.Refresh.md).

### **watch**
Default: **both** if a file system watcher can be created, else **ns**

The **watch** option specifies which sides of the link to watch for changes (and synchronise). Watching a **dir** (or **both**) is currently only supported using the .NET Framework or .NET Core.

`watch` is a simple character vector, one of `'none'`, `'ns'`, `'dir'` or `'both'`.

- **none:** changes are not automatically propagated across the link in either direction.
- **ns:** changes made in a linked namespace changes (made with the editor) will be copied to files. Note that it will **not** reflect changes made using other mechanisms, such as assignment, `⎕FX`, `⎕FIX`, `⎕CY`,  or `⎕NS`. If you want to programmatically change an item so that the change is reflected to files, you should use [⎕SE.Link.Fix](Link.Fix.md).
- **dir** will mirror changes made to files (using any mechanism) into the linked namespace. Note that there is a chance that updating a large number of files (e.g. git checkout, git pull or an unzip) may cause the file system watcher to miss changes and not report them to Link. If the source files are on a network drive, the file system watcher may be even more unreliable. Use [⎕SE.Link.Resync](Link.Resync.md) if you suspect something is wrong.
- **both** will synchronise changes in both directions. This is the default, and is recommended except in very special circumstances.

!!! Note
	[Link.Refresh](Link.Refresh.md) can be used to force a wholesale update of everything based on the setting of the `-source`option, and [Link.Resync](Link.Resync.md) can always be used to generate a list of differences between the workspace and linked directories if you are in doubt about the current state.

### **arrays**

Default: **off**

The **arrays** flag will export arrays on link creation.

- if simply set (`options.arrays←1` for the function or `-arrays` for the user command), then all arrays are exported.
- if set to a comma-separated list of names (`options.arrays←'name1,name2,...'` for the function or `-arrays=name1,name2,...` for the user command) then arrays with specified names are exported.

This option takes effect only when **source** is **ns**, and only when the link is initially created.

### **sysVars**

Default: **off**

The **sysVars** flag will export namespace-scoped system variables to file.

The exhaustive list of exported variables is: `⎕AVU  ⎕CT  ⎕DCT  ⎕DIV  ⎕FR  ⎕IO  ⎕ML  ⎕PP  ⎕RL  ⎕RTL  ⎕USING  ⎕WX`. They will be exported for all unscripted namespaces.

This option takes effect only when **source** is **ns**.

### **forceExtensions**
Default: **off**

The **forceExtensions** flag forces correct file extensions.

If enabled, file extensions will be adjusted (if necessary), when an item is defined in the workspace from an external file, so that the file extension accurately reflects the type of the item according to **typeExtensions**.

### **forceFilenames**
Default: **off**

The **forceFilenames** flag will force correct file names.

If enabled, file names will be adjusted so that they match the item name, when an item is defined in the workspace from an external file, so that the file name matches the name of the item.

By default, Link will always create new files with the same name as items created in the active workspace. However, it will not insist that file names match item names when importing items from a directory.

If **forceFilenames** is not set.  Link will update to the same file that an item was loaded from, even though the file name does not match the item name.

## Advanced Options

### **flatten**
Default: **off**

The **flatten** flag prevents the creation of sub-namespaces in the active workspace.

The **flatten** option will load all items into the root of the linked namespace, even if the source code is arranged into sub-directories. This is typically used for applications that have source which is divided into modules, but still expects to run in a "flat" workspace.

Note that if **flatten** is set, newly created items need special treatment:

- If a function or operator is renamed in the editor, the new item will be placed in the
same folder as the original item.
- If a new item is created, it will be placed in the root of the linked directory.
- It is also possible to use the **getFilename** setting to add application-specific logic to determine the file name to be used (or prompt the user for a decision).

A suggested workflow is to always create a stub source file in the correct directory and edit the function that appears in the workspace, rather than creating new functions in the workspace.

This option takes effect only when **source** is **dir**.

### **caseCode**

Default: **off**

The **caseCode** flag adds a suffix to file names on write.

If your application contains items with names that differ only in case (for example `Debug` and `DEBUG`), and your file system is case-insensitive (for example, under Microsoft Windows), then enabling **caseCode** will cause a suffix to be added to file names, containing an octal encoding of the location of uppercase letters in the name.

For example, with caseCode on, two functions named `Debug` and `DEBUG` will be written to files named
`Debug-1.aplf` and `DEBUG-37.aplf`.

!!! Note
	Dyalog recommends that you avoid creating systems with names that differ only in case. This feature primarily exists to support the import of applications which already use such names. You will probably also want to enable **forceFilenames** if you enable **caseCode**.

### **beforeWrite**

If you specify a **beforeWrite** function, it will be called before Link updates a file or directory, allowing support of custom code or data formats. 

`beforeWrite` is a simple character vector containing the name of a function relative to the linked namespace.

In the user command, simply give the name. For example:  
`]LINK.Create -beforeWrite=Foo ns /tmp/folder`

Your function will be called with a nested right argument containing the following elements:

|Index|Description|
| ---- | ---- |
|[1]|Event name ('beforeWrite')|
|[2]|Reference to a namespace containing link options for the active link.|
|[3]|Fully qualified filename that Link intends to write to (directories end with a slash)|
|[4]|Fully qualified APL name of the item that Link intends to write|
|[5]|Name class of the APL item to write|
|[6]|Old APL name (different from APL name if the write is due to a rename)|
|[7]|Source code that Link intends to write to file|

!!! Note
	Do not assume a specific length, more elements may be added in the future.

Your callback function must return one of the following results:

 - `0`: The **beforeWrite** function has completed all necessary actions. Link should not update any files.
 - `1`: The **beforeWrite** function wishes to "pass" on this write: Link should proceed as planned.

### **beforeRead**
If you specify a **beforeRead** function, it will be called before Link reads source from a file or directory, allowing support of custom code or data formats.

`beforeRead` is a simple character vector containing the name of a function relative to the linked namespace.

In the user command, simply give the name. For example:  
`]LINK.Create -beforeRead=Foo ns /tmp/folder`

Your function will be called with a nested right argument containing the following elements:

|Index|Description|
| ---- | ---- |
|[1]|Event name (`'beforeRead'`)|
|[2]|Reference to a namespace containing link options for the active link.|
|[3]|Fully qualified filename that Link intends to read from (directories end with a slash)|
|[4]|Fully qualified APL name of the item that Link intends to update|
|[5]|Name class of the APL item to be read|

!!! Note
	Do not assume a specific length, more elements may be added in the future.

Your callback function must return one of the following results:
  - `0`: The **beforeRead** function has completed all necessary actions. Link should not update the workspace.
  - `1`: The **beforeRead** function wishes to "pass" on this read: Link should proceed as planned.

### **getFilename**
If you specify a **getFilename** function, it will be called before Link updates a file or directory, allowing you to modify the name (or more likely the extension) of the file used to store the source for an APL item. Changing the file name this way allows you to override the **caseCode**, **forceFilenames** and **forceExtensions** options.

`getFilename` is a simple character vector containing the name of a function relative to the linked namespace.

In the user command, simply give the name. For example:  
`]LINK.Create -getFilename=Foo ns /tmp/folder`

Your function will be called with a nested right argument containing the following elements:

|Index|Description|
| ---- | ---- |
|[1]|Event name (`'getFilename'`)|
|[2]|Reference to a namespace containing link options for the active link.|
|[3]|Fully qualified filename that Link intends to use (directories end with a slash)|
|[4]|Fully qualified APL name of the item|
|[5]|Name class of the APL item|
|[6]|Old APL name (different from APL name if the write is due to a rename)|

!!! Note
	Do not assume a specific length, more elements may be added in the future.

Your callback function must return a simple character vector which must be one of:

- empty: to signify that Link should proceed with the suggested file name.
- non-empty: to specify the name to be used.

### **codeExtensions**
Default: `'aplf' 'aplo' 'apln' 'aplc' 'apli' 'dyalog' 'apl' 'mipage'`

Specify file extensions that are expected to contain source code. Link will only process changes to files with the specified extensions.

`var` is a nested vector of character vectors.

From a user command, the syntax is `-codeExtensions=var` where `var` holds the expected vector of extensions.

### **customExtensions**
Default: `''   ⍝ an empty character vector meaning no custom extensions`

Specifies additional file extensions handled by **beforeRead** functions. 

`customExtensions` is a nested vector of character vectors.

From a user command, the syntax is `-customExtensions=var` where `var` holds the expected vector.

If you have specified a **beforeRead** handler function, and your code supports the use of custom file extensions to store source data in application-specific formats, you need to set **customExtensions** so that Link does not ignore changes to these file types.

The reason for splitting the list of extensions into two parts ([**codeExtensions**](#code-extensions) and **customExtensions**) is to avoid your code having to repeat the list of standard extensions, or update this list if it should be extended in the future.

### **typeExtensions**
Default: `6 2⍴2 'apla' 3 'aplf' 4 'aplo' 9.1 'apln' 9.4 'aplc' 9.5 'apli'`

The **typeExtensions** table specifies the default extension that should be used when creating a new file to contain the source for an item of a given type. 

**typeExtensions** is a two-column matrix with numeric name class numbers in the first column
nd character vectors of corresponding file extensions in the second column.

From a user command, the syntax is `-typeExtensions=var` where `var` holds the expected array.

Note that the **forceExtensions** switch can be used to correct all extensions on pre-existing files when a link is created.

The default corresponds to:

| Type | extension |
| ---- | -------- |
| 2    | apla      |
| 3    | aplf      |
| 4    | aplo      |
| 9.1  | apln      |
| 9.4  | aplc      |
| 9.5  | apli      |

### **fastLoad**
Default: **off**

The **fastload** flag will reduce the load time by not inspecting the source to detect name clashes.

This affects only initial directory loading, but not subsequent editor or file system watcher events. It is worth setting **fastLoad** for very large projects that don't produce name clashes (that is, two files defining the same APL name). 

Side effects are (again, only at initial load time, not at subsequent events):

- good: load will be significantly faster because files won't be inspected to determine their true APL name.
- bad: clashing names won't be detected: files may silently overwrite each other's APL definition if they define the same APL name.
- bad: [**forceFileNames**](#forcefilenames)/[**forceExtensions**](#forcefileextensions) won't be observed
- bad: [**beforeRead**](#beforeread) may report incorrect name class

This option takes effect only when **source** is **dir**.
