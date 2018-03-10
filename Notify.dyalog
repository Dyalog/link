 {r}←Notify args;type;path;oldpath;linked;link;i;folder;name;extn;U;nsname;ns;effect;z;affected;newname;oldname;resp;dispPath;dispNs;cap;text;⎕TRAP
⍝ Notify Link system that an external file has changed
⍝ Usually called by FileSystemWatcher

 :If DEBUG=2
     ⎕←args
     ⎕TRAP←0 'S' ⋄ ∘∘∘
 :EndIf

 r←⍬
 U←Utils

 (type path oldpath)←{⍵,(≢⍵)↓'' '' ''},⊆args
 (path oldpath)←U.Normalise¨path oldpath

 linked←{0::⍬ ⋄ Utils.Normalise¨⎕SE.Link.Links.dir}⍬
 →((≢linked)<i←1⍳⍨linked≡¨(≢¨linked)↑¨⊂path)⍴0 ⍝ not linked => done
 link←i⊃⎕SE.Link.Links

 (folder name extn)←⎕NPARTS path
 folder←¯1↓folder ⍝ drop trailing /

 nsname←(1+≢link.dir)↓folder
 ((nsname='/')/nsname)←'.'
 nsname←link.ns,(~link.flatten)/((0≠≢nsname)/'.'),nsname ⍝ target namespace

 :If 3=⎕NC link.onRead ⍝ user exit defined?
     :Trap 0
         →((link⍎link.onRead)type path nsname)↓0 ⍝ return 1 to continue else 0
         :If ~(type≡'deleted')∨(U.IsDir path)∨extn≡link.extn
             Log'Ignoring due to extension: ',type,' of ',path
             →0
         :EndIf
     :Else
         ⎕←'*** onRead callback ',link.onRead,' failed: ',⎕DMX.EM
         ∘∘∘
     :EndTrap
 :EndIf

 :If 0=≢ns←U.GetRefTo nsname ⍝ We're going to need a ref to it
     Log'Unable to create namespace ',nsname
     →0 ⍝ might as well give up now
 :EndIf

 effect←0

 :Select type

 :Case 'created'               ⍝ A new file
     effect←0                  ⍝ may not have an effect on existing objects
     :If 0≠≢z←U.GetName path     ⍝ try to extract the name
         name←z
     :EndIf
     :If 0≠≢z←4⊃U.GetLinkInfo ns name  ⍝ Redefines existing object with a source file
     :AndIf ⎕NEXISTS z       ⍝ ... and that file exists
         affected←(⍕ns),'.',name
         Log'(created): ignoring new file ',path
         Log'           attempts to redefine ',affected,' which is linked to ',z
         →0
     :EndIf

 :Case 'changed'               ⍝ Update to existing file?
     :If 0≠≢z←4⊃U.GetLinkInfo ns name       ⍝ name already linked
     :AndIf name≡U.GetName path            ⍝ name matches file contents
     :AndIf (U.Normalise path)≡U.Normalise 4⊃z  ⍝ to the same file name
         effect←1 ⋄ affected←(⍕ns),name
         :If (7⊃z)≡U.GetCheckSum path
             Log'(change) ignored, checksum unchanged: ',path
             →0
         :Else
             Log'(change): ',affected,' updated in ',path
         :EndIf    ⍝ ... but the file did not change

     :Else ⍝ change to file with no current link	
         :If U.IsDir path
             Log'(changed) ignored "change" to directory: ',path
             →0
         :EndIf

         :If name≢newname←U.GetName path             ⍝ repeated in create
         :AndIf 0≠≢⊃z←U.GetLinkInfo ns newname       ⍝ name inside is already linked
             affected←(⍕ns),'.',name
             Log'(created): ignoring changed file ',path
             Log'           attempts to redefine ',affected,' which is linked to ',4⊃z
             →0
         :EndIf

         :If 0≠≢z←U.FindLinkInfo path                ⍝ Try to find an "affected" object
             effect←1 ⋄ affected←2⊃z
             Log'(changed): ',affected,' was previously linked to ',path
         :ElseIf 0≠≢newname
             effect←1 ⋄ affected←(⍕ns),'.',newname   ⍝ So just accept it
             Log'(changed): fixing ',affected,' from ',path
         :Else
             Log'(changed): No APL object found in ',path
             →0
         :EndIf

     :EndIf

 :Case 'renamed'
     :If U.IsDir path                                ⍝ of a folder?
     :AndIf 0=ns.⎕NC name                          ⍝ and new name is free and valid
         :If 9=ns.⎕NC oldname←∊1↓⎕NPARTS oldpath   ⍝ and old name looks like an existing namespace
             ns⍎name,'←',oldname                   ⍝ copy it
             (⍎(⍕ns),'.',name).⎕DF(⍕ns),'.',name   ⍝ give it a nice name
             ns.⎕EX oldname                        ⍝ expunge old
             Log'Simple NS rename ',oldname,' → ',name
         :Else                                    ⍝ no old ns
             Log'Simple NS rename ',oldname,' (not found) → ',name
         :EndIf
         →0
     :EndIf

     oldname←2⊃⎕NPARTS oldpath                    ⍝ rename - not of a folder
     :If 0≠≢⊃z←U.GetLinkInfo ns oldname           ⍝ old name *is* linked to this file
         effect←1 ⋄ affected←(⍕ns),name
         Log'(rename) ',affected,' → ',name

     :Else ⍝ old name not linked to old file
         :If 0≠≢z←U.FindLinkInfo path
             affected←2⊃z
             Log'(rename): ',affected,' was previously linked to ',path
         :Else
             Log'(rename): Unable to find changed object corresponding to ',path
         :EndIf
     :EndIf

 :Case 'deleted'
     :If 0≠≢U.GetLinkInfo ns name   ⍝ existing name is linked to this file
     :OrIf 9.1=ns.⎕NC⊂name          ⍝ it identifies a namespace
         effect←1 ⋄ affected←(⍕ns),'.',name
         Log'(delete) of ',affected
     :ElseIf 0≠≢z←U.FindLinkInfo path
         effect←1 ⋄ affected←2⊃z
         Log'(delete): ',affected,' was previously linked to ',path
     :Else
         Log'(delete): Unable to find changed object corresponding to ',path
     :EndIf

 :EndSelect

 :If effect∨'created'≡type

     :If ~resp←link.quiet

         dispPath←U.WinSlash Strip path
         dispNs←U.WinSlash⍕ns ⍝ / → \ on Windows
         cap←'Namespace-Directory Synchroniser'

         :If type≡'renamed'
             text←⊂'"',(U.WinSlash oldpath),'" has been renamed to "',(U.WinSlash path),'". Would you like to synchronise?'
         :Else
             text←⊂'"',(U.WinSlash path),'" has been ',type,'. Would you like to synchronise?'
         :EndIf

         :Select type

         :Case 'created'
             text,←''('If you choose Yes, the contents of the file will be established in "',dispNs,'".')
             text,←''('If you choose No, "',dispNs,'" will be out of sync with "',dispPath,'".')
         :Case 'changed'
             text,←''('If you choose Yes, "',affected,'" will be updated.')
             text,←''('If you choose No, "',dispNs,'" will be out of sync with "',dispPath,'".')
         :Case 'renamed'
             text,←''('If you choose Yes, "',affected,'" will be re-mapped.')
             text,←''('If you choose No, "',dispNs,'" will be mapped to a file which may no longer exist.')
         :Case 'deleted'
             text,←''('If you choose Yes, "',affected,'" will be DELETED!')
             text,←''('If you choose No, "',dispNs,'" will contain items that are not on in the "',dispPath,'".')
         :EndSelect

         resp←⎕SE.SALTUtils.msgBox cap text'Query'
     :EndIf

     :If 1=resp
         :If (⊂type)∊'renamed' 'deleted'
             ⎕EX affected
         :EndIf

         :If type≢'deleted'
             :Trap 0
                 :If U.IsDir path
                     name ns.⎕NS''   ⍝ create namespace
                 :Else               ⍝ file
                     2 ns.⎕FIX'file://',path
                 :EndIf
             :Case 22
                 ⎕←'FileSystemWatcher: ',type,' reported to non-existant file ',path
             :Else
                 ⎕←'Unable to fix file ',path
                 ⎕←'   '⎕DMX
             :EndTrap
         :EndIf
     :EndIf
 :EndIf
