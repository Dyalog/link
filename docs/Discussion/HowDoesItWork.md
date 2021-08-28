# How does Link work?

Some people need to know what is happening under the covers before they can relax and move on. If you are not one of those people, do not waste any further time on this section. If you do read it, understand that things may change under the covers without notice, and we will not allow a requirement to keep this document up-to-date to delay work on the code. It is reasonably accurate as of April 2021.

**Terminology:** In the following, the term *object* is used very loosely to refer to functions, operators, namespaces, classes and arrays.

### What Exactly is a Link?

A link connects a namespace in the active workspace (which can be the root namespace `#`) to a directory in the file system. 

When a link is created:

An entry is created in the table which is stored in the workspace using an undocumented I-Beam, recording the endpoints and all options associated with the Link. The command `]Link.Status` can be used to report this information. Earlier versions used `⎕SE.Link.Links`, but version 3.0 only uses this for links with an endpoint in `⎕SE`.

Depending on which end of the link is specified as the source, APL Source files are created from workspace definitions, or objects are loaded into the workspace from such files. These processes are described in more detail in the following.

By default, if .NET is available, a .NET File System Watcher is created to watch the directory for changes so that those changes can immediately be replicated in the workspace.

#### Creating APL Source Files and Directories

Link writes textual representations of APL objects to UTF-8 text files. Most of the time, it uses the system function `⎕SRC` to extract the source form writing it to file using `⎕NPUT`. There are two exceptions to this:

* So-called "unscripted" namespaces which contain other objects but do not themselves have a textual source, are represented as sub-directories in the file system (which may contain source files for the objects within the namespace).
* Arrays are converted to source form using the function ` ⎕SE.Dyalog.Array.Serialise`. It is expected that the APL language engine will support the "literal array notation", and that `⎕SRC`will one day be extended to perform this function, but there is as yet no schedule for this.

#### Loading APL Objects from Source

As a general rule, Link loads code into the workspace using `2 ⎕FIX 'file://...'`. 

When you are watching both sides of a link, Link delegates the work of tracking the links to the interpreter. In this case, editing objects will cause the editor itself (not Link) to update the source file. You can inspect the links which are maintained by the interpreter using a family of I-Beams numbered 517x. When a *new* function, operator, namespace or class is created, a hook in the editor calls Link code which generates a new file and sets up the link.

If .NET is available, Link uses a File System Watcher to monitor linked directories and immediately react to file creation, modification or deletion.

### The Source of Link

Link consists of a set of API functions which are loaded into the namespace `⎕SE.Link` when APL starts, from **$DYALOG/StartupSession/Link**. The user command file **$DYALOG/SALT/SPICE/Link.dyalog** provides access to the interactive user command covers that exist for most of the API functions. The code is included with installations of Dyalog version 18.1 or later. 

If you want to use Link with version 18.0 or download and install Link from GitHub, see the [installation instructions](/Usage/Installation.md).

### The Crawler

In a future version of Link, hopefully available during 2021, an optional and configurable [Crawler](/Crawler.md) will be able to run in the background and occasionally compare linked namespaces and directories using the same logic as [Link.Resync](/API/Link.Resync.md), and deal with anything that might have been missed by the automatic mechanisms. This will be especially useful if:

* The File System Watcher is not available on your platform
* You add functions or operators to the active workspace without using the editor, for example using ``)COPY`` or dfn assignment.

The document [Technical Details and Limitations](TechDetails.md) provides much more information about the type of APL objects that are supported by Link.

## Breaking Links

If [Link.Break](/API/Link.Break.md) is used to explicitly break an existing Link, the entry is removed from `⎕SE.Link.Links`, and the namespace reverts to being a completely "normal" namespace in the workspace. If file system watch was active, the watcher is disabled. Any information that the interpreter was keeping about connections to files is removed using `5178⌶`. None of the definitions in the namespace are modified by the process of breaking a link.

If you delete a linked namespace using `)ERASE` or `⎕EX`, Link may not immediately detect that this has happened. However, if you call `Link.Status`, or make a change to a watched file that causes the file system watcher to attempt to update the namespace, Link will discover that something is amiss, issue a warning, and delete the link.

If you completely destroy the active workspace using `)LOAD` or `)CLEAR`, all links will be deleted.
