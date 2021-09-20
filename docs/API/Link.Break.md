# Link.Break

    ]LINK.Break [<ns>] [-all={#|⎕SE|*}] [-recursive={on|off|error}]
    
    message ← {options} ⎕SE.Link.Break namespace

Breaks an existing link: Does not affect the contents of the active workspace except to remove all traces of the link, preventing any further synchronisation from taking place.

## Arguments
`namespace` is a list of namespace names as character vectors or references

In the user command, `<ns>` is a space-separated list of namespace names

## Options

### all
{**#**`|⎕SE|*`}

By default (`-all` or `-all=#`), break links to all namespaces within the main workspace. 

To break links to namespaces in the session space, use `-all=⎕SE`, and to break absolutely all links, `-all=*`.

Note that the list of namespaces is ignored when `-all` is used.

### recursive
{on|off|**error**}

Break child namespaces too if they have separately defined links.


## Result
`message` is a simple character vector describing namespaces that were:
- effectively unlinked
- not linked in the first place
- not found