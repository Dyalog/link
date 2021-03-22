# Link.Refresh 

    ]LINK.Refresh <ns> [-source={ns|dir|auto}]

    msg ← {opts} ⎕SE.Link.Refresh ns

Refresh is a one-way operation: it will read one side of the link and overwrite the other side of the link accordingly. 

It means that changes on the other side of the link may be lost: if there are un-synchronised changes on both sides of the link, then Refresh will destroy one set of changes (the non-source side will be overwritten by the source side).

It is useful when not watching the directory, to force updating the namespace from files by using `source=dir`.

It is also useful if you have made changes to linked namespaces which are not tracked (such as using `⎕FIX`, `⎕FX`, `⎕NS`, `⎕CY` or assignment), you can use this function with `source=ns` to re-synchronise the directory.\
In the latter case, it is preferable to modify workspace items with [Fix](Link.Fix), so that the Refresh is not necessary.




#### Arguments

- namespace(s)

#### Options

- **source**	{ns|dir|**auto**}  
  > Whether to consider the ns or dir as the authoritative source for the link.
  > - `dir` means that items in the namespace will be overwritten by items in files.
  > - `ns` means that items in files will be overwritten by items in the namespace.
  >    Note that arrays will *not* be refreshed from namespace, since arrays must always be explicitly written to file by calling [Link.Add](Link.Add.md) or [Link.Fix](Link.Fix.md)
  > - `auto` re-uses the same source that was determined at [Create](Link.Create.md) time.
  >
  > Defaults to `auto`.

#### Result

- String describing the established link, along with possible failures