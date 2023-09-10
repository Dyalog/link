# Link
Link enables the use of text files as the primary storage mechanism for APL source code, and is expected to replace the use of traditional binary workspaces and component files for many new APL projects. The current stable version is 3.0, which is distributed with version 18.2 and has [up-to-date user documentation](https://dyalog.github.io/link/).

# Link Versions
Although Link is developed as a GitHub project and it is possible to fork or clone it and configure Dyalog APL to use it in this fashion, most users of Link will be using a version which is delivered via the Dyalog installer and updated using the Dyalog patch mechanism. Currently supported versions are:

## Version 4.0 (Dyalog v19.0 - compatible with v18.2)
The master branch contains the code which will become 4.0 and be distributed with Dyalog 19.0. The code and documentation are both "work in progress", but the master has always passed QA and as of September 10th 2023, the documentation is up-to-date with respect to new functionality.

## Version 3.0 (Dyalog v18.2 - compatible with v18.0)
Version 3.0 is distributed with version 18.2 and works with version 18.0. Until version 4.0 and Dyalog v19.0 are released, this is the recommended version for anyone getting started with Link and Dyalog APL. The [online documentation](https://dyalog.github.io/link/) is maintained using markdown files which can be found in `docs` folder and deployed using `mkdocs` and `mike`, hosted with GitHub Pages.

## Version 2.0 (Dyalog v17.1 & 18.0)
Version 2.0 is distributed with Dyalog APL versions 17.1 and 18.0. It is no longer being actively developed. Support (and fixes if necessary) are available to Dyalog customers via our normal support channels.

[Version 2.0 documentation](https://github.com/Dyalog/link/wiki) is hosted using the old GitHub wiki technology, and includes a [Version 2.0 API reference](https://github.com/Dyalog/link/wiki/API).
