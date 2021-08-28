# Link.Resync 

    ]LINK.Resync 
    
    msg ← {opts} ⎕SE.Link.Resync ⍬

`Link.Resync` will re-synchronise your workspace and source directories. It is the best way to resume work if you have used [Link.Pause](Link.Pause.md) to temporarily stop watching the file system, or you have loaded a checkpoint workspace that might contain obsolete code, or you have any other reason to suspect that the contents of the active workspace no longer match the source directories.

If you had previously used [Link.Pause](Link.Pause.md), your links will no longer be in a paused state following a Resync - unless you explicitly set the `pause=yes` option.

**WARNING:** Resync is one of the most recent items of functionality added to Link, and should be considered somewhat experimental in Link 3.0. While this is the case, the default value for the `confirm`  option will be `list` ,  which means that Resync will display output documenting the updates that it intends to make. If there are any outstanding differences, you need to explicitly set `confirm=yes` to execute the synchronisation.

#### Arguments

- Currently unused, reserved for future enhancements

#### Options

- **confirm**
  
  > Whether to execute the synchronisation, list the changes required, or both.
  > - `list` means that a list of actions that would be performed will be displayed.
  > - `yes` means that the actions will be performed.
  > - `copy` means that the actions will be performed and the list of actions will also be returned.
  >
  > Defaults to `list` in 3.0, this is expected to change in Link 3.1.
  
- **pause**

  > Whether the link should be in a paused state following the resync.
  >
  > Defaults to `no`.

#### Result

- String describing the changes made, if requested.