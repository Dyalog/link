# Array Formats

By default, Link uses *APL Array Notation (APLAN)* to store arrays in text files. While APLAN is a good format for describing numeric data, nested arrays and many high rank arrays, it is not ideal for storing text data. Link 4.0 introduced experimental support for storing multi-line character data in simple text files.

The configuration setting `text` can be used to enable this feature: If `text` is set to `'aplan'` (the default) then all arrays will be store using APLAN. If `text` is set to `'plain'` then text arrays that adhere to a set of very specific criteria will instead be stored in plain text files. You can set this option when a link is created, or using [`Link.Configure`](../API/Link.Configure.md).

Text files which are not in APLAN format will have a penultimate "sub-extension" section in the file name which records the format of the original array in the workspace. The below table describes the array file extensions, what the content represents, and the specific criteria for storage in plain text file.

For all plain text types, the array must be non-empty.

| File Extension | Array Characteristics                                  | Prohibited characters (`⎕UCS`)
| -------------- | ------------------------------------------------------ | ------------------------------
| .CR.apla       | Simple vector with each line terminated by `⎕UCS 13`   | `10 11 12 133 8232 8233`
| .LF.apla       | Simple vector with each line terminated by `⎕UCS 10`   | `11 12 13 133 8232 8233`
| .CRLF.apla     | Simple vector with each line terminated by `⎕UCS 13 10`| `11 12 133 8232 8233`<sup>*</sup>
| .vec.apla      | Vector of simple character vectors (no scalar elements)| `11 12 13 133 8232 8233`
| .mat.apla      | Simple character matrix                                | `10 11 12 13 133 8232 8233`

<sup>* In addition, every occurring `⎕UCS 10` must be immediately preceded by a `⎕UCS 13` and every occurring `⎕UCS 13` must be immediately followed by `⎕UCS 10`.</sup>

In all other cases, the extension will be just `.apla` and the file will contain APLAN that can represent any APL array.
