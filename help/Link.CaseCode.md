# Link.CaseCode

    names ← {opts} ⎕SE.Link.CaseCode names
     
If case codes is on (default is off), each file name will have a case code (see below). 

If you set up a `getFilename` hook when [creating a Link](Link.Create.md), Link will prompt your hook for a file name whenever a new source file needs
to be created. If case coding is also enabled, the file name should be correctly case coded. The *CaseCode* function is provided to add case coding to any file name. 

See also the inverse function [Link.StripCaseCode](Link.StripCaseCode.md).

### What is a "case code"?
A reverse binary indication of the letter cases in the main part of the name, encoded in octal. For example

`HelloWorld` has the uppercase indication  
`1000010000` which when reversed is  
`0000100001` which is binary for  
<code>           33<sub>10</sub></code> which in octal is  
<code>           41<sub>8</sub></code> so the full name including case code is  
`HelloWorld-41`

#### Arguments

- file name(s) specifying the full path(s) to files or folders within a linked directory

#### Result

- file name(s) with case code