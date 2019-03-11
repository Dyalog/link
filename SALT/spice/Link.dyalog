:Namespace Link ⍝ V 2.03
⍝ 2018 12 17 Adam: Rewrite to thin covers
⍝ 2018 02 01 Adam: Help text
⍝ 2018 02 14 Adam: List -e
⍝ 2019 03 11 Adam: Help text

    ⎕IO←1 ⋄ ⎕ML←1

    ∇ r←List
      ⍝ Name, group, short description and parsing rules
      r←'['
      r,←'{"Name":"Add",         "args":"item",   "Parse":"1 -extension=", "Desc":"Add item to linked namespace"},'
      r,←'{"Name":"Break",       "args":"ns",     "Parse":"1",  "Desc":"Stop namespace from being linked"},'
      r,←'{"Name":"CaseCode",    "args":"file",   "Parse":"1L", "Desc":"Add case code to file name"},'
      r,←'{"Name":"Create",      "args":"ns dir", "Parse":"2L -source=ns dir both -watch=none ns dir both -flatten -casecode -codeextensions -forceextensions -forcefilenames -beforeread= -beforewrite= -typeextensions=","Desc":"Link a namespace to a directory"},'
      r,←'{"Name":"Export",      "args":"ns dir", "Parse":"2L", "Desc":"One-off save"},'
      r,←'{"Name":"Expunge",     "args":"item",   "Parse":"1",  "Desc":"Erase item and associated file"},'
      r,←'{"Name":"GetFileName", "args":"item",   "Parse":"1",  "Desc":"Get name of file linked to item"},'
      r,←'{"Name":"GetItemName", "args":"file",   "Parse":"1L", "Desc":"Get name of item linked to file"},'
      r,←'{"Name":"Import",      "args":"ns dir", "Parse":"2L", "Desc":"One-off load"},'
      r,←'{"Name":"List",        "args":"[ns]",   "Parse":"1S -extended", "Desc":"List link(s) with name count(s)"},'
      r,←'{"Name":"Refresh",     "args":"ns",     "Parse":"1  -source=ns dir both", "Desc":"Resynchronise including items created without editor"},'
      r←⎕JSON']',⍨¯1↓r
      r.Group←⊂'Link'
      r/⍨←×⎕NC'⎕SE.Link'
    ∇

    ∇ r←level Help cmd;info;Means;m;mods;myMods;myModI;myModS;a;modVals;modTxts;argTxts;myArgs;myArgI;myArgss;args;myArgS
      info←{⍵⊃⍨⍵.Name⍳⊢/'.'(≠⊆⊢)cmd}List
     
      m←⍉⍪'' '' ''
      m⍪←'-beforeread' '=<fn>' 'name of function to call before reading a file'
      m⍪←'-beforewrite' '=<fn>' 'name of function to call before writing a file'
      m⍪←'-casecode' '' 'add octal suffixes to preserve capitalisation on systems that ignore case'
      m⍪←'-codeextensions' '=<var>' 'name of vector of file extensions to be considered code'
      m⍪←'-extension' '=<ext>' 'file extension of created file if different from default for the name class'
      m⍪←'-flatten' '' 'merge items from all subdirectories into target directory'
      m⍪←'-forceextensions' '' 'rename existing files so they adhere to the type specific file extensions'
      m⍪←'-forcefilenames' '' 'rename existing files so their names match their contents'
      m⍪←'-source' '={ns|dir|both}' 'which source is authoritative if both are populated'
      m⍪←'-typeextensions' '=<var>' 'name of two-column matrix with name classes and extensions'
      m⍪←'-watch' '={none|ns|dir|both}' 'which source to track for changes so the other can be synchronised'
      (mods modVals modTxts)←↓⍉m
      myMods←'-\w+'⎕S'&'⊢info.Parse
      myModI←⊂mods⍳myMods
      myModS←∊myMods{' [',⍺,⍵,']'}¨myModI⌷modVals
     
      a←⍉⍪'' ''
      a⍪←'ns' 'target namespace of link'
      a⍪←'dir' 'target directory of link'
      a⍪←'file' 'filename where item source is stored'
      a⍪←'item' 'name of APL item to process'
      (args argTxts)←↓⍉a
      myArgs←'-\w+'⎕S'&'⊢info.args
      myArgI←⊂args⍳myArgs
      myArgS←∊'(\[?)(\w+)(\]?)'⎕S' \1<\2>\3'⊢info.args
     
      r←⊂info.Desc
      r,←⊂'    ]LINK.',cmd,myArgS,myModS
      r,←⊂''
      :If 0=level
          r,←⊂']LINK.',cmd,' -??  ⍝ for argument and modifier details'
      :Else
          r,←⊂''
          r,←' +$'⎕R''↓¯1⌽⍕myArgI⌷args,⍪argTxts
          r,←⊂''
          r,←' +$'⎕R''↓¯1⌽⍕myModI⌷modTxts,⍨⍪mods,¨modVals
          r,←⊂''
      :EndIf
      r/⍨←~'' ''⍷r
      r,←⊂']FILE.Open https://github.com/Dyalog/link/wiki/Link.',cmd,'  ⍝ for full documentation'
    ∇

    ∇ r←Run(cmd args);opts;name;lc;names;L;ârgs;ôpts
      L←819⌶
      ⍝ propagate lowercase modifiers to dromedaryCase options' namespace members
      :If 1=1 2⊃⎕SE.Link.⎕AT cmd
          ôpts←{⍵ ⋄ ⍺⍺}
      :Else
          'opts'⎕NS ⍬
          names←'watch' 'beforeRead' 'beforeWrite' 'caseCode' 'codeExtensions' 'extension' 'flatten' 'forceExtensions' 'forceFileNames' 'source' 'typeExtensions' 'extended'
          :For name :In names
              lc←L name
              :If ×args.⎕NC lc
              :AndIf 0≢args⍎lc
                  name opts.{⍎⍺,'←⍵'}##.THIS⍎⍣(∨/'Extensions'⍷name)⍎'args.',lc
              :EndIf
          :EndFor
          ôpts←,opts
      :EndIf
      ârgs←args.Arguments
     ⍝ Simulate calling directly from the original ns
      :With ##.THIS  ⍝ We know THIS has been set for us
          r←(⊃ôpts)(⎕SE.Link⍎cmd)ârgs
      :EndWith
    ∇

:EndNamespace
