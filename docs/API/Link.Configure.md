# Link.Configure

## Syntax

    ]LINK.Configure <target> [settings]
    
    message ← ⎕SE.Link.Configure target [settings]

!!! ucmdhelp "Show User Command information in the session with `]LINK.Configure -?`"

## Arguments

- `target` can be `*` to refer to the user configuration. It can be a reference to, or a simple character vector containing the name of a namespace. Finally, it can be the full name of a configuration file. 
- `settings` is a list in the form `name:value`, providing new values for configuration settings. If no value is provided (there is nothing following the colon), the setting is deleted from the corresponding configuration file. 

## Result

- If no `settings` were provided, Configure returns a formatted display of the current contents of the configuration file. Otherwise, it returns the previous values for any settings mentioned in the argument. 
