# Installation

Link 4.0 is included with Dyalog version 19.0 or later, and is supported for use with version 18.2.

!!!Note
	For Dyalog to automatically update workspace contents in response to changes to files made using external editors or source code management systems, .NET must be installed.

	The .NET Framework is included with Microsoft Windows. For other platforms, .NET can be downloaded from [dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).
	
	Link 4.0 has been tested with the .NET Framework version 4 and .NET versions 6 and 8, and is expected to work with any later version of .NET.

The instructions on this page only apply if you want to user a different release than that which is distributed with your version of Dyalog APL.

!!!Note
	If you use a non-standard Dyalog session (.dse file), contact support@dyalog.com for guidance on enabling Link.

## Instructions

Link is maintained as an open source project at [github.com/dyalog/link](https://github.com/dyalog/link).

**Start by downloading** one of the zip files included with the latest release of Link 4.0 from [github.com/Dyalog/link/releases](https://github.com/Dyalog/link/releases). If you are using Dyalog version 19.0 or later, use the file named `link-v4.0.nn.zip`; Extract the subfolder called `StartupSession`, which contains the code required to run Link. 

**If you have version 18.2**, follow the same instructions, but use the zip file with the suffix `-v182`. This file also contains code that is used to populate the `⎕SE.Dyalog` namespace, it is required because Link 3.0 included this code, which has moved to a separate repository.

If you have the necessary permissions, you can **OVERWRITE the installed version of Link** by replacing the `StartupSession` folder that already exists in the main Dyalog program folder with the downloaded folder.

If you do not have permission to overwrite the Dyalog installation, or you do not wish to overwrite the original version of Link that was included with the interpreter (Dyalog recommends keeping the original code in case you need to fall back), you can keep the code outside the main program folder. In this case, you will need to declare the location of the folder by setting the parameter `DYALOGLINK` (v19.0 or later), or `DYALOGSTARTUPSE` (v18.2). You can add it to the command line when you start APL, but it is probably easier to use one of the following alternatives:

- **Set the `DYALOGLINK` or `DYALOGSTARTUPSE` environment variable** to point to the StartupSession folder.

- **Update the configuration file (or the Windows registry)**, to set the parameter there. Typically, you would edit `~/.dyalog/dyalog.config` to make the change for all versions, or a specific file such as `~/.dyalog/dyalog.182U64.dcfg` for a specific version, to include the line:  
		
		`DYALOGLINK: "/Users/mkrom/link/StartupSession"` (version 19.0 or later)
    	`DYALOGSTARTUPSE: "/Users/mkrom/link/StartupSession"` (version 18.2)
