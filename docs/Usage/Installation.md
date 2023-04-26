# Installation

Link 4.0 is included with Dyalog version 19.0 or later, and is supported under version 18.2.

!!!Note
	For Dyalog to automatically update workspace contents due to file changes requires Microsoft .NET.
	
	The .NET Framework is included with Microsoft windows. For other platforms, .NET can be downloaded from [dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).
	
	Link 4.0 has been tested with the .NET Framework v4.0 and .NET 6.0, and is expected to work with any later version of .NET.

The instructions on this page only apply if you want to work with a different version that which is distributed with your version of Dyalog APL, for example to test a pre-release.

If you use a non-standard Dyalog session (.dse file), contact support@dyalog.com for guidance on enabling Link.

Link is maintained as an open source project at [github.com/dyalog/link](https://github.com/dyalog/link).

!!!Note
    The installation instructions below have not been updated for Link 4.0.

	DO NOT try to use the instructions below, they WILL NOT WORK.

	Please come back soon!

**Start by downloading** the latest release from [github.com/Dyalog/link/releases](https://github.com/Dyalog/link/releases) and extracting the subfolder called `StartupSession`. This folder contains the code required to run Link.

If you have the necessary permissions, you can **OVERWRITE the installed version of Link** by replacing the `StartupSession` folder that already exists in the main Dyalog program folder with the downloaded folder.

If you do not have permission to partially overwrite the Dyalog installation, you can keep the code outside the main program folder. You will need to declare the location of the folder by setting the `DYALOGSTARTUPSE` parameter. You can add it to the command line when you start APL, but it is probably easier to use one of the following alternatives:

- **Set the `DYALOGSTARTUPSE` environment variable** to point to the StartupSession folder.

- **Update the configuration file (or the Windows registry) **, to set the parameter there. Typically, you would edit `~/.dyalog/dyalog.config` to make the change for all versions, or a specific file such as `~/.dyalog/dyalog.180U64.dcfg` for a specific version, to include the line:  
		
		    `DYALOGSTARTUPSE: "/Users/mkrom/link/StartupSession"`
				

**If you are using Dyalog version 18.0**, you will also need to update the user command file used to invoke Link user commands. This only needs to be done once, because the new user command file is designed to pick user command definitions up from the current copy of Link.

The user command file is **SALT/spice/Link.dyalog**. If you have not done a complete checkout or clone of the repository, you will need to download this file from GitHub, as it is not included in the normal release package file.

- If you have permission, you can overwrite the installed version of the Link user commands by copying the file into **$DYALOG/SALT/spice/Link.dyalog**.

- Alternatively you can place a copy of the file in your **MyUCMDs** folder. This will cause it to take priority over the installed copy. Under Linux or Mac, you may need to create the folder yourself, under Windows the installation of Dyalog APL should have created it for you.


You will need to restart Dyalog APL each time you update any of the files mentioned above.