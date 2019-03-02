:Namespace Link ⍝ V 2.02
⍝ 2018 12 17 Adam: Rewrite to thin covers
⍝ 2019 02 01 Adam: Help text
⍝ 2019 02 18 Adam: ]List -extended

    ⎕IO←1 ⋄ ⎕ML←1

    ∇ r←List
      ⍝ Name, group, short description and parsing rules
      r←'['
      r,←'{"Name":"Add",         "args":"item",   "Parse":"1 -extension=", "Desc":"Add item to linked namespace"},'
      r,←'{"Name":"Break",       "args":"ns",     "Parse":"1",  "Desc":"Stop namespace from being linked"},'
      r,←'{"Name":"CaseCode",    "args":"file",   "Parse":"1L", "Desc":"Add case code to file name"},'
      r,←'{"Name":"Create",      "args":"ns dir", "Parse":"2L -source=ns dir both -watch=none ns dir both -flatten -casecode -codeextensions -forceextensions -forcefilenames -beforeread= -beforewrite= -typeextensions=","Desc":"Link a namespace to a directory"},'
      r,←'{"Name":"Export",      "args":"ns dir", "Parse":"2L", "Desc":"One-off save"},'
      r,←'{"Name":"Expunge",     "args":"item",   "Parse":"1",  "Desc":"One-off save"},'
      r,←'{"Name":"GetFileName", "args":"item",   "Parse":"1",  "Desc":"Get name of file linked to item"},'
      r,←'{"Name":"GetItemName", "args":"file",   "Parse":"1L", "Desc":"Get name of item linked to file"},'
      r,←'{"Name":"Import",      "args":"ns dir", "Parse":"2L", "Desc":"One-off load"},'
      r,←'{"Name":"List",        "args":"[ns]",   "Parse":"1S -extended", "Desc":"List link(s) with name count(s)"},'
      r,←'{"Name":"Refresh",     "args":"ns",     "Parse":"1  -source=ns dir both", "Desc":"Resynchronise including items created without editor"},'
      r←⎕JSON']',⍨¯1↓r
      r.Group←⊂'Link'
      r/⍨←×⎕NC'⎕SE.Link'
    ∇

    ∇ r←level Help cmd;args;list;info;Means
      list←List
      info←list⊃⍨list.Name⍳⊢/'.'(≠⊆⊢)cmd
      Means←{
          term←⍺~' '
          has←∨/term⍷info⍎'args' 'Parse'⊃⍨1+'-'∊⍺
          has/,/'  '∘,¨⍺ ⍵
      }
      r←⊂info.Desc
      r,←⊂'    ]LINK.',cmd,' ',info.args
      r,←⊂''
      :If 0=level
          r,←⊂']LINK.',cmd,' -??  ⍝ for argument and modifier details'
      :Else
          r,←⊂''
          r,←'ns  'Means'target namespace of link'
          r,←'dir 'Means'target directory of link'
          r,←'file'Means'filename where item source is stored'
          r,←'item'Means'name of APL item to process'
          r,←⊂''
          r,←'-beforeread     'Means'name of function to call before reading a file'
          r,←'-beforewrite    'Means'name of function to call before writing a file'
          r,←'-casecode       'Means'add octal suffixes to preserve capitalisation on systems that ignore case'
          r,←'-codeextensions 'Means'name of vector of file extensions to be considered code'
          r,←'-extension      'Means'file extension of created file if different from default for the name class'
          r,←'-extended       'Means'also show various option settings'
          r,←'-flatten        'Means'merge items from all subdirectories into target directory'
          r,←'-forceextensions'Means'rename existing files so they adhere to the type specific file extensions'
          r,←'-forcefilenames 'Means'rename existing files so their names match their contents'
          r,←'-source         'Means'which source is authoritative ("ns" or "dir" or "both") if both are populated'
          r,←'-typeextensions 'Means'name of two-column matrix with name classes and extensions'
          r,←⊂''
      :EndIf
      r/⍨←~'' ''⍷r
      r,←⊂']FILE.Open https://github.com/abrudz/Link/wiki/Link.',cmd,'  ⍝ for full documentation'
    ∇

    ∇ r←Run(cmd args);opts;name;lc;names;L;ârgs;ôpts
      L←819⌶
      ⍝ propagate lowercase modifiers to dromedaryCase options' namespace members
      :If 1=1 2⊃⎕SE.Link.⎕AT cmd
          ôpts←{⍵ ⋄ ⍺⍺}
      :Else
          'opts'⎕NS ⍬
          names←'watch' 'beforeRead' 'beforeWrite' 'caseCode' 'codeExtensions' 'extension' 'flatten' 'forceExtensions' 'forceFileNames' 'source' 'typeExtensions'
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
