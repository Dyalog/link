# Link.Resync 

    ]LINK.Resync <ns> 
    
    msg ← {opts} ⎕SE.Link.Resync ⍬

`Link.Resync` will re-synchronise the contents of linked namespaces and the corresponding source directories. It is useful when:

* You know that you have made changes of a type which will not trigger updates, such as function assignments or the `)COPY` system command
* You have reason to believe that the file system watcher might have missed some updates
* You have loaded a workspace that was saved with active links. In this case, all Link functionality will be disabled until you do a Resync to ensure that the workspace content matches the external source.

By default, Resync takes no action, but outputs a list of differences found, with a recommendation of whether the the difference should be resolved by updating a file should be created or updated (`→`), or that a file should be read and the workspace updated (`←` ). For example:

```
      ]link.resync
2 updates required: use -proceed option to synchronise
 Name          Direction  File             Comments
 #.badapp.Foo  →                           Item has no corresponding file
 #.badapp.Goo  ←          /myapp/Goo.aplf  File is dated 08:17 yesterday,
                                           WS copy is dated 03 Sep 2021 
```

If you accept the recommendations, you can add the `proceed` switch, after which the link will be up-to-date and work can proceed normally.

```apl
      ]link.resync -proceed
1 file read, 1 file updated 
```

If Link is not able to suggest an action, it will display `?` in the direction column, for example if the source file is now older than when it was loaded into the workspace, `-proceed` will be rejected, you will need to resolve the difference manually.

!!! Note
	**Beware: The recommendations are NOT necessarily the correct actions!** For example, if an item exists in the workspace but not on file, Resync will recommend creating the file (and vice versa if a file exists but the item is not found in the workspace). But if the file was intentionally removed or renamed in the source, the correct action is actually to delete or rename it in the workspace. Always review the recommendations carefully before `-proceed` ing. Of course, if you are using a source code management system like Git, you should easily be able to detect and recover from mistakes.

#### Arguments

- ns: namespace(s) to consider

#### Options

- **proceed**

  > Whether to execute the changes suggested by Resync without the `proceed` option.

- **arrays**, **sysvars**

  > Whether arrays and system variables should be included in the analysis. See [Link.Create](Link.Create.md) for details of these options.

#### Result

- String describing the changes made, if requested.