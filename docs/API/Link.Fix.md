# Link.Fix

    {fixed} ← {namespace} {name} {oldname} ⎕SE.Link. Fix src 

This function is intended as a replacement for `⎕FIX` or `⎕FX` in environments in which some or all namespaces are linked. It will allow you to add or modify an array, function, operator, or scripted namespace, class or interface, without worrying about whether the namespace is linked. The source will be fixed in the target namespace, and the corresponding file will be created/updated if there is an active link which specifies that the namespace is being watched.

For arrays, Fix expects the source to be Array Notation (you can use `⎕SE.Dyalog.Array.Serialise` to produce it from array values). For other items, it uses the source in the form that would be produced by `⎕NR` or `⎕SRC`. In all cases the source is a vector of text vectors.

Normally, one can use `⎕FIX` or `⎕FX` inside the target namespace, e.g. `myns.⎕FIX 'avg←{sum←+⌿⍵' 'sum÷≢⍵}'` but since `Link.Fix` exists only as `⎕SE.Link.Fix` then the target namespace must be explicitly specified as in `myns ⎕SE.Link.Fix 'avg←{sum←+⌿⍵' 'sum÷≢⍵}'`. The default namespace is the calling namespace.

Note: If the item has already been updated or created and you only need to trigger an update of the source file, you can also use [Link.Add](Link.Add.md).

#### Right Argument: source

- A vector of character vectors representing the source code of the item to be defined

#### Left Argument: {namespace} {name} {oldname}

- namespace: The namespace (by name or by reference) within which the source shall be fixed. Defaults to `''` which means the calling namespace.  
- name: The name of the item being defined. Defaults to `''` which means that the name will be defined by the source to be fixed. The name is required only for arrays, because their source doesn't contain their name.
- oldname: The old name of the fixed item, if this operation is a rename. Defaults to `name`, which means it is not a rename.

#### Result

- The name of the item that was defined.