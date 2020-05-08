# Link.CaseCode

If case codes is on (default is off), each file name will have a case code (see below). 

If you set up a *BeforeWrite* hook when creating a Link, Link will prompt your hook for a file name whenever a new source file needs
to be created. If case coding is also enabled, the file name should be correctly case coded. The *CaseCode* function is provided to add case coding to any file name. 

### What is a "case code"?
A reverse binary indication of the letter cases in the main part of the name, encoded in octal. For example

`HelloWorld` has the uppercase indication  
`1000010000` which when reversed is  
`0000100001` which is binary for  
<code>           33<sub>10</sub></code> which in octal is  
<code>           41<sub>8</sub></code> so the full name including case code is  
`HelloWorld-41`

#### Arguments

- filename

#### Result

- filename with case code