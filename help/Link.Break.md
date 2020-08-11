# Link.Break

Breaks an existing link: Does not affect the contents of the active workspace, but removes
all traces of the link, preventing any further synchronisation from taking place.

#### Arguments

- namespace name(s) or reference(s)

#### Options

- `all`: Break all existing links (arguments are then irrelevant)
- `recursive` {on|off|**error**}: Break children namespaces too if some have their own links to their own directories
 

#### Result