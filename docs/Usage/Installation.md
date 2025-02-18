# Installation

Link is 

-   **included** with Dyalog version 19.0 and later
-   **supported** for use with version 18.2

It depends on the .NET Framework – see below.

Use these instructions to 

-   **Install Link** with Dyalog 18.2 or

-   Install a **different Link version** from that distributed with your version of Dyalog

	??? detail "How to display your installed Link version"

		```apl
		      ⎕SE.Link.Version
		4.0.17       
		```

!!! warning "Non-standard session file"

	If you use a non-standard Dyalog session (`.dse`) file, contact [support@dyalog.com](mailto:support@dyalog.com) for guidance on enabling Link.


## Required: the .NET Framework

.NET allows Dyalog to update workspace contents automatically when you use external editors or source code management systems to edit the files. Without .NET, [watch](http://localhost:8000/Usage/api/Link.Create.md#watch) can only be set to `ns` and Link can only update files with changes made by the Dyalog editor or using [Link.Add](../API/Link.Add.md).

Link has been tested with the .NET Framework version 4 and .NET versions 6 and 8, and is expected to work with any later version of .NET.

=== "Microsoft Windows"

	The .NET Framework is already installed; there is nothing for you to do.

=== "Linux, macOS"

	Download .NET and follow the installation instructions.

	[dotnet.microsoft.com/download](https://dotnet.microsoft.com/download) 

=== "AIX"

	.NET is not available for AIX. Therefore [watch](../api/Link.Create.md#watch) can only be set to **ns** and Link can only update files with changes made by the Dyalog editor. The workspace contents will not be updated as a result of changes made by external editors.


## Step 2: Download a Link ZIP

:fontawesome-solid-download:&nbsp;
[Download the ZIP](https://github.com/Dyalog/link/releases) for your version

	link-v4.0.nn.zip       ⍝ Dyalog 19.0+
	link-v4.0.nn-v182.zip  ⍝ Dyalog 18.2

where `nn` is a Link patch number.

Extract subfolder `StartupSession/Link`.


## Step 3: Install your Link folder

### In the default location

The Link folder belongs in the `StartupSession` folder.
By default, this is

=== "Microsoft Windows"

	where Dyalog is installed, e.g.

		C:\Program Files\Dyalog\Dyalog APL-64 19.0 Unicode\StartupSession

=== "Linux, macOS, AIX"

	within your home folder, e.g.

		~/dyalog.190UC64.files/StartupSession  ⍝ Dyalog 19.0+
		~/dyalog.182UC64.files/StartupSession  ⍝ Dyalog 18.2

If you have write access to the default location

-   move the `Link` folder outside it (as a fallback)
-   copy the extracted `Link` folder into it

### In a custom location

If you do not have write access to the default location

1.  Make a new folder in your home directory
1.  Copy the extracted `StartupSession` folder to it

	E.g.

	=== "Microsoft Windows"

			C:\Users\mkrom\mydyalogfiles\StartupSession\Link

	=== "Linux, macOS, AIX"

			~/mydyalogfiles/StartupSession/Link

1.  Declare the custom location of your Link folder

	=== "Microsoft Windows"

		In the Windows Registry, [set the environment variable](https://superuser.com/questions/284342/what-are-path-and-other-environment-variables-and-how-can-i-set-or-use-them) as below.

	=== "Linux, macOS, AIX"

		Select a configuration file. 

			~/.dyalog/dyalog.config       ⍝ all versions of Dyalog
			~/.dyalog/dyalog.182U64.dcfg  ⍝ specific version, such as 18.2

		In your configuration file, set the environment variable as below.

	The relevant environment variable changed after Dyalog 18.2.

	=== "Dyalog 19.0+"

		Declare as `DYALOGLINK` the filepath that **contains** the `StartupSession` folder.
		Some examples:

			DYALOGLINK  C:\Users\mkrom\mydyalogfiles

			DYALOGLINK: "[HOME]/dyalog.190U64.files",
			DYALOGLINK: "[HOME]/mydyalogfiles",
			DYALOGLINK: "/Users/mkrom/",

	=== "Dyalog 18.2"

		Declare as `DYALOGSTARTUPSE` the filepath of the `StartupSession` folder.
		For example:

			DYALOGSTARTUPSE  C:\Users\mkrom\StartupSession

			DYALOGSTARTUPSE: "/Users/mkrom/StartupSession",

## Step 4: Refresh the user commands

```apl
      ]ureset
153 commands reloaded
```

## Step 5: Display the Link version

Test your installation by querying the Link version.

Quit and restart APL.
Confirm you see the Link version you intended to install.

```apl
      ⎕SE.Link.Version
4.0.20
```
