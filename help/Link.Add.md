This function allows you to add an item to the link, creating the appropriate representation in the linked directory. Normally, new APL items (except arrays) will automatically be added when saved by the editor (including closing the editor by hitting <kbd>Esc</kbd>), but if you create an item outside the editor (for example using `⎕FX`, `⎕CY`/`)copy`, or `⎕NS` ), or you want to explicitly add an array to the link, you will need to tell Link to add this item.

#### Arguments

- item name(s)

#### Options

- `filename`: custom name (optionally with extension) of file in which to store the source for the added item. Normally, Link will use the item's name as filename and select an extension based on the current options in the relevant link.

#### Result