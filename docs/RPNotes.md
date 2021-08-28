# Rich's Notes
Things which I haven't just directly changed since I'm not exactly sure how yet

- Sometimes components are referred to by UCMD syntax, sometimes by OOP syntax? Should get consistent...
	- Probably "API syntax" followed by "Also, here is UCMD version"...
	- the fact that help can be got with ]Link.FnName -? should probably be mentioned somewhere

## Technical APL jargon which needs clarifying in a separate document
- Active workspace
	The active workspace is the collection of names in an active Dyalog session. It consists of all of the names found using `#.⎕NL⍳9`, and possibly also `#.⎕SE`.

## Simplified
There are 3 ways to bring code in to or push code out from the active workspace.
1. Use `Link.Create` to create a bi-directional link. Changes made in the Dyalog editor are reflected in the text source on the file system, and changes made to the text source on the file system are reflected in the active workspace (viewable using the Dyalog editor).
1. Use `Link.Import` to import code from text source in a folder on the file system into a namespace in the active workspace.
1. Use `Link.Export` to export code from a namespace in the active workspace to a folder of text source files on the file system.

It seems obvious, but somewhere it might be worth noting that - until/unless this is added as a specific feature - individual items can be written to file ("exported") by copying them into a new namespace and using Link.Export on that namespace.

## SCM for APLers
This should be its own document, or possibliy repository

## Introduction
- Source code stored in external files is preserved exactly as typed, rather than being reconstructed from the tokenised form.
	This part is a little obtuse unless you already know about how Dyalog handles source code. It should probably be moved from this section and explained a little further, possibly in the History of Text Source section
- SCM for APLers should be its own document living somewhere in the Documentation/Learning materials/Information Ecosystem

- You can invoke ]LINK.Createseveral times to create multiple links, and you can also use ]LINK.Importor ]LINK.Export to import source code into the workspace or export code to external files without creating links that will respond to subsequent changes. 
	This part should be more prominent somehow
	How do I import code and my changes not be saved?
	How can I make changes to my code without them being saved?

## Tech details
- Scripted namespaces: It is likely that this restriction will be lifted in a future version of Link.
- Once again mentioning the loss of text source fidelity. Should be explained somewhere else or linked to a more comprehensive explanation and some examples
- Maybe remove - because the APL interpreter does not have a source form for such items.
- With the exception of the scenarios ← this paragraph needs small rework

## How does Link work?
This section is really part of Technical Details and Limitations, but might...
- version 3.0 only uses this for links with an endpoint in `⎕SE`. ← is this a change history issue?
- It is expected that the APL language engine will support ← Future stuff
- will be able to run in the background and ← what does "in the background" mean specifically?

- The fact that Link only acts automatically in response to changes made in editors should be made more prominent!
- family of I-Beams  ← is a list of these desired? I feel like someone who reads this would want to see what they are and what they do?
- file system watcher ← is this File System Watcher or file system watcher?

## Getting started
- First paragraph slightly confusing
- This chapter is actually on "usage", of which Getting Started is just one part...

## Set up
- We can now launch out development environment using ← a screenshot won't hurt
- The contents of this chapter are not obvious from its title...

## Converting an Existing Workspace to use Link
This section is a tad confused...
- Recreating the workspace might be relevant in some section about "distribution"

## SALT to Link
- what are "sequence numbers" ?
- .dyapp File: APL source file `.apl*` or `.dyalog` or configuration file `.dcfg`. Perhaps link to Configuration file docs as well?

## Installation
- Feels like it should be part of Getting Started, although it's really about installing Link if you need a version other than that which ships with the 'terp.

## Link 2.1
There is some mention about this as the beta name - however, who actually had access to that? I guess technically anyone...