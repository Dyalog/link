# Link.Fix

    {fixed} ← {namespace} {name} {oldname} ⎕SE.Link. Fix src 

This function is intended as a replacement for `⎕FIX` or `⎕FX` in code which manipulates linked namespaces.  It will allow you to add
or modify an array, function, operator, or scripted namespace, class or interface within a linked namespace. The source will be fixed in the target namespace, and the corresponding file will be created/updated.

For arrays, Fix uses the Array Notation from `⎕SE.Dyalog.Array`. For other items, it uses the source provided by `⎕NR` or `⎕SRC`. In all cases the source is a vector of text vectors.

Normally, one can use `⎕FIX` or `⎕FX` inside the target namespace, e.g. `myns.⎕FIX 'avg←{sum←+⌿⍵' 'sum÷≢⍵}'` but since `Link.Fix` exists only as `⎕SE.Link.Fix` then the target namespace must be explicitly specified as in `myns ⎕SE.Link.Fix 'avg←{sum←+⌿⍵' 'sum÷≢⍵}'`. The default namespace is the calling namespace.

Note: If the item has already been updated or created and you
only need to update the source file, you can also use [Link.Add](Link.Add.md).

When an item is edited and the namespace is being watched, a call is made to this function by the APL interpreter.

#### Right Argument: source

- A vector of character vectors representing the source code of the item to be defined

#### Left Argument: {namespace} {name} {oldname}

- namespace: The namespace (by name or by reference) within which the source shall be fixed. Defaults to `''` which means the calling namespace.  
- name: The name of the item being defined. Defaults to `''` which means that the name is defined by the source to be fixed. The name is required only for arrays, because their source doesn't contain their name.
- oldname: The old name of the fixed item, if this operation is a rename. Defaults to `name`, which means it is not a rename.

#### Result

- 1 if the item was fixed in a linked namespace, else 0 (and the source code wasn't fixed)