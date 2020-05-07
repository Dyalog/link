***Link*** facilitates the use of text files for APL source code
through the creation of one or more ***links*** between *namespaces* inside the active workspace
and *directories* containing source code. Functionality provided by links include:

* **Keeping Source Files Up-to-date:** 
Typically, links are configured to replicate any changes made using the Dyalog editor
and tracer to external source files. As a result, the source files are kept up-to-date
without further action by the developer.

* **Integrating External Changes into the workspace:**
Links can be also be configured to use a "file system watcher" to replicate changes made
using external tools such as editors and source code management systems inside the active
APL session. This functionality is currently only available under Microsoft Windows, 
but the intention is to extend support to all platforms.

* **Loading and Saving Source Files:**
Link can also be used to copy source code into or out of an APL session without subsequently
detecting and replicating changes made in- or outside the APL system.

Note that Link is ***not a source code management system***,
but is designed to support the use of tools like Git or Subversion to manage the linked directories.

**Installation:** 
*Link* is implemented as a set of APL functions which are loaded into a session namespace
(```⎕SE.Link```) when Dyalog APL version 17.1 or later is started with a default session file. For instructions on installing 
and using Link with version 17.0 Unicode, or a more recent interpreter with a non-standard session file,
please read the [installation instructions](Installation.md).

**Usage:**
Once installed, Links can be created and managed with user commands. While this is probably the most convenient
mechanism for interactive or casual use,
the API functions in the ```⎕SE.Link``` namespace can also be called directly. Direct API calls are the recommended
choice if you want to integrate Link into your own load / build tools, or other "devops" code.

The [API reference](API.md) lists the API functions and their arguments and options. It can also
be used as documentation for the user commands, since each user command is a thin cover for
an API function and takes the same arguments and options.

For more information on getting started with Link, see the [Overview](Overview.md),