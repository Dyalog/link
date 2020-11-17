# Link.Pause 

Pause will temporarily disable watching on linked namespaces, so that changes are not synchronised between namespace and directory.

Paused links can later be resumed by calling [Link.Refresh](Link.Refresh.md).

Note that if the link was [created](Link.Create.md) with no `watch`, then Pause will have no effect. To change the `watch` setting, the link needs to be [broken](Link.Break.md) then [created](Link.Create.md) again.

Pause may be useful when doing batch code update (such as `svn update` or `git pull`), which may confuse the file watching if too many file change at once.

It may also be useful when running code, to ensure that the code may not change while running.



#### Arguments

- linked namespace(s)


#### Result

- one boolean per argument namespace:
  - `1` if namespace was linked (and watching is now paused)
  - `0` if namesapce was not linked (and Pause did nothing)