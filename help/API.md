The Link API functions are normally found in ```⎕SE.Link```. All API functions take a character
vector or a nested vector as a right argument, and optionally a namespace containing option values on
the left. For more details on setting options, look below the following table:

### Link API Function reference

Function                        | Right Argument(s) | Options                  | Result 
--------------------------------|---------------------|--------------------------|-------
 [Add](Link.Add)<sup>`]`</sup>  | items               | filename all | 
 [Break](Link.Break)<sup>`]`</sup>| namespace           | | 
 [CaseCode](Link.CaseCode) | filename            |                                           | case-coded filename 
 [Create](Link.Create)<sup>`]`</sup>| namespace directory | source watch [[and many more]](Link.Create) | 
 [Export](Link.Export)<sup>`]`</sup>| namespace directory | | 
 [Expunge](Link.Expunge)<sup>`]`</sup>| items               | | 
 [Fix](Link.Fix)           | source              | namespace name oldname<sup>`⍺`</sup>                     | 
 [GetFileName](Link.GetFileName)<sup>`]`</sup>| item |        |                                           | filename 
 [GetItemName](Link.GetItemName)<sup>`]`</sup>| filename      |                                           | itemname 
 [Import](Link.Import)<sup>`]`</sup>| namespace directory | | 
 [List](Link.List)<sup>`]`</sup>|    [namespace]      | extended | 
 [Notify](Link.Notify)     | event filename oldfilename | | 
 [Refresh](Link.Refresh)<sup>`]`</sup>| namespace           | | 
 [StripCaseCode](Link.CaseCode) | filename            |                                           | filename without case code

 <sup>`]`</sup> These functions have [user command covers](#user-commands).

 <sup>`⍺`</sup> The left argument to [Fix](Link.Fix) is a 3-element vector, not an option namespace.


### Option Namespaces

API functions take a primary argument on the right which is a simple
character vector or a nested vector as documented above. With the exception of [Fix](Link.Fix),
which takes a 3-element left argument, API functions typically accept an option namespace as
the left argument. For example, to create a link with non-default `source` and `flatten` options,
you would write:

```apl
      options←⎕NS ''                                    ⍝ create empty namespace
      options.(source flatten)←'dir' 1                  ⍝ set two named options
      options ⎕SE.Link.Create 'myapp' '/sources/myapp'  ⍝ namespace and director name on the right, options on left
```

### User commands

Most, but not all, API functions have a corresponding user command, to make them a little easier to use
interactively. The API functions with user command covers are indicated with <sup>`]`</sup> in [the above table](#link-api-function-reference). These user commands all take exactly the same arguments and options as the API functions,
specified using user command syntax. The Link.Create call above would thus be written:
```apl
      ]LINK.Create myapp /sources/myapp -source=dir -flatten
```
***Specifying extensions:*** Two options require arrays identifying file extensions: `codeExtensions` and `typeExtensions`.
For convenience, the `]Link.Create` user command accepts the *name* of a variable containing the array, 
rather than the array values. However, in this case,
it is highly recommended to use the API function directly rather than the user command.
