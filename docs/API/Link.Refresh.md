# Link.Refresh 

    ]LINK.Refresh <ns> [-source={ns|dir|auto}]
    
    msg ← {opts} ⎕SE.Link.Refresh ns

!!! ucmdhelp "Show User Command information in the session with `]LINK.Refresh -?`"

Refresh will break and re-create a link by using one one side of the link as source, and bringing the other side into line.

!!! Note
	**Refresh has the potential to lose changes:** Refresh will overwrite one end of the link without checking for changes. [Link.Resync](Link.Resync.md) provides better control, allowing you to review the differences before selecting how they should be resolved, and is now recommended in place of Refresh in most scenarios.

Refresh is useful when you have decided not to watch one side of a link, but now want to pick up any changes that have happened since the link was created or most recently refreshed.

* To bring the workspace into line with the source directories, use `source=dir`.
* If you have made changes to linked namespaces using other mechanisms than the editor (such as using `⎕FIX`, `⎕FX`, `⎕NS`, `⎕CY` or assignment), you can Refresh with `source=ns` to update the directory.


#### Arguments

- namespace(s)

#### Options

- **source**	{ns|dir|**auto**}  
  > Whether to consider the ns or dir as the source for the link.
  > - `dir` means that items in the namespace will be overwritten by items in files.
  > - `ns` means that items in files will be overwritten by items in the namespace.
  > - `auto` re-uses the same source that was determined at [Create](Link.Create.md) time.
  >
  > The default is to use the setting that was specified at creation (`auto`).

#### Result

- String describing the established link, along with possible failures