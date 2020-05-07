# Link documentation

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

For more information:
* [Installation instructions](Installation)
* [Overview](Overview)
* [Getting started](GettingStarted)
* [Full API reference](API)