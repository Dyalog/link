# Upgrading to Link 3.0

If you are upgrading from Link 2.0 to 3.0, there are many new options and API functions (and corresponding user commands) that are available. The most significant changes are described here.

### Breaking Changes

Some of the changes have the potential to break existing applications that use Link and require a review of existing code that calls the [Link API](API/index.md):

* When specifying the name of a directory, Link 3.0 will not accept a trailing slash (this is reserved for possible future extensions)
* The `source=both` option has been removed from [Link.Create](API/Link.Create.md).
* Link.List has been renamed [Link.Status](API/Link.Status.md).
* When providing a new value for an array using [Link.Fix](API/Link.Fix.md), Link 3.0 expects the text source form of the array rather than the value of the array (bringing arrays into line with all other cases). To update using a new value, assign the value to the array and call [Link.Add](API/Link.Add.md).
* If you have defined handlers for custom array representations, there have been significant changes to the arguments to the `beforeRead` and `beforeWrite`callback functions. Also, a new `getFilename` callback has been added. These callback functions are described in the documentation for [Link.Create](API/Link.Create.md).
* **fastLoad:** When loading very large bodies of code (thousands or tens of thousands of functions), you may need to specify the new `fastLoad` option on [Link.Create](API/Link.Create.md), in order to disable the checking of whether the names of items actually defined by source files correspond to the name of the file. Without this option, link creation may slow down so much that it could be considered a breaking change.

### Other Significant Changes

The most important new features are:

* The addition of [Link.Pause](API/Link.Pause.md) and [Link.Resync](API/Link.Resync.md) which provide better support for resuming work after a break, especially if the active workspace has been saved and reloaded.
* "Case Coding" of file names, supporting the maintenence of source for names which differ only in case (for example, `FOO` vs `Foo`) in case-insensitive file systems.
* The addition of the [Link.LaunchDir](API/Link.LaunchDir.md) API function, which returns the name of the directory that the interpreter was started from, either using the `LOAD=` or `CONFIGFILE=`setting.

### Change History

A detailed list of new features added to recent releases and a few behavioural changes can be found in the [Link Change History](ChangeHistory.md). 



