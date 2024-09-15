# Installation

Link 4.0 is included with Dyalog version 19.0 and later, and is supported for use with version 18.2.
It depends on .NET.

Use these instructions to 

-   use a different release from that distributed with your version of Dyalog APL, or
-   install Link with Dyalog 18.2

Link is maintained as an open-source project at [github.com/dyalog/link](https://github.com/dyalog/link).

!!! warning "Non-standard session file"

	If you use a non-standard Dyalog session (`.dse`) file, contact [support@dyalog.com](mailto:support@dyalog.com) for guidance on enabling Link.


## Required: .NET Framework

.NET allows Dyalog to update workspace contents automatically when you use external editors or source code management systems to edit the files.

Link 4.0 has been tested with the .NET Framework version 4 and .NET versions 6 and 8, and is expected to work with any later version of .NET.

=== ":fontawesome-brands-windows:" Microsoft Windows"

	The .NET Framework is already installed; there is nothing for you to do.

=== ":fontawesome-brands-linux: :fontawesome-brands-apple: Linux and macOS"

	Download .NET and follow the installation instructions.

	:fontawesome-brands-windows:
	[dotnet.microsoft.com/download](https://dotnet.microsoft.com/download) 


## Step 2: Download Link ZIP

To use a **different** Link release from that distributed with your version of Dyalog APL, download the corresponding ZIP.

:fontawesome-brands-github:
[github.com/Dyalog/link/releases](https://github.com/Dyalog/link/releases)

=== "Dyalog 19.0+"

		link-v4.0.nn.zip

=== "Dyalog 18.2"

		link-v4.0.nn-v182.zip

where `nn` is a patch number.

Extract subfolder `StartupSession/Link`.


## Step 3: Install your Link folder

By default, your Link folder is contained in your home folder in:

=== "Dyalog 19.0+"

		dyalog.190UC64.files/StartupSession

=== "Dyalog 18.2"

		dyalog.182UC64.files/StartupSession

**If you have write access to this folder**

-   rename its existing child `Link` folder as a fallback
-   copy the extracted `Link` folder here

For example, if your user name is `judy` the full filepath of the extracted folder would be

=== "Dyalog 19.0+"

		/Users/judy/dyalog.190UC64.files/StartupSession/Link

=== "Dyalog 18.2"

		/Users/judy/dyalog.180UC64.files/StartupSession/Link


**If you do not have write access to this folder**

-   Make a new folder, e.g. `my.dyalog.files` in your home folder
-   Copy the extracted `StartupSession` folder to it

	That would create the filepath

		/Users/judy/my.dyalog.files/StartupSession/Link


## Step 4: Declare the location of your Link folder

### :fontawesome-brands-windows: Microsoft Windows

In the Windows Registry…

==FIXME==

### :fontawesome-brands-linux: :fontawesome-brands-apple: Linux and macOS

Select a configuration file. 

For all versions of Dyalog

	~/.dyalog/dyalog.config

For a specific version, such as 18.2

	~/.dyalog/dyalog.182U64.dcfg

In your configuration file, declare the Link filepath:


=== "Dyalog 19.0+"

	Declare the filepath that contains the `StartupSession` folder.
	Some examples:

		DYALOGLINK: "[HOME]/dyalog.190U64.files",
		DYALOGLINK: "[HOME]/my.dyalog.files",
		DYALOGLINK: "/Users/mkrom/link",

=== "Dyalog 18.2"

	Declare the filepath of the `StartupSession` folder.
	For example:

		DYALOGSTARTUPSE: "/Users/mkrom/link/StartupSession",

## Step 5: Refresh user commands

```apl
      ]ureset
153 commands reloaded
```

## Step 6: Query Link version

Test your installation by querying the Link version.

Quit and restart APL.
Confirm you see the Link version you intended to install.

```apl
      ⎕SE.Link.Version
4.0.20
```
