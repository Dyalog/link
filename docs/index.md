!!! Note
     Link version 4.0 and associated documentation are under development!
     You can track our progress [on GitHub](https://github.com/Dyalog/link/milestone/2).

# Audience
It is assumed the reader is a user of Dyalog APL using Dyalog APL version 19.0 or later. If you are currently managing text source using SALT or Link versions 1 or 2 and considering moving to Link 4.0, you might want to review documentation which describes differences between early versions of SALT and Link - these can be found in the [Link 3.0 documentation](https://dyalog.github.io/link/3.0/).

If you are migrating from Link 3.0 to 4.0, you may want to begin with a review of the [new features of Link 4.0](ReleaseNotes40.md).

# Introduction

***Link*** allows you to use Unicode text files to store APL source code, rather than "traditional" binary workspaces. The benefits of using Link and text files include:

* It is easy to use source code management tools like Git or Subversion to manage your code.

!!! Note
	Although an SCM is not a requirement for Link, if you are not already using a source code management system, we ***highly*** recommend making the effort to learn about and install Git.
	
	If you choose not to use an SCM then you just need your own strategy for taking suitable copies of your source files, as you would with workspaces.

* Changes to your code are **immediately** written to file: there is no need to remember to save your work. The assumption is that you will make the record permanent with a *commit* to your source code management system, when the time is right.
  
* Unlike binary workspaces, text source can be shared between different versions of APL - or even with human readers or writers who don't have APL installed at all.

* Source code stored in external files is preserved exactly as typed, rather than being reconstructed from the tokenised form.

*[SCM]: Source Code Manager

## Link is NOT...

- **A source code management system**: Link has no source code management features. You will need to use a separate tool like Git to manage the text files that Link will maintain for you as you work with Dyalog APL.
- **A database management system:** although Link is able to store APL arrays using a pre-release of the *literal array notation*, this is only intended to be used for constants which you consider to be part of the source code of your applications. Although all functions and operators that you define using the editor will be written to source files by default, source files are only created for arrays by explicit calls to [Link.Add](API/Link.Add.md) or by specifying optional parameters to [Link.Export](API/Link.Export.md). Application data should be stored in a database management system or files managed by the application.

## Link fundamentals

Link establishes ***links*** between one or more **namespaces** in the active APL workspace and corresponding **directories** containing APL source code in Unicode test files. For example, the following user command invocation will link a namespace called `myapp` to the folder `/home/sally/myapp`:

```      apl
      ]LINK.Create myapp /home/sally/myapp
```

A set of API functions is available in the session namespace `⎕SE`, for performing Link operations under programme control. Using the API, the above would be written:

```apl
      ⎕SE.Link.Create 'myapp' '/home/sally/myapp'
```

If `myapp` contains sub-directories, a namespace hierarchy corresponding to the directory structure will be created within the `myapp` namespace. By default, the link is bi-directional, which means that Link will:

* **Keep source files up-to-date:** 
Any changes made to code in the active workspace using the tracer and editor are immediately replicated in the corresponding text files.
* **Keep the workspace up-to-date:**
If .NET Framework or .NET Core is available, then any changes made to the external files using a text editor, or resulting from an SCM action such as rolling back or switching to a different branch, will immediately be reflected in the active workspace.

!!!Note
	For Dyalog to automatically update workspace contents due to file changes requires Microsoft .NET.
	
	The .NET Framework is included with Microsoft windows. For other platforms, .NET can be downloaded from [dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).
	
	To find out which versions are supported, see [section 2.1 of the .NET Core Interface Guide](https://docs.dyalog.com/latest/dotNET%20Core%20Interface%20Guide.pdf) and under the heading "Prerequisites" in [chapter 1 of the Dyalog for Microsoft Windows .NET Framework Interface Guide](https://docs.dyalog.com/latest/Dyalog%20for%20Microsoft%20Windows%20.NET%20Framework%20Interface%20Guide.pdf).

You can invoke [Link.Create](API/Link.Create.md) several times to create multiple links, and you can also use [Link.Import](API/Link.Import.md) or [Link.Export](API/Link.Export.md) to import source code into the workspace or export code to external files *without* creating links that will respond to subsequent changes. 

## Functions vs. User Commands
With a few exceptions, each [Link API function](API/index.md) has a corresponding User Command, designed to make the functionality slightly easier to use interactively in the session.

### User commands
The user commands have the general syntax

```
     ]LINK.CmdName arg1 [arg2] [-name[=value] ...]
```

where `arg2`'s presence depends on the specific command, `-name` is a flag enabling the specific option and `-name=value` sets that option to a specific value. Some options (like `codeExtensions` and `typeExtensions`) require an array of values: in these cases the user commands typically take the *name* of a variable containing that array.

For a list of installed user commands, type:


```apl
     ]LINK -?
```

### API functions

The API is designed for use under program control, and options are provided in an optional namespace passed as the left argument. The general syntax of the utility functions is

```apl
     options FnName arguments
```

where `options` is a namespace with variables, named according to the option they set, containing their corresponding values. The `-name=value` option can be set by `options.name←value`, and switches with values (e.g. `-name`) can be set by `options.name←1`. Unset options will assume their default value.

Options can also be provided as a character vector with the literal array representation of the option workspace, for example:

```apl
     '(name: 1)' FnName arguments
```

The details of the arguments and options can be found in the [API Reference](API/index.md).

## Further reading

To get started using Link, please read:

* [Basic Usage](Usage/index.md) to see how to set up your first links, and learn about exporting existing application code to source files.
* [Setting Up Your Environment](Usage/Setup.md) for a discussion of how to set up Link-based development and runtime environments.
* [Technical Details and Limitations](Discussion/TechDetails.md) if you want to know about the full range of APL objects that are supported, and some of the edge cases that are not yet supported by Link.

If you have an existing APL application that you want to move to Link, you might want to read one of the following texts first:

* [Converting Your Workspace to Text Source:](Usage/WStoLink.md) if you already have an existing body of APL code in binary workspaces.
* [Migrating to Link 3.0 from SALT:](Usage/SALTtoLink.md) if you are already managing text source using Link's predecessor SALT.

## Frequently Asked Questions

* [What happens if I save a workspace after creating Links?](Discussion/Workspaces.md#saving-workspaces-containing-links)
* [Are workspaces dead now?](Discussion/Workspaces.md#are-workspaces-dead-now)
* [How is Link implemented?](Discussion/TechDetails.md#how-does-link-work)

