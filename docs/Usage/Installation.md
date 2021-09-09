# Installation

The fully supported version of Link 3.0 is included with Dyalog version 18.1 or later; no installation is required. The instructions on this page only apply if you want to:

- Use Link 3.0 in place of Link 2.0 with Dyalog version 18.0
- Participate in testing pre-releases of Link
- Have some other reason for wanting to use a different version than that which is distributed with Dyalog.

Link is maintained as an open source project at [github.com/dyalog/link](https://github.com/dyalog/link). Start by cloning or downloading aa particular release of Link to a folder on your machine. After that:

**If you only rarely expect to update Link** and you have the necessary permissions, you can **OVERWRITE the installed version of Link** by copying the contents of the StartupSession folder that you have downloaded into **$DYALOG/StartupSession**.

**If you want to regularly update Link using Git**, you should either:

- **Set the `DYALOGSTARTUPSE` environment variable** to point to the StartupSession folder in your checkout or download.

- **Update the configuration file (or under Windows the registry) **, to set the parameter there. Typically, you would edit `~/.dyalog/dyalog.config` to make the change for all versions, or a specific file such as `~/.dyalog/dyalog.180U64.dcfg` for a specific version, to include a line:

  `DYALOGSTARTUPSE: "/Users/mkrom/link/StartupSession"`

**If you are using Dyalog version 18.0**, you will also need to update the user command file used to invoke Links user commands. This should only need to be done once, even if you subsequently download new versions of Link. You can either:

- Overwrite the installed version of the Link user commands by copying **SALT/spice/Link.dyalog**, from the downloaded repository, into **$DYALOG/SALT/spice/Link.dyalog** (assuming you have the necessary permissions).

- Place the copy of **SALT/spice/Link.dyalog**, from the downloaded repository, into your **MyUCMDs** folder. This will cause it to take priority over the installed copy. Under Linux or Mac, you would typically achieve this with the command like the following (assuming you checked Link out to ~/link):

  `cp ~/link/SALT/spice/Link.dyalog ~/MyUCMDs`

You will need to restart Dyalog APL each time you update these files.