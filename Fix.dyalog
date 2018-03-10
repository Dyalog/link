 {linked}←where Fix src;link;nss;files;file;src;nc;nosrc;fsw;old;ns;name
⍝ Fix a function/operator or script, preserving any existing source files
⍝   Used internally by EditorFix "afterfix" processing
⍝   May be called by other tools providing the source in ⎕NR/⎕SRC format on the right
⍝   One day, the left argument of (ns name) may be inferred, for now it must be provided

⍝ Returns 1 if a link was found for the name, else 0
⍝   NB: if 0 is returned, no ⎕FX/⎕FIX was done

 nosrc←0=≢src
 (ns name)←where
 ns←⍬⍴ns

 (linked link)←0 ⍬

 :If 0≠⎕NC'⎕SE.Link.Links'
 :AndIf 0≠≢⎕SE.Link.Links
     nss←⍎¨⎕SE.Link.Links.ns
     :Repeat
         :If linked←ns∊nss
             link←(nss⍳ns)⊃⎕SE.Link.Links
         :Else
             ns←ns.##
         :EndIf
     :Until linked∨ns∊# ⎕SE
 :EndIf

 :If linked
     :If 0<≢file←4⊃5179(ns.⌶)name         ⍝ Already saved in a file

     :ElseIf ~link.flatten                ⍝ Not flattened

         file←(≢link.ns)↓⍕ns              ⍝ Add sub.namespace structure
         ((file='.')/file)←'/'            ⍝ Convert dots to /
         file←link.dir,file               ⍝ Add link directory
         file,←'/',name,link.extn         ⍝ And the object name

     :Else                                ⍝ New name in "flattened" link
         :If 3=link.⎕NC'onCreate'         ⍝ User exit to determine file name?
             →(0=≢file←(link⍎onCreate)ns name)⍴0 ⍝ Return file name or '' to abort
         :Else
             ⎕←'Fix: unable to determine file name for "',name'"'
                          ⍝ /// could use folder browser under Windows
         :EndIf
     :EndIf

     :If nosrc                       ⍝ Source not provided - find it
         :Select nc←⍬⍴ns.⎕NC name
         :CaseList 3 4
             src←ns.⎕NR name
         :Case 9
             src←⎕SRC ns⍎name
         :Else
             ⎕←'AfterFix: Unable to file object of class ',(⍕nc) ⋄ →0
         :EndSelect
     :EndIf

     :If nosrc∧3=link.⎕NC'onWrite'
         src←(link⍎onWrite)ns name src file
     :EndIf

     :Trap 0
         :If fsw←0≠⎕NC⊂'link.fsw.Object.EnableRaisingEvents'
             old←link.fsw.Object.EnableRaisingEvents
             link.fsw.Object.EnableRaisingEvents←0
         :EndIf
         3 ⎕MKDIR 1⊃⎕NPARTS file ⍝ make sure folder is there
         (⊂src)⎕NPUT file 1
     :Else
         old←0
         ⎕←'AfterFix: Unable to write "',name,'" to file ',file
         ⎕←'     '⎕DMX
     :EndTrap
     :If fsw ⋄ link.fsw.Object.EnableRaisingEvents←old ⋄ :EndIf

     :Trap 0
         2 ns.⎕FIX'file://',file
     :Else
         ⎕←'AfterFix: Unable to re-fix "',name,'" from file ',file
         ⎕←'     '⎕DMX
     :EndTrap
 :EndIf
