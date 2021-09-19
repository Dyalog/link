# Link.Version

    version ←  ⎕SE.Link.Version

This niladic function returns the current Link [semantic version number](https://semver.org/) as a string in the format `'X.Y.Z'`, where X Y and Z are non-negative integers. Development or experimental versions will have a trailing hyphen and string such as `'X.Y.Z-alpha3'`.
