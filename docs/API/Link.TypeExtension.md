# Link.TypeExtension

    ext ← opts ⎕SE.Link.TypeExtension nc 

This function is used internally by Link, but is also available for use when implementing extensions to Link using exits like `beforeRead` and `beforeWrite`.

#### Right Argument

- nameclass of item

#### Left argument

- link options namespace used as left argument of [Link.Create](Link.Create.md)

#### Result

- character vector of the extension (without leading `'.'`)\
Note that extension will be (`,'/'`) for unscripted namespaces (name class `¯9`) because they map to directories