# Linking Namespaces to Directories
Linking one or more namespaces in an active Dyalog workspace to corresponding directories in the file system makes it straightforward for users of Dyalog APL to store source code in Unicode text files while continuing to use an active APL session to interactively experiment with expressions and data, write and maintain code.

Using textual source rather than binary saved workspaces allows the use of source code management and other tools manage software projects using APL.

# The `]link` user command
Version 17.0 of Dyalog APL installs the files found in the Github repository https://github.com/dyalog/link in a folder called "Link" below the main Dyalog folder. A user command named `]link` provides a simple user interface which allows the creation, listing and removal of links.

The `]link` user command takes two arguments; the names of a namespace and of a directory in the file system. For example, the entire workspace can be linked to a single directory using:

```
      ]link # /User/mkrom/MyApp
```

Following the above, the source for any new functions created using the Dyalog function editor will immediately be stored in a file with the same name as the function, with the extension .dyalog. For example, if a function `foo` is created, then on exit from the editor, the file `/User/mkrom/MyApp/foo.dyalog` will contain the source of the function

If a function is created within a namespace, a sub-directory will be created to represent the namespace. The creation of a function `#.MyNs.goo` will lead to the creation of a file called `/User/mkrom/MyApp/MyNs/goo.dyalog`.

Under operating systems where Link is able to create a File System Watcher object (in v17.0, only Microsoft Windows), changes made to source files, including the addition of new files to linked directories, will immediately be reflected within the linked namespace. For example, the creation of a file named `/User/mkrom/MyApp/OtherNS/hoo.dyalog`, containing the definition of a function named `hoo`, would create a namespace `#.OtherNS` and within it define the function `hoo`.

## Modifiers

To get accurate information about the version of `]link` that you have installed, type:

```
      ]link -?
```

|Modifier|Values|Default|Description|
|--------|------|---|-----------|
|source|ns dir both|both|Indentifies initial source. Note that "both" will first copy from ns to dir, and then the other way.|
|watch|none ns dir both|both|Where to watch for changes. Watching the dir is currently only supported under Microsoft Windows|
|extn||.dyalog|File extension considered to be APL source code|
|flatten|on off|off|Loads everything into ns without creating sub-namespaces|
|prompt|on off|off|Prompts user to verify all synchronisation (not recommended)|
|reset|||Removes an existing link (dir argument not required)|        
|make|none ns dir both|both|create any necessary namespaces or folders during initialisation|

## Un-handled Events

Link detects changes in the workspace by attaching to the "EditorFix" callback from the editor - and uses a Microsoft.Net FileSystemWatcher object to monitor the directory (under Microsoft Windows only).

If functions or operators are created using `⎕FX`, `⎕FIX` or in the case of dfns or dops assignment, no callback is triggered. You can inform the link mechanism of such a change by calling  
```
      ns [name [oldname]] ⎕SE.Link.Fix source
```
Where `ns` is the namespace the fn or op has been defined in, optional arguments `name` and `oldname` are the new and (if it was renamed) old name. The right argument can be empty, in which case the definition will be picked up from the active workspace, or it can be the new source, in which case the fn or op will be redefined.

If an external change has been made to a file, and you want to make the link mechanism aware of this fact, for example if you are on a platform where FileSystemWatcher is unavailable, you can use:
```
      ⎕SE.Link.Notify type path [oldpath]
```
In the right argument, `type` must be one of *created*, *changed*, *renamed* or *deleted*. `path` is the name of a new file and, in the case of a rename, `oldpath` should name the old file in order for everything to end up pointing to the right place.

## Files which do not contain code

Link handles functions, operators, namespaces and classes - all of which have a well defined textual representation. There is currently no defined representation for arrays. You can add you own handling for additional file formats using two modifiers to name functions that should be called to pre-process events. The function `⎕SE.Link.Test.Run` shows an example of adding support for a `.charvec` and `.charmat` file formats, to allow the definitions of character constants to be stored in source files.

Two modifiers allow the specification of a function to call when an external change is detected (-onRead=fnname), or when a change happens in the workspace (-onWrite=fnname). In each case, the function should return 1 if link should perform own processing, 0 to signal that it has performed all necessary actions.

|Callback|Arguments|
|----|-----|
|onRead|change-type file-name target-ns-name|
|onWrite|namespace object-name old-name name-class source-as-vtv linked-file-name|

## Using the GitHub Version

Dyalog version 17.0 is shipped with a version of Link installed. However, Link is an open source project store in a GitHub repository. If you want to use a more recent implementation of Link than the one shipped with Version 17.0, we recommend that you clone the GitHub repo, or download a ZIP from GitHub, and then set the DyalogLinkSource environment variable to point to the source code for Link. The first time you use ]link in an APL session, it loads the code dynamically.

## Limitations

Watching a directory is only possible under Microsoft Windows.