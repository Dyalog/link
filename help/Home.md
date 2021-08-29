# Link documentation

**NOTE:** This is the documentation for Link 2.0, which is distrubuted with Dyalog APL versions 17.1 and 18.0.
If you are looking for documentation for Link version 3.0 it is [available separately](https://dyalog.github.io/link/).
If you are using version 18.0 and just getting started with Link, installing version 3.0 is highly recommended.

***Link*** facilitates the use of text files for APL source code
by associating **namespaces** inside the active workspace
to **directories** containing source code. Functionality provided by links include:

* **Keeping Source Files Up-to-date:** 
Typically, links are configured to replicate any changes made using the Dyalog editor
and tracer to external source files. As a result, the source files are kept up-to-date
without further action by the developer.

* **Integrating External Changes into the workspace:**
Links is also typically configured to replicate changes made to the text files
(using external tools such as editors and source code management systems) inside the active
APL workspace.

* **Loading and Saving Source Files:**
Link can also be used to copy source code into or out of an APL session without subsequently
detecting and replicating changes made in- or outside the APL system.

Note that Link is ***not a source code management system***,
but is designed to support the use of tools like Git or Subversion to manage the linked directories.

For more information:
* [Installation instructions](Installation.md)
* [Overview](Overview.md)
* [Getting started](GettingStarted.md)
* [Full API reference](API.md)