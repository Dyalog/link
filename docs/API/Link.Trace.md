# Link.Trace

## Syntax
```text
]LINK.Trace <name> [lines]

message ← ⎕SE.Link.Trace name [lines]
```

!!! ucmdhelp "Show User Command information in the session with `]LINK.Trace -?`"

This function allows you to set stops on selected lines of a function or operator. It will also store the setting in the `.linkconfig` file for the directory, so that the trace settings will be re-applied the next time the directory is linked, as would be the case if they were set using the editor.

## Arguments
- `name` is the name of an existing function or operator.  
- `lines` is a list of integer line numbers, or "⍬" to clear all settings.

## Result
- `message` is a simple character vector containing the previous settings.