# Link.Pause 

    ]LINK.Pause 
    
    msg ←  ⎕SE.Link.Pause ⍬

Pause will temporarily suspend all synchronisation activities performed by Link. The recommended way to resume after a pause is to use [Link.Resync](Link.Resync.md), unless you are sure that you want to resume by using one side of the link as the definitive source, ignoring all changes on the other side, in which case [Link.Refresh](Link.Refresh.md) is the right choice.

Obviously, for links [created](Link.Create.md) with no synchronisation, Pause will have no effect. To change the `watch` setting, the link needs to be [broken](Link.Break.md) then [created](Link.Create.md) again.

Pause may be useful when doing batch code updates (such as `svn update` or `git pull`), copying or unzipping large quantities of source files, or other operations which may overload the file system watcher or cause unnecessary "thrashing" to occur.

It may also be useful when running application code, to guarantee that the code will not change while running.

### Editing Code While Paused

While Link itself will not perform synchronisation while links are paused, the editor which is integrated with the Dyalog APL IDE will update source files in some situations.

In the default scenario, where Link is watching both sides of a link, the information which links each code object in the workspace to a source file is [maintained by the interpreter](../Discussion/HowDoesItWork.md#loading-apl-objects-from-source). If code is edited using the built-in editor, the editor *will* automatically also update the source file (prompting the user for confirmation, depending on how the APL system is configured). The only way to avoid this is to use [Link.Break](Link.Break.md). In the [longer term](../Discussion/HowDoesItWork.md#the-future) we hope to convince the editor to honour paused links.

#### Arguments

- None


#### Result

- String stating whether Pause was successful or not.