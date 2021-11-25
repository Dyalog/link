# Installation

Link 3.0 is included with Dyalog version 18.2 or later.

!!!Note
	Automatic detection of file changes requires .NET Framework or .NET Core. These can be downloaded from [dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).
	
	To find out which versions are supported, see [section 2.1 of the .NET Core Interface Guide](https://docs.dyalog.com/latest/dotNET%20Core%20Interface%20Guide.pdf) and under the heading "Prerequisites" in [chapter 1 of the Dyalog for Microsoft Windows .NET Framework Interface Guide](https://docs.dyalog.com/latest/Dyalog%20for%20Microsoft%20Windows%20.NET%20Framework%20Interface%20Guide.pdf).
	

The instructions on this page only apply if you want to:

- Use Link 3.0 with Dyalog version 18.0 (in place of Link 2.0).
- Participate in testing pre-releases of Link.
- Have some other reason for wanting to use a different version than that which is distributed with Dyalog APL.

Link is maintained as an open source project at [github.com/dyalog/link](https://github.com/dyalog/link). Start by downloading (or cloning) the latest release of Link and locating the subfolder called `StartupSession`. This folder contains the code required to run Link.

**If you only rarely expect to update Link** and you have the necessary permissions, you can **OVERWRITE the installed version of Link** by replacing the StartupSession folder that already exists in the main Dyalog program folder with the downloaded folder.

**If you want to regularly update Link as new versions are made available**, or you do not have permission to partially overwrite the Dyalog installation, you can keep the code outside the main program folder, so it can easily be updated with a `git pull`, or a copy operation that does not require special permissions. You will need to declare the location of the folder by setting the `DYALOGSTARTUPSE` parameter. You can add it to the command line when you start APL, but it is probably easier to use one of the following alternatives:

- **Set the `DYALOGSTARTUPSE` environment variable** to point to the StartupSession folder.

- **Update the configuration file (or the Windows registry) **, to set the parameter there. Typically, you would edit `~/.dyalog/dyalog.config` to make the change for all versions, or a specific file such as `~/.dyalog/dyalog.180U64.dcfg` for a specific version, to include a line:

  `DYALOGSTARTUPSE: "/Users/mkrom/link/StartupSession"`

**If you are using Dyalog version 18.0**, you will also need to update the user command file used to invoke Link user commands. This only needs to be done once, because the new user command file is designed to pick user command definitions up from the current copy of Link.

The user command file is **SALT/spice/Link.dyalog**. If you have not done a complete checkout or clone of the repository, you will need to download this file from GitHub, as it is not included in the normal release package file.

- If you have permission, you can overwrite the installed version of the Link user commands by copying the file into **$DYALOG/SALT/spice/Link.dyalog**.

- Alternatively you can place a copy of the file in your **MyUCMDs** folder. This will cause it to take priority over the installed copy. Under Linux or Mac, you may need to create the folder yourself, under Windows the installation of Dyalog APL should have created it for you.


You will need to restart Dyalog APL each time you update any of the files mentioned above.