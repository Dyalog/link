## Link versus Workspaces

As the *versus* in the heading is intended to imply, the main purpose of Link is to replace many uses of workspaces. Link is intended to make it possible for APL users to move away from the use of workspaces as a mechanism for storing APL source code.

### Are Workspaces Dead Now?

No: Workspaces still have many uses, even if they are no longer a recommended mechanism for source code management:

* **Distribution:** For large applications, it will be inconvenient or undesirable to ship large collections of source files that are loaded at startup. The use of workspaces as a mechanism for the distribution of packaged collections of code and data is expected to continue.
* **Crash Analysis:** When an application fails, it is often useful to save the workspace, complete with execution stack, code and data, for subsequent analysis and sometimes resumption of execution. Dyalog will continue to support this, although we may gradually impose some restrictions, for example requiring the same version and variant of the interpreter in order to resume execution of a saved workspace.
* **Pausing work:** In many ways, this is similar to crash analysis: sometimes you need to shut down your machine in the middle of things and resume later, but you don't want to be forced to start from scratch because you have created an interesting scenario with data in the workspace. Saving a workspace allows you to do this.

With the exception of the scenarios mentioned above, Link is intended to make it unnecessary to save workspaces. All source code changes that you make while editing or tracing your code should immediately end up in text files and be managed using an SCM. The normal workflow is to start each APL session by loading the code into the workspace from source directories. You might want to save a "stub" workspace that contains a very small amount of code that loads everything else from text source, but from version 18.0 of Dyalog APL you can now [easily set that up using text files as well](/Usage/Setup), rendering workspaces obsolete as part of your normal development workflow.

### Saving workspaces containing Links

If you do `)SAVE` a workspace which has active links in it, this creates a potentially confusing situation. Objects defined in the workspace will still contain the information that was created by `2 ⎕FIX`,  which means that after a re-load, editing may cause the editor itself to update the source files, even though Link has not been activated. If you reload the workspace on a different machine, the source files may not be available, leading to confusing error messages.

You should always [Link.Break](/API/Link.Break) or [Link.Resync](/API/Link.Resync) after loading a workspace which was saved with links in it.