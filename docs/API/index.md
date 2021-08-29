# API Overview

## API function syntax
The Link API functions all reside in `⎕SE.Link`.

The general syntax for Link API functions is as follows:
```APL
      message ← options ⎕SE.Link.FnName args
```
where:

- `message` is a simple character vector or nested array containing messages related to the effects of the function call.
- `options` is a namespace containing [optional parameters](#option-namespaces). Only certain functions accept an options namespace.
- `FnName` is the name of the API function
- `args` is either a character vector or a nested vector as described in the help section for that API function.

## Option Namespaces
Some API functions accept an option namespace as the left argument. For example, to create a link with non-default `source` and `flatten` options,
you would write:

```apl
      options←⎕NS ⍬                                     ⍝ create empty namespace
      options.(source flatten)←'dir' 1                  ⍝ set two named options
      options ⎕SE.Link.Create 'myapp' '/sources/myapp'  ⍝ namespace and director name on the right, options on left
```

Creating option namespaces will become more elegant once Dyalog APL is enhanced with a notation for namespaces. Until that time (no definite schedule has yet been set), you can take advantage of the new JSON5 dialect support in the `⎕JSON` system function to use JSON as a notation for options without requiring quotes around option names:

```
        opt←⎕JSON⍠'Dialect' 'JSON5'
        (opt '{source:"dir", flatten:1}') ⎕SE.Link.Create 'myapp' '/sources/myapp' 
```

## User commands
Some API functions have a corresponding user command, to make them a little easier to use interactively. The API functions with user command covers are indicated with <sup>`]`</sup> in the function reference tables. These user commands all take exactly the same arguments and options as the API functions, specified using user command syntax. The Link.Create call above would thus be written:
```apl
      ]LINK.Create myapp /sources/myapp -source=dir -flatten
```
***Specifying extensions:*** Two options require arrays identifying file extensions: `codeExtensions`, `customExtensions` and `typeExtensions`. For convenience, the `]LINK.Create` user command accepts the *name* of a variable containing the array, rather than the array values. 

## Basic API Function reference
Function | User Command | Right Argument(s) | Left Argument(s) | Result
--------|-------------|-----------------|----------------|------
[Add](Link.Add.md) | `]Add` | items | *<none>* | message                                                                                      
[Break](Link.Break.md) | `]Break` | namespaces | options: `all` `exact` | message                                                               
[Create](Link.Create.md) | `]Create` | namespace directory | options: `source` `watch` (and [many more](Link.Create.md#common-options)) | message
[Export](Link.Export.md) | `]Export` | namespace directory | options: `overwrite` `caseCode` `arrays` `sysVars` | message             
[Expunge](Link.Expunge.md) | `]Expunge` | items | *<none>* | boolean array                                                             
[Import](Link.Import.md) | `]Import` | namespace directory | options: `overwrite` `flatten` `fastLoad` | message                      
[LaunchDir](Link.LaunchDir.md) | | none | none | directory name                                                                           
[Pause](Link.Pause.md) | `]Pause` | *<none>* | *<none>* | message                                                                    
[Refresh](Link.Refresh.md) | `]Refresh` | namespace | options: `source` | message                                                      
[Resync](Link.Resync.md) | `]Resync` | *<none>* | options: `confirm` `pause` | message                                                
[Status](Link.Status.md) | `]Status` | namespace | options: `extended` | message                                                      
[Version](Link.Version.md) | | *<none>* | *<none>* | version number as string 

!!!Note
	The currently active version of Link can be found as part of `]TOOLS.Version`

## Advanced API Function reference 
Function | User Command | Right Argument(s) | Left Argument(s) | Result
--------|-------------|-----------------|----------------|-------
[CaseCode](Link.CaseCode.md) | | filename | *&lt;none&gt;* | case-coded filename
[Fix](Link.Fix.md) | | source | array: namespace name oldname | boolean                                                                                
[GetFileName](Link.GetFileName.md) | `]GetFileName` | items | *&lt;none&gt;* | filenames                                                                
[GetItemName](Link.GetItemName.md) | `]GetItemName` | filenames | *&lt;none&gt;* | items                                                                
[Notify](Link.Notify.md) | | event filename oldfilename | *&lt;none&gt;* | *&lt;none&gt;*                                                              
[StripCaseCode](Link.StripCaseCode.md) | | filename | *&lt;none&gt;* | filename without case code                                                      
[TypeExtension](Link.TypeExtension.md) | | name class | option namespace used for [Create](Link.Create.md) | file extension (without leading `'.'`) | |
