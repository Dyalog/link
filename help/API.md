The Link API functions are normally found in ```⎕SE.Link```. All API functions take a character
vector or a nested vector as a right argument. The left argument may either be a namespace containing option values, or an array of character vectors. Namespaces may be specified by reference. For more details on setting options, look below the following table:

### Basic API Function reference

Function                                              | Right Argument(s)          | Left Argument(s)                               | Result 
------------------------------------------------------|----------------------------|------------------------------------------------|-------
 [Add](Link.Add.md)<sup>`]`</sup>                     | items                      | *&lt;none&gt;*                                 | 
 [Break](Link.Break.md)<sup>`]`</sup>                 | namespaces                 | options: `all` `exact`                         | 
 [Create](Link.Create.md)<sup>`]`</sup>               | namespace directory        | options: `source` `watch` [and [many more](Link.Create.md#common-options)]      | 
 [Export](Link.Export.md)<sup>`]`</sup>               | namespace directory        | options: same as [Create](Link.Create.md)      | 
 [Expunge](Link.Expunge.md)<sup>`]`</sup>             | items                      | *&lt;none&gt;*                                 | boolean array
 [Import](Link.Import.md)<sup>`]`</sup>               | namespace directory        | options: same as [Create](Link.Create.md)      | 
 [Refresh](Link.Refresh.md)<sup>`]`</sup>             | namespace                  | options: `source`                              | 
 [Status](Link.Status.md)<sup>`]`</sup>               | namespace                  | options: `extended`                            | 
 [Version](Link.Version.md)             | *&lt;none&gt;*             | *&lt;none&gt;*                                 | version number as string

 <sup>`]`</sup> These functions have [user command covers](#user-commands).

### Advanced API Function reference 

Function                                              | Right Argument(s)          | Left Argument(s)                               | Result 
------------------------------------------------------|----------------------------|------------------------------------------------|-------
 [CaseCode](Link.CaseCode.md)                         | filename                   | *&lt;none&gt;*                                 | case-coded filename 
 [Fix](Link.Fix.md)                                   | source                     | array: namespace name oldname                  | 
 [GetFileName](Link.GetFileName.md)<sup>`]`</sup>     | items                      | *&lt;none&gt;*                                 | filenames
 [GetItemName](Link.GetItemName.md)<sup>`]`</sup>     | filenames                  | *&lt;none&gt;*                                 | items
 [Notify](Link.Notify.md)                             | event filename oldfilename | *&lt;none&gt;*                
 [StripCaseCode](Link.StripCaseCode.md)               | filename                   | *&lt;none&gt;*                                 | filename without case code
 [TypeExtension](Link.TypeExtension.md)               | name class                 | option namespace used for [Create](Link.Create.md) | file extension (without leading `'.'`)                         |                                                |

 <sup>`]`</sup> These functions have [user command covers](#user-commands).

### Option Namespaces

API functions take a primary argument on the right which is a simple
character vector or a nested vector as documented above. With the exception of [Fix](Link.Fix.md),
which takes a 3-element left argument, API functions typically accept an option namespace as
the left argument. For example, to create a link with non-default `source` and `flatten` options,
you would write:

```apl
      options←⎕NS ''                                    ⍝ create empty namespace
      options.(source flatten)←'dir' 1                  ⍝ set two named options
      options ⎕SE.Link.Create 'myapp' '/sources/myapp'  ⍝ namespace and director name on the right, options on left
```

### User commands

Most, but not all, API functions have a corresponding user command, to make them a little easier to use interactively. The API functions with user command covers are indicated with <sup>`]`</sup> in the above tables. These user commands all take exactly the same arguments and options as the API functions, specified using user command syntax. The Link.Create call above would thus be written:
```apl
      ]LINK.Create myapp /sources/myapp -source=dir -flatten
```
***Specifying extensions:*** Two options require arrays identifying file extensions: `codeExtensions`, `customExtensions` and `typeExtensions`. For convenience, the `]Link.Create` user command accepts the *name* of a variable containing the array, rather than the array values. 