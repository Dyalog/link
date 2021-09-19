# Link.Notify

    {name} ←  ⎕SE.Link.Notify args  

When synchonisation is active, Link will call Notify each time it detects a change to a linked source file. 
If synchronisation is not enabled, you can use this function to bring an external change into the active workspace, to notify the link system that an external file has changed.

If the workspace and directories become un-synchronised, you are probably better off using [Link.Resync](Link.Resync.md) to get a list of differences, or [Link.Refresh](Link.Refresh.md) to completely re-load the external source.

#### Arguments

- **type** of event that happened
   > - `'created'`: new file
   > - `'changed'`: update to existing file
   > - `'renamed'`: a file or subdirectory got a new name
   > - `'deleted'`: a file or directory was erased

- **path** of affected file or directory

- **oldpath** is the previous path
   
   > can be omitted for all but a **rename** event

#### Result
- If link updated an APL item, its full name is returned as a string. Otherwise an empty string is returned.