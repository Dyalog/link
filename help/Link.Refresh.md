# Link.Refresh 

If synchronisation is not enabled, or you have made changes to
linked folders or namespaces which are not tracked (such as
using `⎕FX`, `⎕NS`. `⎕CY` or assignment), you can use this function to re-synchronise the namespace and the directory.\
In the latter case, it is preferable to modify workspace items with [Fix](Link.Fix), so that the Refresh is not necessary.

#### Arguments

- namespace

#### Options

- **source**	{ns|**dir**|both}  
  > Whether to consider the ns or dir as the authoritative source for the link.
  > - `dir` means that items in the namespace will be overwritten by items in files.
  > - `ns` means that items in files will be overwritten by items in the namespace.
  > - `both` will first copy from ns to dir, and then the other way.
  >
  > \
  > Defaults to `dir`.

#### Result

On success an empty vector, else an error message.
