This function provides details of texisting links.

#### Arguments

- namespace to look for links in (use # to list all links)

#### Options

- **extended** {**0**|1}
   > Request additional information

#### Result

- Table of links
   > First three columns are always:
   - namespace reference
   - directory name
   - number of linked items scripts
   > If **extended** was specified, link options settings:
   - case code
   - flatten
   - force extensions
   - force filenames
   - watch
   