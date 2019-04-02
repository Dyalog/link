:Namespace Test
⍝ Put the Link system and FileSystemWatcher through it's paces
⍝ Call Run with a right argument containing a folder name which can be used for the test
⍝ For example:
⍝   Run 'c:\tmp\linktest'

    ⎕IO←1 ⋄ ⎕ML←1

    ∇ r←{test_filter} Run folder;start;pause_tests;tests;z;test
     ⍝ Run all the Link Tests. If no folder name provided, default to /temp/linktest
      
      tests←{((5↑¨⍵)∊⊂'test_')⌿⍵}'t' ⎕nl ¯3 ⍝ by default: run all tests 
      pause_tests←0                             ⍝ no manual testing

      :If 0≠⎕NC 'test_filter'
          pause_tests←(⊂'pause')∊test_filter
          tests←(∨⌿1∊¨test_filter ∘.⍷ tests)/tests
      :EndIf
     
      →(0=≢folder←Setup folder)⍴0

      start←⎕AI[3]

      :For test :In tests
         z←(⍎test) folder
      :EndFor
     
      r←(⍕≢tests),' test[s] passed OK in ',(1⍕1000÷⍨⎕AI[3]-start),' seconds under ',⍕'.'⎕WG'APLVersion'
    ∇

    ∇ r←test_flattened folder;name;main;dup;opts;ns;goofile;dupfile;foo;foofile;z
     ⍝ Test the flattened scenario
     
      r←0
      #.⎕EX name←2⊃⎕NPARTS folder
     
      3 ⎕MKDIR folder
      ⎕MKDIR folder,'/app'
      ⎕MKDIR folder,'/utils'
     
      (⊂main←' r←main' 'r←dup 2')⎕NPUT folder,'/app/main.aplf'        ⍝ One "application" function
      (⊂dup←' r←dup x' 'r←x x')⎕NPUT dupfile←folder,'/utils/dup.aplf' ⍝ One "utility" function
     
      opts←⎕NS''
      opts.(flatten source)←1 'dir'
      opts.beforeWrite←'⎕SE.Link.Test.onFlatWrite'
      z←opts ⎕SE.Link.Create('#.',name)folder
     
      ns←#⍎name
     
      assert'''dup'' ''main'' ≡ ns.⎕NL ¯3'           ⍝ Validate both fns are in root namespace
      assert'2 2≡ns.main'                            ⍝ Check that main function works
     
      dup,←⊂' ⍝ Modified dup'
      ns'dup'⎕SE.Link.Fix dup                        ⍝ Redefine existing function dup
      assert'dup≡⊃⎕NGET dupfile 1'
     
      goofile←folder,'/app/goo.aplf'
      FLAT_TARGET←'app' ⍝ simulated user input to onFlatWrite: declare target folder for new function
     
      ns'goo'⎕SE.Link.Fix' r←goo x' ' r←x x x'       ⍝ Add a new function
      assert'(ns.⎕NR ''goo'')≡⊃⎕NGET goofile 1'
      ns'foo' 'goo'⎕SE.Link.Fix foo←' r←foo x' ' r←x x x' ⍝ Simulate RENAME of existing foo > goo

      foofile←∊((⊂'foo')@2)⎕NPARTS goofile           ⍝ Expected name of the new file
      assert 'foo≡⊃⎕NGET foofile 1'                  ⍝ Validate file has the right contents 
      
      PauseTest folder   

      ⎕NDELETE foofile  
      assert '''dup'' ''goo'' ''main''≡ns.⎕nl -3'
     
      CleanUp folder name
    ∇

    ∇ r←onFlatWrite args;⎕TRAP;ns;name;oldname;nc;src;file;link;nameq;ext;z
    ⍝ Callback functions to implement determining target folder for flattened link
      (ns name oldname nc src file link nameq)←8↑args
     
      r←1           ⍝ Link should proceed and complete the operation
      →(0=nameq)⍴0  ⍝ We only need to respond to requests for a file name
     
      :If name≢oldname ⍝ copy / rename of an existing function
          r←4⊃5179 ns.⌶ name           ⍝ ask for existing link info for oldname
      :AndIf 0≠≢r                      ⍝ we could find info for oldname
          r←∊((⊂name)@2) ⎕NPARTS r     ⍝ just substitute the name
      :Else            ⍝ a new function
          ⍝ A real application exit might prompt the user to pick a folder
          ⍝   in the QA example we look to a global variable
          ext←⎕SE.Link.TypeExtension link nc        ⍝ Ask for correct extension for the name class
          r←link.dir,'/',FLAT_TARGET,'/',name,'.',ext  ⍝ Return the file name
      :EndIf
    ∇

    ∇ r←test_basic folder;name;foo;ns;nil;ac;bc;tn;goo;old;new;link;file;cb;z;zzz;olddd;zoo;goofile;t;m;cv;cm;opts;start;otfile;value
      r←0
      #.⎕EX name←2⊃⎕NPARTS folder
     
      opts←⎕NS''
      opts.beforeRead←'⎕SE.Link.Test.onBasicRead'
      opts.beforeWrite←'⎕SE.Link.Test.onBasicWrite'
      opts.customExtensions←'charmat' 'charvec'
      z←opts ⎕SE.Link.Create('#.',name)folder
     
      assert'1=≢⎕SE.Link.Links'
      link←⊃⎕SE.Link.Links
      ns←#⍎name
     
      ⍝ Create a monadic function
      (⊂foo←' r←foo x' ' x x')⎕NPUT folder,'/foo.dyalog'
      assert'foo≡ns.⎕NR ''foo'''
      ⍝ Create a niladic / non-explicit function
      (⊂nil←' nil' ' 2+2')⎕NPUT folder,'/nil.dyalog'
      assert'nil≡ns.⎕NR ''nil'''    
      
      ⍝ Create an array       
      (⊂'[''one'' 1' '''two'' 2]') ⎕NPUT folder,'/one2.apla' 
      assert '(2 2⍴''one'' 1 ''two'' 2)≡ns.one2'
      
      ⍝ Rename the array
      otfile←folder,'/onetwo.apla'
      ⎕NUNTIE otfile ⎕NRENAME tn←(folder,'/one2.apla') ⎕NTIE 0
      assert '(2 2⍴''one'' 1 ''two'' 2)≡ns.onetwo' 
      assert '0=⎕NC ''ns.one2'''

      ⍝ Update the array       
      (⊂'[''one'' 1' '''two'' 2' '''three'' 3]' ) ⎕NPUT otfile 1
      assert '(3 2⍴''one'' 1 ''two'' 2 ''three'' 3)≡ns.onetwo' 
      
      ⍝ Update file using Link.Fix
      ns.onetwo←⌽ns.onetwo
      ns'onetwo'⎕SE.Link.Fix ''
      assert 'ns.onetwo≡##.U.Deserialise ⊃⎕NGET otfile 1'

      ⍝ Create sub-folder
      ⎕MKDIR folder,'/sub'
      assert'9.1=ns.⎕NC ⊂''sub'''

      ⍝ Move array to sub-folder
      value←ns.onetwo  
      ⎕NUNTIE (new←folder,'/sub/one2.apla') ⎕NRENAME tn←otfile ⎕NTIE 0
      assert 'value≡ns.sub.one2'

      ⍝ Erase the array       
      ⎕NDELETE new
      assert '0=⎕NC ''ns.sub.one2'''     
     
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
      assert'∨/''/bus/foo.dyalog''⍷4⊃ns.bus ##.U.GetLinkInfo''foo'''
      assert'0=ns.⎕NC ''sub'''                 ⍝ sub is gone
     
      ⍝ Now copy a file containing a function
      old←ns ##.U.GetLinkInfo'foo'
      (folder,'/foo - copy.dyalog')⎕NCOPY folder,'/foo.dyalog' ⍝ simulate copy/paste
      ⎕DL 1 ⍝ Allow FileSystemWatcher time to react
      goofile←folder,'/goo.dyalog'
      goofile ⎕NMOVE folder,'/foo - copy.dyalog' ⍝ followed by rename
      ⎕DL 1 ⍝ Allow FileSystemWatcher some time to react
      ⍝ Verify that the old function has NOT become linked to the new file
      assert'old≡new←ns ##.U.GetLinkInfo ''foo'''
     
      ⍝ Now edit the new file so it "accidentally" defines 'zoo'
      tn←goofile ⎕NTIE 0
      'z'⎕NREPLACE tn 5,⎕DR'' ⍝ (beware UTF-8 encoded file)
      ⎕NUNTIE tn
      ⍝ Validate that this did cause zoo to arrive in the workspace
      zoo←' r←zoo x' ' x x'
      assert'zoo≡ns.⎕NR ''zoo'''
     
      ⍝ Now edit the new file so it finally defines 'goo'
      tn←goofile ⎕NTIE 0
      'g'⎕NREPLACE tn 5,⎕DR'' ⍝ (beware UTF-8 encoded file)
      ⎕NUNTIE tn
      ⍝ Validate that this did cause goo to arrive in the workspace
      goo←' r←goo x' ' x x'
      assert'goo≡ns.⎕NR ''goo'''
      ⍝ Also validate that zoo is now gone
      assert'0=ns.⎕NC ''zoo'''
     
      ⍝ Now simulate changing goo using the editor and verify the file is updated
      ns'goo'⎕SE.Link.Fix' r←goo x' ' r←x x x'
      assert'(ns.⎕NR ''goo'')≡⊃⎕NGET goofile 1'
     
      ⎕SE.Link.Expunge'ns.goo' ⍝ Test "expunge"
      assert'0=⎕NEXISTS goofile'
     
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
      (⊂cv←ns.cv,⊂'Line three')⎕NPUT(folder,'/cv.charvec')1
      (⊂↓cm←↑ns.cv)⎕NPUT(folder,'/cm.charmat')1
     
      assert'cm≡↑⊃⎕NGET (folder,''/cm.charmat'') 1'
      assert'cv≡⊃⎕NGET (folder,''/cv.charvec'') 1'
      
      PauseTest folder

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
      CleanUp folder name
    ∇

    ∇ r←Setup folder
      r←'' ⍝ Run will abort if empty
      :If 'Windows'≢7↑⊃'.'⎕WG'APLVersion'
          ⎕←'Unable to run Link.Tests - Microsoft Windows is required to test the FileSystemWatcher'
          →0
      :EndIf
     
      {}⎕SE.UCMD'udebug on'
      ⎕SE.Link.DEBUG←0 ⍝ 1 = Trace, 2 = Stop on entry
     
      :If 0≠⎕NC'⎕SE.Link.Links'
      :AndIf 0≠≢⎕SE.Link.Links
          Log'Please reset all links and try again.'
          Log ⎕SE.UCMD'link.list'
          Log'      ⎕SE.Link.(Break Links.ns)'
          →0
      :EndIf
     
      folder←∊1 ⎕NPARTS folder,(0=≢folder)/'/temp/linktest' ⍝ Normalise
     
      :Trap 22
          2 ⎕MKDIR folder ⍝ 2 ⎕NDELETE folder
      :Case 22
          ⎕←folder,' exists. Clean it out? [y|n] '
          :If 'yYjJ1 '∊⍨⊃⍞~' '
              2 ⎕NDELETE folder ⋄ ⎕DL 1
              3 ⎕MKDIR folder
          :EndIf
      :EndTrap
     
      r←folder
    ∇

    ∇ CleanUp(folder name);z;m
    ⍝ Tidy up after test
     
      ⎕SE.Link.DEBUG←0
      z←⎕SE.Link.Break'#.',name
      assert'0=≢⎕SE.Link.Links'
     
      z←⊃¨5176⌶⍬ ⍝ Check all links have been cleared
      :If ∨/m←((≢folder)↑¨z)∊⊂folder
          ⎕←'*** Links not cleared:'
          ⎕←⍪m/z
      :EndIf
     
      3 ⎕NDELETE folder    ⍝
      #.⎕EX name
    ∇

    ∇ Log x
      ⎕←x ⍝ This might get more sophisticated someday
    ∇
    
    ∇ PauseTest folder;z
     :If 2=⎕NC 'pause_tests'
     :AndIf pause_tests=1 
         ⎕←4(↑⍤1)↑(((≢folder)↑¨4⊃¨z)∊⊂folder)/z←5177⌶⍬    
         ⎕←''
         ⎕←'*** ',(2⊃⎕SI),' paused. To continue,'
         ⎕←'      →RESUME'
         RESUME ⎕STOP 'PauseTest'
     RESUME:
     :EndIf
    ∇

    ∇ assert expr;maxwait;end;timeout
      ⍝ Asynchronous assert: We don't know how quickly the FileSystemWatcher will do something
      end←3000+3⊃⎕AI ⍝ 3s
      timeout←0
     
      :While 0∊{0::0 ⋄ ⍎⍵}expr
          ⎕DL 0.1
      :Until timeout←end<3⊃⎕AI
     
      'assertion failed'⎕SIGNAL timeout/11
    ∇

   ⍝ Callback functions to implement .charmat & .charvec support
    ∇ r←onBasicRead args;type;file;nsname;⎕TRAP;parts;data;extn
      (type file nsname)←3↑args
      r←1 ⍝ Link should carry on; we're not handling this one
     
      :If (⊂extn←3⊃parts←⎕NPARTS file)∊'.charmat' '.charvec'
          :Select type
     
          :Case 'deleted'
              (⍎nsname).⎕EX 2⊃parts
              r←0 ⍝ We're done; Link doesn't need to do any more
     
          :CaseList 'changed' 'renamed' 'created'
              data←(↑⍣(extn≡'.charmat'))⊃⎕NGET file 1
              ⍎nsname,'.',(2⊃parts),'←data'
              r←0 ⍝ As above
     
          :EndSelect
      :EndIf
    ∇

    ∇ r←onBasicWrite args;ns;name;oldname;nc;src;file;⎕TRAP;extn;link;nameq
      (ns name oldname nc src file link nameq)←8↑args
      r←1 ⍝ Link should carry on; we're not handling this one
     
      :If 2=⌊nc ⍝ A variable
     
          :Select ⎕DR src
     
          :CaseList 80 82 160 320
              :If 2=⍴⍴src ⋄ src←↓src
              :Else ⋄ →0
              :EndIf
              extn←⊂'.charmat'
     
          :Case 326
              :If (1≠⍴⍴src)∨~∧/,(10|⎕DR¨src)∊0 2 ⋄ →0
              :EndIf
              extn←⊂'.charvec'
     
          :EndSelect
     
          (⊂src)⎕NPUT(∊(extn@3)⎕NPARTS file)1
          r←0 ⍝ We're done; Link doesn't need to do any more
      :EndIf
    ∇

:EndNamespace
