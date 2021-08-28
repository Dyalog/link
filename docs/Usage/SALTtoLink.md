# Migrating from SALT to Link

If you have been using SALT ([Link's direct predecessor](/History.md)) to maintain the source of your application, the good news is that nearly all of your source files already have a format which can be used directly with Link (with the exception of source files containing arrays). 

There are a few issues that may require some work to sort out.

## No Version Control Features

SALT includes basic version control features, such as storing multiple versions of the source for a single function by creating file names containing sequence numbers, and providing tools to compare different versions. Link assumes that you will use an external SCM like Git or SVN, and contains no version control features of its own.

*[SCM]: Source Code Manager

## Different API

Obviously, you need to replace all calls to SALT functions like `⎕SE.SALT.Load` with calls to `⎕SE.Link.Create` or `⎕SE.Link.Import`.

## File Name Extensions

SALT uses the extension of `.dyalog` for all source files including arrays. Link will load `.dyalog` files and, if you edit existing objects the source file will be updated. However, if you create any new items, all new files will have extensions that vary by type, for example `.aplf` for functions, `.apln` for namespaces, or `.apla` for arrays.

You can rename all your source files to the Link defaults in one operation by creating a link using the [`-forcefilenames`](/API/Link.Create) switch. Remember to take a backup before you cause such a sweeping change to your source files!

## `.dyapp` Files

From Dyalog version 18.0, you can launch the APL interpreter using any APL source file, or a configuration file. As a result, `.dyapp` files are now deprecated. The section on [setting up your environment](Setup.md) contains examples of using the new mechanisms to launch your application.

## Arrays

SALT uses a couple of different formats to represent arrays, either XML or executable APL expressions. Link uses the future literal array notation. You will need to load your arrays into the workspace using SALT and then use [Link.Add](/API/Link.Add.md) to write them back out again.

## Loading Individual Files

The SALT `Load` function supports loading individual source files and maintaining a link to the source file, so that editing the function will cause the source file to be updated. While [Link.Import](/API/Link.Import.md) can load individual files, the files loaded in this way will not be synchronised. [Link.Create](/API/Link.Create.md) only supports linking an entire directory to a namespace.

This may well change in a future release. Until then, you can use `2 ⎕FIX 'file://filename'` to achieve more or less the same effect as SALT's Load.

## The `⍝∇:require` Comment

SALT was implemented before the interpreter added support for the `:Require` keyword, which can be used to manage the order in which dependencies are loaded. SALT used special comments to implement its own dependency management. Link does not support these comments; you must switch to using the keyword.

