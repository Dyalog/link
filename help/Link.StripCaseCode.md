If case codes is on (default is off), each file name will have a [case code](Link.CaseCode.md#what-is-a-case-code). 

If you set up a *BeforeRead* hook when creating a Link, Link will allow your prompt your hook take appropriate action before a file is imported. If the filename may have a case code. The *StripCaseCode* function is provided to remove case coding from any file name.

#### Arguments

- filename

#### Result

- filename without case code