:Namespace Test
⍝ Put the ]link UCMD and FileSystemWatcher through it's paces
⍝ Call Run with a right argument containing a folder name which can be used for the test
⍝ For example:
⍝   Run 'c:\tmp\linktest'

    ⎕IO←1 ⋄ ⎕ML←1

    ∇ r←Run folder;name;foo;ns;nil;ac;bc;tn;goo;old;new;U;link;file;cb;z;zzz;olddd;zoo;goofile;t;m
      
     :If 'Windows'≢7↑⊃'.' ⎕WG 'APLVersion'
        r←'Unable to run tests - Microsoft Windows is required to test the FileSystemWatcher'
        →0
     :EndIf
     
      U←##.Utils
     
      {}⎕SE.UCMD'udebug on'
      ⎕SE.Link.DEBUG←0 ⍝ 1 = Trace, 2 = Stop on entry
     
      :If 0≠⎕NC'⎕SE.Link.Links'
      :AndIf 0≠≢⎕SE.Link.Links
          Log'Please reset all links and try again.'
          Log ⎕SE.UCMD'link'
          →0
      :EndIf
     
      folder←∊1 ⎕NPARTS folder,(0=≢folder)/'/temp/linktest' ⍝ Normalise
      name←2⊃⎕NPARTS folder
     
      ⎕MKDIR folder ⍝ 2 ⎕NDELETE folder
      #.⎕EX name
     
      cb←' -onRead=⎕SE.Link.Test.onRead -onWrite=⎕SE.Link.Test.onWrite'
      ⎕SE.UCMD'link #.',name,' ',folder,cb
      assert'1=≢⎕SE.Link.Links'
      link←⊃⎕SE.Link.Links
      ns←#⍎name
     
      ⍝ Create a monadic function
      (⊂foo←' r←foo x' ' x x')⎕NPUT folder,'/foo.dyalog'
      assert'foo≡ns.⎕NR ''foo'''
      ⍝ Create a niladic / non-explicit function
      (⊂nil←' nil' ' 2+2')⎕NPUT folder,'/nil.dyalog'
      assert'nil≡ns.⎕NR ''nil'''
     
      ⍝ Create sub-folder
      ⎕MKDIR folder,'/sub'
      assert'9.1=ns.⎕NC ⊂''sub'''
     
      ⍝ Put a copy of foo in the folder
      (⊂foo)⎕NPUT folder,'/sub/foo.dyalog'
      assert'foo≡ns.sub.⎕NR ''foo'''
     
      ⍝ Create a class with missing dependency
      (⊂ac←':Class aClass : bClass' ':EndClass')⎕NPUT folder,'/sub/aClass.dyalog'
      assert'9=ns.sub.⎕NC ''aClass'''
      assert'ac≡⎕SRC ns.sub.aClass'
     
      ⍝ Now add the base class
      (⊂bc←':Class bClass' ':EndClass')⎕NPUT folder,'/sub/bClass.dyalog'
      assert'9=ns.sub.⎕NC ''bClass'''
      assert'bc≡⎕SRC ns.sub.bClass'
     
      ⍝ Check that the derived class works
      :Trap 0 ⋄ {}⎕NEW ns.sub.aClass
      :Else ⋄ ⎕←'NB: Unable to instantiate aClass: ',⊃⎕DM
      :EndTrap
     
      ⍝ Rename the sub-folder
      (folder,'/bus')⎕NMOVE folder,'/sub'
      assert'9.1=ns.⎕NC ⊂''bus'''              ⍝ bus is a namespace
      assert'3=ns.bus.⎕NC ''foo'''             ⍝ bus.foo is a function
      :If ~∨/'/bus/foo.dyalog'⍷4⊃U.GetLinkInfo ns.bus 'foo'
          ⎕←'*** NB https://github.com/mkromberg/link/issues/2 still not resolved'
      :EndIf
      assert'0=ns.⎕NC ''sub'''                 ⍝ sub is gone
     
      ⍝ Now copy a file containing a function
      old←U.GetLinkInfo ns'foo'
      (folder,'/foo - copy.dyalog')⎕NCOPY folder,'/foo.dyalog' ⍝ simulate copy/paste
      ⎕DL 1 ⍝ Allow FileSystemWatcher time to react 
      goofile←folder,'/goo.dyalog'
      goofile ⎕NMOVE folder,'/foo - copy.dyalog' ⍝ followed by rename
      ⎕DL 1 ⍝ Allow FileSystemWatcher some time to react
      ⍝ Verify that the old function has NOT become linked to the new file
      assert 'old≡new←U.GetLinkInfo ns''foo'''
     
      ⍝ Now edit the new file so it "accidentally" defines 'zoo'
      tn←goofile ⎕NTIE 0
      'z'⎕NREPLACE tn 5 80 ⍝ (beware UTF-8 encoded file)
      ⎕NUNTIE tn
      ⍝ Validate that this did cause goo to arrive in the workspace
      zoo←' r←zoo x' ' x x'
      assert'zoo≡ns.⎕NR ''zoo'''

      ⍝ Now edit the new file so it finally defines 'goo' 
      tn←goofile ⎕NTIE 0
      'g'⎕NREPLACE tn 5 80 ⍝ (beware UTF-8 encoded file)
      ⎕NUNTIE tn
      ⍝ Validate that this did cause goo to arrive in the workspace
      goo←' r←goo x' ' x x'
      assert'goo≡ns.⎕NR ''goo''' 
      ⍝ Also validate that zoo is now gone
      assert'0=ns.⎕NC ''zoo'''
      
      ⍝ Now simulate changing goo using the editor and verify the file is updated
      ns'goo'⎕SE.Link.Fix' r←goo x' ' r←x x x'
      assert'(ns.⎕NR ''goo'')≡⊃⎕NGET goofile 1' 
      
      ⎕SE.Link.Expunge 'ns.goo' ⍝ Test "expunge"
      assert '0=⎕NEXISTS goofile' 
     
      ⍝ Now test the Notify function - and verify the System Variable setting trick
     
      link.fsw.Object.EnableRaisingEvents←0 ⍝ Disable notifications
      (⊂':Namespace _SV' '##.(⎕IO←0)' ':EndNamespace')⎕NPUT file←folder,'/bus/_SV.dyalog'
      ⎕SE.Link.Notify'created'file
     
      assert'0=ns.bus.⎕IO'
      assert'1=ns.⎕IO'
     
      link.fsw.Object.EnableRaisingEvents←1 ⍝ Re-enable watcher
     
      ⍝ Now test whether exits implement ".charmat" support
      ⍝ First, write vars in the workspace to file'
     
      ns.cm←↑ns.cv←'Line 1' 'Line two'
      ns'cm'⎕SE.Link.Fix ⍬ ⍝ Inform it charmat was edited
      ns'cv'⎕SE.Link.Fix ⍬ ⍝ Ditto for charvec
      assert'ns.cm≡↑⊃⎕NGET (folder,''/cm.charmat'') 1'
      assert'ns.cv≡⊃⎕NGET (folder,''/cv.charvec'') 1'
     
      ⍝ Then verify that modifying the file brings changes back
      (⊂ns.cv←ns.cv,⊂'Line three')⎕NPUT(folder,'/cv.charvec')1
      (⊂↓ns.cm←↑ns.cv)⎕NPUT(folder,'/cm.charmat')1
     
      assert'ns.cm≡↑⊃⎕NGET (folder,''/cm.charmat'') 1'
      assert'ns.cv≡⊃⎕NGET (folder,''/cv.charvec'') 1'
     
      ⍝ Now tear it all down again:
      ⍝ First the sub-folder

      2 ⎕NDELETE folder,'/bus'
      assert'0=⎕NC ''ns.bus'''
     
      ⍝ The variables
      ⎕NDELETE folder,'/cv.charvec'
      ⎕NDELETE folder,'/cm.charmat'
      assert'0 0≡ns.⎕NC 2 2⍴''cmcv'''
     
      ⍝ The the functions, one by one
      ⎕NDELETE folder,'/nil.dyalog'
      assert'0=ns.⎕NC ''nil'''
      ⎕NDELETE folder,'/foo.dyalog'
      assert'0=≢ns.⎕NL -⍳10' ⍝ top level namespace is now empty
     
     EXIT: ⍝ →EXIT to aborted test and clean up
      ⎕SE.Link.DEBUG←0
      ⎕SE.UCMD']link #.',name,' -reset'
      assert'0=≢⎕SE.Link.Links' 
      
      z←⊃¨5176⌶⍬ ⍝ Check all links have been cleared
      :If ∨/m←((≢folder)↑¨z)∊⊂folder  
         ⎕←'*** Links not cleared:'
         ⎕←⍪m/z
      :EndIf
           
      2 ⎕NDELETE folder    ⍝
      assert'9=#.⎕NC name' ⍝ After ]link -reset this should not remove the namespace
      #.⎕EX name
          
      Log'Tests passed OK'
    ∇
   
    ∇ Log x
      ⎕←x ⍝ This might get more sophisticated someday
    ∇

    ∇ assert expr;maxwait;end;timeout
      ⍝ Asynchronous assert: We don't know how quickly the FileSystemWatcher will do something
      end←3000+3⊃⎕AI ⍝ 3s
      timeout←0
     
      :While 0∊⍎expr
          ⎕DL 0.1
      :Until timeout←end<3⊃⎕AI
     
      'assertion failed'⎕SIGNAL timeout/11
    ∇         

   ⍝ Callback functions to implement .charmat & .charvec support

    ∇ r←onRead(type file nsname);⎕TRAP;parts;data;extn
      r←1 ⍝ Carry on, Soldier!
      :If (⊂extn←3⊃parts←⎕NPARTS file)∊'.charmat' '.charvec'
          :Select type
          :Case 'deleted'  
             (⍎nsname).⎕EX 2⊃parts  
             r←0
          :CaseList 'changed' 'renamed' 'created'
              data←(↑⍣(extn≡'.charmat'))⊃⎕NGET file 1
              ⍎nsname,'.',(2⊃parts),'←data'
              r←0 ⍝ We're done
          :EndSelect
      :EndIf
    ∇

    ∇ r←onWrite(ns name oldname nc src file);⎕TRAP;extn
      r←1 ⍝ Do as you wish
     
      :If nc=2 ⍝ A variable
     
          :Select ⎕DR src
     
          :CaseList 80 160 320
              :If 2=⍴⍴src ⋄ src←↓src
              :Else ⋄ →0
              :EndIf
              extn←⊂'.charmat'
     
          :Case 326
              :If (1≠⍴⍴src)∨(10|⎕DR¨src)∨.≠0 ⋄ →0
              :EndIf
              extn←⊂'.charvec'
     
          :EndSelect
     
          (⊂src)⎕NPUT(∊(extn@3)⎕NPARTS file)1
          r←0 ⍝ No further work required
      :EndIf
    ∇

:EndNamespace
