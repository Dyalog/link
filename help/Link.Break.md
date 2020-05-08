# Link.Break

Breaks an existing link: Does not affect the contents of the active workspace, but removes
all traces of the link, preventing any further synchronisation from taking place.

#### Arguments

- namespace name or reference

#### Options

- `all`: Break all existing links (arguments are then irrelevant)
- `exact`: Break only the argument namespace, but not children namespaces if some have their own links

#### Result