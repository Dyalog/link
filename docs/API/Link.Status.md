# Link.Status

    ]LINK.Status [<ns>] [-extended]
    
    status ← {opts} ⎕SE.Link.Status ns 

This function provides information about existing links.

#### Arguments

- ns: namespace to look for links in (use `''` to list all links)

#### Options

- **extended** {**0**|1}
   
   > Request additional information

#### Result

- Table of links
   > First three columns are always:
   - namespace reference
   - directory name
   - number of linked files and directories (excluding root directory)
   > If `extended` was specified, options settings for each link:
   - case code
   - flatten
   - force extensions
   - force filenames
   - watch
   - paused
