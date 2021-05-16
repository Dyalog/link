# Link.Diff

    ]LINK.Diff <ns> [-arrays{=name1,name2,...}] [-sysvars]

    diff ← {opts} ⎕SE.Link.Diff ns

Diff compares both sides of a link and return a 3-column matrix of differences.

The first column have APL names as strings.
The second column have corresponding file names as strings.
The third column has a character amongst `'←→?'`:
- `'←'` means that the APL definition needs to be updated from file
- `'→'` means that the file needs to be updated from APL definition
- `'?'` means that Link.Diff was not able to identify which source is newer

APL names that are not linked to a file (but should) will have `''` as the corresponding file name. File names that are not linked to an APL name (but should) will have `''` as the corresponding APL name. Linked names that have difference in source will be listed with the APL name and the file name. Linked names that sources that match will not be listed

So the easy test to check that the link is up-to-date is `0∊⍴⎕SE.Link.Diff ns`

#### Arguments

- namespace(s)

#### Options

- `arrays` and `sysVars` have the same syntax and defaults as in [Link.Create](Link.Create.md), and allow the comparison of arrays and system variables. By default, only arrays that have a corresponding file are compared.

#### Result

- 3-column matrix (first two columns are strings, third column is characters)