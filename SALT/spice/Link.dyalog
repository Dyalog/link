:Namespace Link ⍝ V 2.09
⍝ 2018 12 17 Adam: Rewrite to thin covers
⍝ 2018 02 01 Adam: Help text
⍝ 2018 02 14 Adam: List -e
⍝ 2019 03 14 Adam: help text
⍝ 2019 05 07 Adam: disable ]CaseCode
⍝ 2019 05 31 MKrom: Fix ⎕ML sensitivity
⍝ 2019 06 19 Adam: Avoid special-cased vars in caller
⍝ 2020 05 14 Nic: updated to link v2.1 API
⍝ 2020 06 08 Adam: Remove Version ucmd (use ⎕SE.Link.Version)

    ⎕IO←1 ⋄ ⎕ML←1

    :Section Globals for Run
      ⍝ OPTS←opts
      ⍝ ARGS←args.Arguments
      ⍝ CMD←cmd
      ⍝ RSLT←...
    :EndSection

    ∇ r←List
      ⍝ Name, group, short description and parsing rules
      r←'['
      r,←'{"Name":"Add",         "args":"item",    "Parse":"1", "Desc":"Associate item in linked namespace with new file/directory in corresponding directory"},'
      r,←'{"Name":"Break",       "args":"[ns1]",     "Parse":"1S -all -exact",  "Desc":"Break link between namespace and corresponding directory"},'
      ⍝r,←'{"Name":"CaseCode",    "args":"file1",   "Parse":"1L", "Desc":"Append filename with numeric encoding of capitalisation"},'
      r,←'{"Name":"Create",      "args":"ns dir",  "Parse":"2L -source=ns dir both -watch=none ns dir both -casecode -forceextensions -forcefilenames  -flatten -beforeread= -beforewrite= -getfilename= -codeextensions= -typeextensions= -fastload","Desc":"Link a namespace with a directory (create one or both if absent)"},'
      r,←'{"Name":"Export",      "args":"ns0 dir2","Parse":"2L", "Desc":"Export a namespace to a directory (create the directory if absent); does not create a link"},'
      r,←'{"Name":"Expunge",     "args":"item",    "Parse":"1",  "Desc":"Erase item and associated file"},'
      r,←'{"Name":"GetFileName", "args":"item",    "Parse":"1",  "Desc":"Return name of file associated with item"},'
      r,←'{"Name":"GetItemName", "args":"file",    "Parse":"1L", "Desc":"Return name of item associated with file"},'
      r,←'{"Name":"Import",      "args":"ns2 dir0","Parse":"2L -fastload", "Desc":"Import a namespace from a directory (create the namespace if absent); does not create a link"},'
      r,←'{"Name":"List",        "args":"[ns1]",   "Parse":"1S -extended", "Desc":"List active namespace-directory links"},'
      r,←'{"Name":"Refresh",     "args":"ns1",     "Parse":"1  -source=ns dir both", "Desc":"Synchronise namespace-directory content"},'
      r←⎕JSON']',⍨¯1↓r
      r.Group←⊂'Link'
      r/⍨←×⎕NC'⎕SE.Link'
    ∇

    ∇ r←level Help cmd;info;Means;m;mods;myMods;myModI;myModS;a;modVals;modTxts;argTxts;myArgs;myArgI;myArgss;args;myArgS
      info←{⍵⊃⍨⍵.Name⍳⊢/'.'(≠⊆⊢)cmd}List
     
      m←⍉⍪'' '' ''
      m⍪←'-all' '' 'break all links (in all children of # and ⎕SE)'
      m⍪←'-beforeread' '=<fn>' 'name of function to call before reading a file'
      m⍪←'-beforewrite' '=<fn>' 'name of function to call before writing a file'
      m⍪←'-casecode' '' 'add octal suffixes to preserve capitalisation on systems that ignore case'
      m⍪←'-codeextensions' '=<var>' 'name of vector of file extensions to be considered code'
      m⍪←'-exact' '' 'break only the argument namespace, and not its children if they have their own links'
      m⍪←'-extended' '' 'include additional properties for each link'
      m⍪←'-extension' '=<ext>' 'file extension of created file if different from link''s default for the nameclass'
      m⍪←'-fastload' '' 'reduce the load time by not inspecting source to detect name clashes'
      m⍪←'-flatten' '' 'merge items from all subdirectories into target directory'
      m⍪←'-forceextensions' '' 'rename existing files so they adhere to the type specific file extensions'
      m⍪←'-forcefilenames' '' 'rename existing files so their names match their contents'
      m⍪←'-getfilename' '=<fn>' 'name of function to call to specify a custom file name for a given APL item'
      m⍪←'-source' '={ns|dir|both}' 'which source is authoritative if both are populated'
      m⍪←'-typeextensions' '=<var>' 'name of two-column matrix with name classes and extensions'
      m⍪←'-watch' '={none|ns|dir|both}' 'which source to track for changes so the other can be synchronised'
      (mods modVals modTxts)←↓⍉m
      myMods←'-\w+'⎕S'&'⊢info.Parse
      myModI←⊂mods⍳myMods
      myModS←∊myMods{' [',⍺,⍵,']'}¨myModI⌷modVals
     
      a←⍉⍪'' ''
      a⍪←'ns' 'namespace to be linked'
      a⍪←'ns0' 'source namespace'
      a⍪←'ns1' 'linked namespace'
      a⍪←'ns2' 'target namespace'
      a⍪←'dir' 'directory to be linked'
      a⍪←'dir0' 'source directory'
      a⍪←'dir2' 'target directory'
      a⍪←'file' 'name of file where item source is stored'
      a⍪←'file1' 'filename to be appended with octal representation of reverse binary encoding of capitalisation'
      a⍪←'item' 'name of APL item'
      (args argTxts)←↓⍉a
      myArgs←'\w+'⎕S'&'⊢info.args
      myArgI←⊂args⍳myArgs
      myArgS←∊'(\[?)(\pL+)\d?(\]?)'⎕S' \1<\2>\3'⊢info.args
     
      r←⊂info.Desc
      r,←⊂'    ]LINK.',cmd,myArgS,myModS
      r,←⊂''
      :If 0=level
          r,←⊂']LINK.',cmd,' -??  ⍝ for argument and modifier details'
      :Else
          r,←⊂''
          r,←'^  (\pL+)\d?' ' +$'⎕R'  <\1>' ''↓¯1⌽⍕myArgI⌷args,⍪argTxts
          r,←⊂''
          r,←' +$'⎕R''↓¯1⌽⍕myModI⌷modTxts,⍨⍪mods,¨modVals
          r,←⊂''
      :EndIf
      r/⍨←~'' ''⍷r
      r,←⊂']FILE.Open https://github.com/Dyalog/link/tree/master/help/Link.',cmd,'.md  ⍝ for full documentation'
    ∇

    ∇ r←Run(cmd args);opts;name;lc;names;L
      L←819⌶
      ⍝ propagate lowercase modifiers to dromedaryCase options' namespace members
      :Select |1 2⊃⎕SE.Link.⎕AT cmd
      :Case 0  ⍝ niladic
         opts←⊃  ⍝ hack : rslt← ⊃ (⍎Niladic)args
      :Case 1  ⍝ monadic
          opts←⊢
      :Case 2  ⍝ ambivalent or dyadic
          'opts'⎕NS ⍬
          names←'all'  'beforeread'  'beforewrite'  'casecode'  'codeextensions'  'exact'  'extended'  'extension'  'fastload'  'flatten'  'forceextensions'  'forcefilenames'  'getfilename'  'source'  'typeextensions'  'watch' 
          :For name :In names
              lc←L name
              :If ×args.⎕NC lc
              :AndIf 0≢args⍎lc
                  name opts.{⍎⍺,'←⍵'}##.THIS⍎⍣(∨/'Extensions'⍷name)⍎'args.',lc
              :EndIf
          :EndFor
      :EndSelect
     ⍝ Set up GLOBALS in this ucmd ns:
      OPTS←opts
      ARGS←args.Arguments
      CMD←cmd
     ⍝ Simulate calling directly from the original ns
      :With ##.THIS  ⍝ We know THIS has been set for us
          ⎕SE.SALTUtils.c.Link.(RSLT←OPTS(⎕SE.Link⍎CMD)ARGS) ⍝ dot our way home
      :EndWith
      r←RSLT ⍝ fetch result from global
    ∇

:EndNamespace
