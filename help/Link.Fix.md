# Link.Fix

This function is intended as a replacement for `⎕FIX` or `⎕FX` in code which manipulates linked namespaces. It will allow you to add
or modify a function, operator, or scripted object within a linked namespace, creating or updating the correponding source file.

Note: If the item has already been updated or created and you
only need to update the source file, you can also use [Add](Link.Add.md).

When an item is edited, a call is made to this function by the APL interpreter.

#### Right Argument: source

- A vector of character vectors representing the source code of the item to be defined

#### Left Argument: namespace name [oldname]

> The left argument is a two or three element vector:

- namespace: The namespace within which the object shall be fixed. Normally, one can use `⎕FIX` or `⎕FX` inside the target namespace, e.g. `myns.⎕FIX 'avg←{sum←+⌿⍵' 'sum÷≢⍵}'` but since `Link.Fix` exists only as `⎕SE.Link.Fix` then the target namespace must be explicitly specified.
- name: The name of the object being defined
- oldname: The old name of the object, if this operation is a rename

#### Result

- 1 if the object was found to be in a linked namespace, else 0