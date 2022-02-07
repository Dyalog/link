# Link.CaseCode

    names ← {options} ⎕SE.Link.CaseCode filenames

The *CaseCode* function adds case coding to any file name. It is intended for use in functions which implement `getFilename` callbacks, which you can set up when you [create a Link](Link.Create.md), to allow your code to generate file names. If case coding is enabled for the repository, the file name should be correctly case coded. For example, if `/tmp` is a currently linked folder:

```apl
      ⎕SE.Link.CaseCode 'c:\tmp\HelloWorld.apln' 'c:\tmp\FOO.aplf'
 c:/tmp/HelloWorld-41.apln  c:/tmp/FOO-7.aplf 
```

### What is a "case code"?
A reverse binary indication of the letter cases in the main part of the name, encoded in octal. For example

`HelloWorld` has the uppercase indication  
`1000010000` which when reversed is  
`0000100001` which is binary for  
<code>        33<sub>10</sub></code> which in octal is  
<code>        41<sub>8</sub></code> so the full name including case code is  
`HelloWorld-41`

#### Arguments
`filenames` is a simple character vector or vector of character vectors containing file names which do not contain case codes. The file names do not need to exist, but they need to reference a currently linked folder.

#### Result

- Case coded file name(s)