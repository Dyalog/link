# Link.Add

## Syntax

```text
]LINK.Add name←expression

message ← ⎕SE.Link.Add name←expression 
```

!!! ucmdhelp "Show User Command information in the session with `]LINK.Add -?`"

This function allows you to add one or more APL items to the link, creating the appropriate representation in the linked directory. New in 4.0 is that you can evaluate an expression and assign the result into the items before ``]LINK.Add`` is run. Note that a source file will only be created or updated if the item is in a linked namespace.

This is useful to write a new or modified array to a source file: [arrays are normally not written to file by Link](Link.Create.md#arrays).

It is also useful when a change has been made to a linked item using any mechanism other than the APL editor, for example the definition of a new dfn using assignment, or the use of `)COPY` to bring new objects into the workspace.

!!! Note
    You can create or update an item from source while adding it to the Link by calling [Link.Fix](Link.Fix.md).

## Arguments

- `name` is a simple character vector or nested vector of character vectors containing the names of items to be added to the link.  
    In the user command, `<name>` is a space-separated list of names.
- `expression` is an expression that is evaluated and assigned to the single or list of variables before ``]LINK.ADD`` takes affect. That is, that the expression is not saved, but the result of it is. 

## Result

- `message` is a simple character vector describing items that were:
  - Added (they belong in a linked namespace and were successfully added)
  - Not linked (they do not belong to a linked namespace)
  - Not found (the name doesn't exist at all)