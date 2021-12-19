## Link versus Workspaces

As the *versus* in the heading is intended to imply, the main purpose of Link is to replace many uses of workspaces. Link is intended to make it possible for APL users to move away from the use of workspaces as a mechanism for storing APL source code.

### Are Workspaces Dead Now?

No: Workspaces still have many uses, even if they are falling out of favour as mechanism for source code management:

* **Distribution:** For large applications, it will be inconvenient or undesirable to ship large collections of source files that are loaded at startup. The use of workspaces as a mechanism for the distribution of packaged collections of code and data is expected to continue.
* **Crash Analysis:** When an application fails, it is often useful to save the workspace, complete with execution stack, code and data, for subsequent analysis and sometimes resumption of execution. Dyalog will continue to support this, although we may gradually impose some restrictions, for example requiring the same version and variant of the interpreter in order to resume execution of a saved workspace.
* **Pausing work:** In many ways, this is similar to crash analysis: sometimes you need to shut down your machine in the middle of things and resume later, but you don't want to be forced to start from scratch because you have created an interesting scenario with data in the workspace. Saving a workspace allows you to do this.

With the exception of the scenarios mentioned above, Link is intended to make it unnecessary to save workspaces. All source code changes that you make while editing or tracing your code should immediately end up in text files and be managed using an SCM. The normal workflow is to start each APL session by loading the code into the workspace from source directories. You might want to save a "stub" workspace that contains a very small amount of code that loads everything else from text source, but from version 18.0 of Dyalog APL you can now [easily set that up using text files as well](../Usage/Setup.md), rendering workspaces obsolete as part of your normal development workflow.

### Saving workspaces containing Links

If you `)SAVE` a workspace which has active links in it, this creates a potential conflict between the source code embedded in the workspace and any changes that may have been made to external source since the workspace was saved. If you `)LOAD` a saved workspace, Link will issue a warning along the lines of:

```
IMPORTANT: 1 namespace linked in this workspace: #.myapp
IMPORTANT: Link.Resync is required
```

Except for a few reporting tools like [Link.Status](../API/Link.Status.md), link user commands and API functions will be disabled, until you run [Link.Resync](../API/Link.Resync.md), which will compare the contents of the workspace and the source directories, list the differences and propose actions to take in order to bring the contents of the workspace in line with the source folders.

!!! Note
	**Beware: If you continue working without doing a Resync, strange things may happen:** Link user commands and API functions will refuse to perform any actions, but names defined in the linked namespace contain references to external source files that the interpreter and editor will still honour. Using the built-in editor will read the external source file at the start of an editing session, and any changes made will be written to file, even though Link itself remains disabled.

In other words, you should **NOT** continue working without a Resync, unless you have a very good reason to do so and understand exactly what might happen.

### Distribution

If you want to distribute a workspace created using Link to import code, note that if the workspace is loaded on a machine where the recorded source file names are not valid, this will lead to confusion. Application workspaces should always be built using [Link.Import](../API/Link.Import.md). Alternatively, use [Link.Break](../API/Link.Break.md) to remove the links before you `)SAVE` the workspace.

!!! Note
	If you automate a build process using Link.Create rather than Link.Import, immediately followed by a `⎕SAVE`, there is a significant chance that a File System Watcher callback will be running in a separate thread, which will cause the `⎕SAVE` to fail.

See the discussion about [setting up your environment](../Usage/Setup.md) for more tips on creating development and runtime environments.
