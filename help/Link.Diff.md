# Link.Diff

    ]LINK.Diff <ns> [-arrays{=name1,name2,...}] [-sysvars]

    diff ← {opts} ⎕SE.Link.Diff ns

Diff will compare both sides of a link and return a 2-column matrix of differences.

The first column will have APL names, and the second column will have corresponding file names.

- APL names that are not linked to a file (but should) will have `''` as the corresponding file name
- File names that are not linked to an APL name (but should) will have `''` as the corresponding APL name
- Linked names that have difference in source will be listed with the APL name and the file name
- Linked names that sources that match will not be listed

So the easy test to check that the link is up-to-date is `~0∊⍴⎕SE.Link.Diff ns`

#### Arguments

- namespace(s)

#### Options

- `arrays` and `sysVars` have the same syntax and defaults as in [Link.Create](Link.Create.md), and allow the comparison of arrays and system variables, which would otherwise be ignored.

#### Result

- 2-column matrix of strings