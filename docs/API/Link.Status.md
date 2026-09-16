# Link.Status

    ]LINK.Status [<ns>] [-extended]
    
    status ← {opts} ⎕SE.Link.Status ns 

!!! ucmdhelp "Show User Command information in the session with `]LINK.Status -?`"

This function provides information about existing links.

#### Arguments

- ns: namespace to look for links in (use `''` to list all links)

#### Options

- **extended** {**0**|1}
  
   > Request additional information

#### Result

- Table of links
   > The first row contains column headers.
   > First four columns are always:
   - namespace reference
   - arrow showing the direction(s) in which the link is watched
   - name of the linked directory or source file
   - number of linked files and directories (excluding root directory)
   > If `extended` was specified, options settings for each link:
   - case code
   - flatten
   - merge
   - force extensions
   - force filenames
   - watch
   - record flags
   - paused
