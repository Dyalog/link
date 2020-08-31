# Link.Refresh 

If synchronisation is not enabled, or you have made changes to
linked folders or namespaces which are not tracked (such as
using `⎕FIX`, `⎕FX`, `⎕NS`, `⎕CY` or assignment), you can use this function to re-synchronise the namespace and the directory.\
In the latter case, it is preferable to modify workspace items with [Fix](Link.Fix), so that the Refresh is not necessary.

#### Arguments

- namespace(s)

#### Options

- **source**	{ns|dir|**auto**}  
  > Whether to consider the ns or dir as the authoritative source for the link.
  > - `dir` means that items in the namespace will be overwritten by items in files.
  > - `ns` means that items in files will be overwritten by items in the namespace.
  > - `auto` re-uses the same source that was determined at [Create](Link.Create.md) time (that is, the non-empty side of the link at create time)
  >
  > Defaults to `auto`.

#### Result

