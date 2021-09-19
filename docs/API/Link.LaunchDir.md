# Link.LaunchDir

    dir ←  ⎕SE.Link.LaunchDir

If APL was launched with a `LOAD` or `CONFIGFILE` parameter, `Link.LaunchDir` returns the fully qualified name of the directory in which the file used to start APL is located. If both were specified, the `LOAD`ed file takes priority.

If neither parameter is specified, the current working directory is returned.

This function is useful during the startup of applications loaded directly from source, and allows you to locate additional resources that are located relative to the source for the code used to start the application. For examples of usage, see [setting up your environment](../Usage/Setup.md)

#### Arguments

- None

#### Result

- A character vector containing a fully qualified directory name.