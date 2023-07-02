# Link.Stop

## Syntax
```text
]LINK.Stop <name> [lines]

message ← ⎕SE.Link.Stop name [lines]
```

!!! ucmdhelp "Show User Command information in the session with `]LINK.Stop -?`"

This function allows you to set stops on selected lines of a function or operator. It will also store the setting in the `.linkconfig` file for the directory, so that the stops will be re-applied the next time the directory is linked, as would be the case if the stops were set using the editor.

## Arguments
- `name` is the name of an existing function or operator.  
- `lines` is a list of integer line numbers, or "⍬" to clear all stops.  

## Result
- `message` is a simple character vector containing the previous settings.