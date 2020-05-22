:Namespace Test
⍝ Put the Link system and FileSystemWatcher through it's paces
⍝ Call Run with a right argument containing a folder name which can be used for the test
⍝ For example:
⍝   Run 'c:\tmp\linktest'

    ⎕IO←1 ⋄ ⎕ML←1

    USE_ISOLATES←1   ⍝ Boolean : 0=handle files locally ⋄ 1=handle files in isolate
    ⍝ the isolate is to off-load this process from file operations give it more room to run filewatcher callbacks
    ⍝ the namespace will be #.SLAVE, and only file operations that trigger a filewatcher callback need to be run in that namespace
    USE_NQ←0         ⍝ Value to use for ⎕SE.Link.FileSystemWatcher.USE_NQ

    ASSERT_DORECOVER←1 ⍝ Attempt recovery if expression provided
    ASSERT_ERROR←1     ⍝ Boolean : 1=assert failures will error and stop ⋄ 0=assert failures will output message to session and keep running
    PAUSE_LENGTH←0.1   ⍝ Length of delays to insert at strategic points on slow machines - See Breathe

    ∇ Breathe
      ⎕DL PAUSE_LENGTH
    ∇

    STOP_TESTS←0  ⍝ Can be used in a failing thread to stop the action

    ∇ {r}←{flag}NDELETE file;type;name;names;types;n;t
     ⍝ Cover for ⎕NERASE / ⎕NDELETE while we try to find out why it makes callbacks fail
     ⍝ Superseeded by #.SLAVE.⎕NDELETE
      r←1
      :If 0=⎕NC'flag' ⋄ flag←0 ⋄ :EndIf
     
      :Select flag
      :Case 0 ⋄ ⎕NDELETE file
      :Case 2 ⍝ Recursive
          (name type)←0 1 ⎕NINFO file
          :If type=1 ⍝ Directory
              (names types)←0 1(⎕NINFO⍠1)file,'/*'
              :For (n t) :InEach names types
                  :If t=1 ⋄ 2 NDELETE n          ⍝ Subdirectory
                  :Else ⋄ ⎕NDELETE n ⋄ ⎕DL 0.01 ⍝ Better be a file
                  :EndIf
              :EndFor
          :EndIf
          ⎕NDELETE name ⋄ ⎕DL 0.01
      :Else ⋄ 'Larg must be 0 or 2'⎕SIGNAL 11
      :EndSelect
    ∇

    ∇ {r}←text NPUT args;file;bytes;tn;overwrite
     ⍝ Cover for ⎕NPUT
     ⍝ Superseeded by #.SLAVE.⎕NPUT when USE_ISOLATES←1
     
      (file overwrite)←2↑(⊆args),1
      r←≢bytes←⎕UCS'UTF-8'⎕UCS∊(⊃text),¨⊂⎕UCS 13 10
      :If (⎕NEXISTS file)∧overwrite
          tn←file ⎕NTIE 0 ⋄ 0 ⎕NRESIZE tn ⋄ bytes ⎕NAPPEND tn ⋄ ⎕NUNTIE tn ⋄ ⎕DL 0.01
      :Else
          tn←file ⎕NCREATE 0 ⋄ bytes ⎕NAPPEND tn ⋄ ⎕NUNTIE tn ⋄ ⎕DL 0.01
      :EndIf
    ∇

    ∇ r←{test_filter}Run folder;start;pause_tests;tests;z;test;dnv;aplv;opts
     ⍝ Run all the Link Tests. If no folder name provided, default to (739⌶0),'/linktest'
     
      tests←{((5↑¨⍵)∊⊂'test_')⌿⍵}'t'⎕NL ¯3 ⍝ by default: run all tests
      pause_tests←0                             ⍝ no manual testing
     
      :If 0≠⎕NC'test_filter'
          pause_tests←(⊂'pause')∊test_filter
          tests←(1∊¨test_filter∘⍷¨tests)/tests
      :EndIf
     
      →(0=≢folder←Setup folder)⍴0
     
      start←⎕AI[3]
     
      :For test :In tests
          z←(⍎test)folder
      :EndFor
     
      UnSetup folder
     
      dnv←{0::'none' ⋄ ⎕USING←'' ⋄ System.Environment.Version.(∊⍕¨Major'.'(|MajorRevision))}''
      aplv←{⍵↑⍨¯1+2⍳⍨+\'.'=⍵}2⊃'.'⎕WG'APLVersion'
      opts←' (USE_ISOLATES: ',(⍕USE_ISOLATES),', USE_NQ: ',(⍕##.FileSystemWatcher.USE_NQ),', PAUSE_LENGTH: ',(⍕PAUSE_LENGTH),')'
      r←(⍕≢tests),' test[s] passed OK in',(1⍕1000÷⍨⎕AI[3]-start),'s with Dyalog ',aplv,' and .NET ',dnv,opts
    ∇

    ∇ {r}←{x}(F Retry c)y;n
      :If 900⌶⍬
          x←⊢
      :EndIf
      :For n :In ⍳⊃c
          :Trap 0
              r←x F y
              :Return
          :Else
              ⎕SIGNAL(n=c)/⊂⎕DMX.(('EN'EN)('Message'Message))
          :EndTrap
          ⎕DL⊃1↓c
      :EndFor
    ∇

    ∇ r←test_flattened folder;name;main;dup;opts;ns;goo;goofile;dupfile;foo;foofile;z;_
     ⍝ Test the flattened scenario
     
      r←0
      #.⎕EX name←2⊃⎕NPARTS folder
     
      FLAT_TARGET←'app' ⍝ simulated user input to onFlatWrite: declare target folder for new function
     
      {}3 ⎕MKDIR Retry 5 0.1⊢folder
      {}3 ⎕MKDIR folder,'/app'
      {}3 ⎕MKDIR folder,'/utils'
     
      ⍝ ↓↓↓ Do not use QNPUT for these, they must NOT be asynchonous
      _←(⊂main←' r←main' 'r←dup 2')⎕NPUT folder,'/app/main.aplf'        ⍝ One "application" function
      _←(⊂dup←' r←dup x' 'r←x x')⎕NPUT dupfile←folder,'/utils/dup.aplf' ⍝ One "utility" function
     
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
      assert'dupfile≡4⊃5179⌶''ns.dup'''             ⍝   ... await callback & link established
     
      goofile←folder,'/app/goo.aplf'
     
      ns'goo'⎕SE.Link.Fix goo←' r←goo x' ' r←x x x'  ⍝ Add a new function
      assert'goo≡⊃⎕NGET goofile 1'
      assert'goofile≡4⊃5179⌶''ns.goo'''             ⍝   ... await callback & link established
     
      ns'foo' 'goo'⎕SE.Link.Fix foo←' r←foo x' ' r←x x x' ⍝ Simulate RENAME of existing foo > goo
     
      foofile←∊((⊂'foo')@2)⎕NPARTS goofile           ⍝ Expected name of the new file
      assert'foo≡⊃⎕NGET foofile 1'                   ⍝ Validate file has the right contents
      assert'foofile≡4⊃5179⌶''ns.foo'''             ⍝   ... and foo is linked to the right file
     
      Breathe ⍝ Allow backlog of FSW events to clear on slow machines
      _←QNDELETE foofile
      assert'''dup'' ''goo'' ''main''≡ns.⎕nl -3' '⎕EX ''ns.foo'''
     
      PauseTest folder
     
      CleanUp folder name
    ∇

    ∇ r←onFlatWrite args;⎕TRAP;ns;name;oldname;nc;src;file;link;nameq;ext;z
    ⍝ Callback functions to implement determining target folder for flattened link
      (ns name oldname nc src file link nameq)←8↑args
     
      r←1           ⍝ Link should proceed and complete the operation
      →(0=nameq)⍴0  ⍝ We only need to respond to requests for a file name
     
      :If 0≠≢r←4⊃5179 ns.⌶oldname     ⍝ we could find info for oldname
          :If name≢oldname ⍝ copy / rename of an existing function
              r←∊((⊂name)@2)⎕NPARTS r     ⍝ just substitute the name
          :EndIf
      :Else            ⍝ a new function
          ⍝ A real application exit might prompt the user to pick a folder
          ⍝   in the QA example we look to a global variable
          ext←⎕SE.Link.TypeExtension link nc        ⍝ Ask for correct extension for the name class
          r←link.dir,'/',FLAT_TARGET,'/',name,'.',ext  ⍝ Return the file name
      :EndIf
    ∇

      assertMsg←{
          msg←⍎⍵
          ('assertion failed: "',msg,'" instead of "',⍺,'" from: ',⍵)⎕SIGNAL 11/⍨~∨/⍺⍷msg
      }

    ∇ r←test_failures folder;opts;name
      r←0
      #.⎕EX name←2⊃⎕NPARTS folder
     
      'not found'assertMsg'⎕SE.Link.Export''#.',name,'.ns_not_here'' ''',folder,''''
      'not found'assertMsg'⎕SE.Link.Import''#.',name,''' ''',folder,'/dir_not_here'''
     
      opts←⎕NS''
      opts.source←'ns'
      'not found'assertMsg'opts ⎕SE.Link.Create''#.',name,'.ns_not_here'' ''',folder,''''
     
      opts←⎕NS''
      opts.source←'dir'
      'not found'assertMsg'opts ⎕SE.Link.Create''#.',name,''' ''',folder,'/dir_not_here'''
    ∇

    ∇ r←test_import folder;name;foo;cm;cv;ns;z;opts;_;bc;ac
      r←0
      #.⎕EX name←2⊃⎕NPARTS folder
     
      3 ⎕MKDIR Retry 5⊢folder∘,¨'/sub/sub1' '/sub/sub2'
     
      ⍝ make some content
      (⊂foo←' r←foo x' ' x x')⎕NPUT folder,'/foo.dyalog'
      (⊂⊂cv←'Line 1' 'Line two')⎕NPUT¨folder∘,¨'/cm.charmat' '/cv.charvec'
      cm←↑cv
      (⊂'[''one'' 1' '''two'' 2]')⎕NPUT folder,'/sub/sub2/one2.apla'
      (⊂bc←':Class bClass' ':EndClass')⎕NPUT folder,'/sub/sub2/bClass.dyalog'
      (⊂ac←':Class aClass : bClass' ':EndClass')⎕NPUT folder,'/sub/sub2/aClass.dyalog'
     
      opts←⎕NS''
      opts.beforeRead←'⎕SE.Link.Test.onBasicRead'
      opts.beforeWrite←'⎕SE.Link.Test.onBasicWrite'
      ⍝opts.customExtensions←'charmat' 'charvec'
      z←opts ⎕SE.Link.Import('#.',name)folder
      assert'0=≢⎕SE.Link.Links'
     
      ns←#⍎name
     
      assert'foo≡ns.⎕NR''foo'''
⍝ Import does not support custom types at this time
⍝      assert'cm≡ns.cm'
⍝      assert'cv≡ns.cv'
     
      assert'9.1=ns.⎕NC''sub'' ''sub.sub1'' ''sub.sub2'''
      assert'ns.sub.sub2.one2≡2 2⍴''one'' 1 ''two'' 2'
     
      assert'9.4=ns.sub.sub2.⎕NC''aClass'' ''bClass'''
      assert'ac≡⎕SRC ns.sub.sub2.aClass'
      assert'bc≡⎕SRC ns.sub.sub2.bClass'
      ('Unable to instantiate aClass (',(⊃⎕DM),')')assert'≢⎕NEW ns.sub.sub2.aClass'
     
      ⍝ make sure there is no link
      ns'foo'⎕SE.Link.Fix' r←foo x' ' r←x x x'
      assert'foo≢⊃⎕NGET folder,''/foo.dyalog'''
     
      _←(⊂' r←foo x' ' r←x x x x')QNPUT(folder,'/foo.dyalog')1
      assert'(ns.⎕NR''foo'')≢⊃#.SLAVE.⎕NGET folder,''/foo.dyalog'''
     
      ⎕SE.Link.Expunge'ns.sub.sub1'
      assert'⎕NEXISTS folder,''/sub/sub1'''
     
      ⎕EX'ns' ⋄ #.⎕EX name
     
      opts.flatten←1
      z←opts ⎕SE.Link.Import('#.',name)folder
      ns←#⍎name
      assert'0=≢⎕SE.Link.Links'
      assert'0=≢ns.⎕NL-9.1'
     
⍝ Import does not support custom types at this time
⍝      assert'cm≡ns.cm'
⍝      assert'cv≡ns.cv'
     
      assert'ns.one2≡2 2⍴''one'' 1 ''two'' 2'
     
      assert'9.4=ns.⎕NC''aClass'' ''bClass'''
      assert'ac≡⎕SRC ns.aClass'
      assert'bc≡⎕SRC ns.bClass'
      ('Unable to instantiate aClass (',(⊃⎕DM),')')assert'≢⎕NEW ns.aClass'
     
      PauseTest folder
     
      ⍝ Now tear it all down again:
      _←2 QNDELETE folder
      assert'9=⎕NC ''ns'''
     
      #.⎕EX name
    ∇

    ∇ r←test_basic folder;_;ac;bc;cb;cm;cv;file;foo;goo;goofile;link;m;name;new;nil;ns;o2file;old;olddd;opts;otfile;start;t;tn;value;z;zoo;zzz
      r←0
      #.⎕EX name←2⊃⎕NPARTS folder
     
      opts←⎕NS''
      opts.beforeRead←'⎕SE.Link.Test.onBasicRead'
      opts.beforeWrite←'⎕SE.Link.Test.onBasicWrite'
      opts.customExtensions←'charmat' 'charvec'
      opts.watch←'both'
      z←opts ⎕SE.Link.Create('#.',name)folder
      z ⎕SIGNAL(0=≢⎕SE.Link.Links)/11
     
      assert'1=≢⎕SE.Link.Links'
      link←⊃⎕SE.Link.Links
      ns←#⍎name
     
      ⍝ Create a monadic function
      _←(⊂foo←' r←foo x' ' x x')QNPUT folder,'/foo.dyalog'
      assert'foo≡ns.⎕NR ''foo''' 'ns.⎕FX ↑foo'
      ⍝ Create a niladic / non-explicit function
      _←(⊂nil←' nil' ' 2+2')QNPUT folder,'/nil.dyalog'
      assert'nil≡ns.⎕NR ''nil''' 'ns.⎕FX ↑nil'
     
      ⍝ Create an array
      _←(⊂'[''one'' 1' '''two'' 2]')QNPUT o2file←folder,'/one2.apla'
      assert'(2 2⍴''one'' 1 ''two'' 2)≡ns.one2'
     
      ⍝ Update the array
      _←(⊂'[''one'' 1' '''two'' 2' '''three'' 3]')QNPUT o2file 1
      value←(3 2⍴'one' 1 'two' 2 'three' 3)
      assert'value≡ns.one2' 'ns.one2←value'
     
      ⍝ Update array using Link.Fix
      ns.one2←⌽ns.one2
      ns'one2'⎕SE.Link.Fix''
      assert'ns.one2≡##.Deserialise ⊃⎕NGET o2file 1'
     
      ⍝ Rename the array
      Breathe
      otfile←folder,'/onetwo.apla'
      z←ns.one2
      _←otfile #.SLAVE.⎕NMOVE o2file
     
      assert'z≡ns.onetwo' 'ns.onetwo←z'
      assert'0=⎕NC ''ns.one2''' '⎕EX ''ns.one2'''
     
      ⍝ Create sub-folder
      Breathe
      _←#.SLAVE.⎕MKDIR folder,'/sub'
      assert'9.1=ns.⎕NC ⊂''sub''' '''ns.sub'' ⎕NS '''''
     
      ⍝ Move array to sub-folder
      Breathe
      value←ns.onetwo
      _←(new←folder,'/sub/one2.apla')#.SLAVE.⎕NMOVE otfile
      assert'value≡ns.sub.one2' 'ns.sub.one2←value'
     
      ⍝ Erase the array
      Breathe
      _←QNDELETE new
      assert'0=⎕NC ''ns.sub.one2''' '⎕EX ''ns.sub.one2'''
     
      ⍝ Put a copy of foo in the folder
      _←(⊂foo)QNPUT folder,'/sub/foo.dyalog'
      assert'foo≡ns.sub.⎕NR ''foo'''
     
      ⍝ Create a class with missing dependency
      _←(⊂ac←':Class aClass : bClass' ':EndClass')QNPUT folder,'/sub/aClass.dyalog'
      assert'9=ns.sub.⎕NC ''aClass'''
      assert'ac≡⎕SRC ns.sub.aClass'
     
      ⍝ Now add the base class
      _←(⊂bc←':Class bClass' ':EndClass')QNPUT folder,'/sub/bClass.dyalog'
      assert'9=ns.sub.⎕NC ''bClass'''
      assert'bc≡⎕SRC ns.sub.bClass'
     
      ⍝ Check that the derived class works
      :Trap 0 ⋄ {}⎕NEW ns.sub.aClass
      :Else ⋄ ⎕←'NB: Unable to instantiate aClass: ',⊃⎕DM
      :EndTrap
     
      ⍝ Rename the sub-folder
      _←(folder,'/bus')#.SLAVE.⎕NMOVE folder,'/sub'
      assert'9.1=ns.⎕NC ⊂''bus''' '''ns.bus'' ⎕NS '''''     ⍝ bus is a namespace
      assert'3=ns.bus.⎕NC ''foo''' '2 ns.bus.⎕FIX ''file://'',folder,''/bus/foo.dyalog''' ⍝ bus.foo is a function
      assert'∨/''/bus/foo.dyalog''⍷4⊃ns.bus ##.U.GetLinkInfo''foo''' ⍝ check connection is registered
      assert'0=ns.⎕NC ''sub''' '⎕EX ''ns.sub'''             ⍝ sub is gone
     
      ⍝ Now copy a file containing a function
      old←ns ##.U.GetLinkInfo'foo'
      _←(folder,'/foo - copy.dyalog')#.SLAVE.⎕NCOPY folder,'/foo.dyalog' ⍝ simulate copy/paste
      ⎕DL 0.2 ⍝ Allow FileSystemWatcher time to react (always needed)
      goofile←folder,'/goo.dyalog'
      _←goofile #.SLAVE.⎕NMOVE folder,'/foo - copy.dyalog' ⍝ followed by rename
      ⎕DL 0.2 ⍝ Allow FileSystemWatcher some time to react (always needed)
      ⍝ Verify that the old function is still linked to the original file
      assert'old≡new←ns ##.U.GetLinkInfo ''foo''' '5178⌶''ns.foo'''
     
      ⍝ Now edit the new file so it defines 'zoo'
      tn←goofile ⎕NTIE 0 ⋄ 'z'⎕NREPLACE tn 5,⎕DR'' ⋄ ⎕NUNTIE tn ⍝ (beware UTF-8 encoded file)
      ⍝ Validate that this did cause zoo to arrive in the workspace
      zoo←' r←zoo x' ' x x'
      assert'zoo≡ns.⎕NR ''zoo''' 'ns.⎕FX zoo'
     
      Breathe
      ⍝ Finally edit the new file so it finally defines 'goo'
      tn←goofile ⎕NTIE 0
      'g'⎕NREPLACE tn 5,⎕DR'' ⍝ (beware UTF-8 encoded file)
      ⎕NUNTIE tn
      ⍝ Validate that this did cause goo to arrive in the workspace
      goo←' r←goo x' ' x x'
      assert'goo≡ns.⎕NR ''goo''' 'ns.⎕FX goo'
      ⍝ Also validate that zoo is now gone
      assert'0=ns.⎕NC ''zoo''' 'ns.⎕EX ''zoo'''
     
      ⍝ Now simulate changing goo using the editor and verify the file is updated
      ns'goo'⎕SE.Link.Fix' r←goo x' ' r←x x x'
      assert'(ns.⎕NR ''goo'')≡⊃⎕NGET goofile 1'
      assert'goofile≡4⊃5179⌶''ns.goo''' ⍝ Ensure link registered
     
      ⎕SE.Link.Expunge'ns.goo' ⍝ Test "expunge"
      assert'0=⎕NEXISTS goofile'
     
      ⍝ Now test the Notify function - and verify the System Variable setting trick
     
      :If 9=⎕NC'link.fsw.QUEUE'
          fsw←(⍕link.fsw.QUEUE)⎕WG'Data'
      :Else
          fsw←link.fsw
      :EndIf
     
      fsw.EnableRaisingEvents←0 ⍝ Disable notifications
     
      (⊂':Namespace _SV' '##.(⎕IO←0)' ':EndNamespace')NPUT file←folder,'/bus/_SV.dyalog'
      ⎕SE.Link.Notify'created'file
     
      assert'0=ns.bus.⎕IO'
      assert'1=ns.⎕IO'
     
      fsw.EnableRaisingEvents←1 ⍝ Re-enable watcher
     
      ⍝ Now test whether exits implement ".charmat" support
      ⍝ First, write vars in the workspace to file'
     
      ns.cm←↑ns.cv←'Line 1' 'Line two'
      ns'cm'⎕SE.Link.Fix ⍬ ⍝ Inform it charmat was edited
      ns'cv'⎕SE.Link.Fix ⍬ ⍝ Ditto for charvec
      assert'ns.cm≡↑⊃⎕NGET (folder,''/cm.charmat'') 1'
      assert'ns.cv≡⊃⎕NGET (folder,''/cv.charvec'') 1'
     
      ⍝ Then verify that modifying the file brings changes back
      _←(⊂cv←ns.cv,⊂'Line three')QNPUT(folder,'/cv.charvec')1
      _←(⊂↓cm←↑ns.cv)QNPUT(folder,'/cm.charmat')1
     
      assert'cm≡↑⊃#.SLAVE.⎕NGET (folder,''/cm.charmat'') 1'
      assert'cv≡⊃#.SLAVE.⎕NGET (folder,''/cv.charvec'') 1'
     
      PauseTest folder
     
      ⍝ Now tear it all down again:
      ⍝ First the sub-folder
     
      Breathe
      _←2 QNDELETE folder,'/bus'
      assert'0=⎕NC ''ns.bus''' '⎕EX ''ns.bus'''
     
      ⍝ The variables
      _←QNDELETE folder,'/cv.charvec'
      assert'0=ns.⎕NC ''cv''' 'ns.⎕EX ''cv'''
      _←QNDELETE folder,'/cm.charmat'
      assert'0=ns.⎕NC ''cm''' 'ns.⎕EX ''cm'''
     
      ⍝ The the functions, one by one
      _←QNDELETE folder,'/nil.dyalog'
      assert'0=ns.⎕NC ''nil'''
      _←QNDELETE folder,'/foo.dyalog'
      assert'0=≢ns.⎕NL -⍳10' ⍝ top level namespace is now empty
     
     EXIT: ⍝ →EXIT to aborted test and clean up
      CleanUp folder name
    ∇

    ∇ r←test_bugs folder;name;opts
      ⎕EX name←'#.',2⊃⎕NPARTS folder
      name ⎕NS ⍬
      name⍎'var←⍳6'
      (⍎name).⎕FX'goo arg' '⎕←arg'
      opts←⎕NS ⍬
      opts.source←'ns'
      {}opts ⎕SE.Link.Create name folder
      assert'(⊂,⊂folder,''/goo.aplf'')≡(⎕NINFO⍠1⊢folder,''/*'')'
      CleanUp folder name
      r←0
    ∇

    ∇ r←test_casecode folder;name;opts;z;DummyFn;FixFn;fns;nl3;actfiles;mat;expfiles
      r←0
     
      ⎕EX name←'#.',2⊃⎕NPARTS folder
     
      ⎕MKDIR folder
     
      opts←⎕NS''
      opts.caseCode←1
      z←opts ⎕SE.Link.Create name folder
     
      fns←⍬
      DummyFn←{('   ∇   r   ←   ',⍵)('   ⎕   ←   ''',⍵,'''   ⍝   ')('   ∇   ')}
      FixFn←name∘{_←⍺ ⍵ ⎕SE.Link.Fix DummyFn ⍵ ⋄ ⍵}
      fns,←⊂FixFn'fn_CaseCode'
      ⍝fns,←⊂FixFn'FN_CaseCode'   ⍝ this one will fail on windows
      Breathe
      {}⎕SE.Link.Break name ⋄ #.⎕EX name
     
      opts.caseCode←0
      z←opts ⎕SE.Link.Create name folder
     
      fns,←⊂FixFn'fn_NoCaseCode'
      ⍝fns,←⊂FixFn'FN_NoCaseCode'  ⍝ this one will fail on windows
      Breathe
      {}⎕SE.Link.Break name ⋄ #.⎕EX name
     
      opts.caseCode←1
      z←opts ⎕SE.Link.Create name folder
     
      nl3←(⍎name).⎕NL ¯3
      expfiles←{⍵[⍋⍵]}(1+≢folder)↓¨⎕SE.Link.GetFileName(name,'.')∘,¨fns
      actfiles←{⍵[⍋⍵]}(1+≢folder)↓¨⊃⎕NINFO⍠1⊢folder,'/*'
      ⍝ mat←↑{⍵[⍋↑⍵]}¨fns nl3 expfiles actfiles
      ⍝ ⎕←'expected apl names' 'actual apl names' 'expected file names' 'actual file names',mat
      assert'expfiles≡actfiles'
      assert'fns≡nl3'
      Breathe
      {}⎕SE.Link.Break name ⋄ #.⎕EX name
     
      CleanUp folder name
    ∇

    ∇ r←Setup folder;canwatch;dotnetcore
      r←'' ⍝ Run will abort if empty
     
      ⎕PW⌈←300
      (canwatch dotnetcore)←##.U.CanWatch''
      ⎕SE.Link.FileSystemWatcher.USE_NQ←USE_NQ
      ⎕SE.Link.FileSystemWatcher.DEBUG←1 ⍝ Turn on event logging
     
      :If ~canwatch
          ⎕←'Unable to run Link.Tests - .NET is required to test the FileSystemWatcher'
          →0
      :EndIf
     
      :If 0=⎕NC'⎕SE.Link.DEBUG' ⋄ ⎕SE.Link.DEBUG←0 ⋄ :EndIf
      {}⎕SE.UCMD'udebug ','off' 'on'⊃⍨0 1⍸⎕SE.Link.DEBUG
      ⍝⎕SE.Link.DEBUG←1 ⍝ 1 = Trace, 2 = Stop on entry
     
      :If 0≠⎕NC'⎕SE.Link.Links'
      :AndIf 0≠≢⎕SE.Link.Links
          Log'Please break all links and try again.'
          Log ⎕SE.UCMD'link.list'
          Log'      ⎕SE.Link.(Break Links.ns) ⍝ to break all links'
          →0
      :EndIf
     
      folder←∊1 ⎕NPARTS folder,(0=≢folder)/(739⌶0),'/linktest'
     
      :Trap 22
          2 ⎕MKDIR folder
      :Case 22
          ⎕←folder,' exists. Clean it out? [y|n] '
          :If 'yYjJ1 '∊⍨⊃⍞~' '
              {2 ⎕MKDIR ⍵⊣⎕DL 1⊣3 ⎕NDELETE ⍵}Retry 5⊢folder
          :EndIf
      :EndTrap
     
      :If USE_ISOLATES
          :If 9.1≠⎕NC⊂'#.isolate'
              #.⎕CY'isolate'
          :EndIf
          {}#.isolate.Config'processors' 1 ⍝ Only start 1 slave
          #.SLAVE←#.isolate.New''
          QNDELETE←{⍺←⊢ ⋄ ⍺ #.SLAVE.⎕NDELETE ⍵}
          QNPUT←{⍺←⊢ ⋄ ⍺ #.SLAVE.⎕NPUT ⍵}
      :Else
          #.SLAVE←#.⎕NS''
          QNDELETE←{⍺←⊢ ⋄ ⍺ NDELETE ⍵}
          QNPUT←{⍺ NPUT ⍵}
      :EndIf
     
      r←folder
    ∇

    ∇ UnSetup folder
      :If USE_ISOLATES
          z←4=#.SLAVE.(2+2) ⍝ Make sure it finished what it was doing
          {}#.isolate.Reset 0
          ⎕EX'#.SLAVE'
      :EndIf
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
      :If 2=⎕NC'pause_tests'
      :AndIf pause_tests=1
          ⎕←4(↑⍤1)↑(((≢folder)↑¨4⊃¨z)∊⊂folder)/z←5177⌶⍬
          ⎕←''
          ⎕←'*** ',(2⊃⎕SI),' paused. To continue,'
          ⎕←'      →RESUME'
          RESUME ⎕STOP'PauseTest'
     RESUME:
      :EndIf
    ∇

    ∇ {txt}←{msg}assert args;clean;expr;maxwait;end;timeout;txt
      ⍝ Asynchronous assert: We don't know how quickly the FileSystemWatcher will do something
     
      :If STOP_TESTS
          ⎕←'STOP_TESTS detected...'
          (1+⊃⎕LC)⎕STOP'assert'
      :EndIf
     
      (expr clean)←2↑(⊆args),⊂''
      end←1000+3⊃⎕AI ⍝ 3s
      timeout←0
     
      :While 0∊{0::0 ⋄ ⍎⍵}expr
          ⎕DL 0.1
      :Until timeout←end<3⊃⎕AI
     
      :If 900⌶⍬ ⍝ Monadic
          msg←'assertion failed'
      :EndIf
      :If ~timeout ⋄ txt←'' ⋄ :Return ⋄ :EndIf
     
      txt←msg,': ',expr,' at ',(2⊃⎕SI),'[',(⍕2⊃⎕LC),']'
      :If ASSERT_DORECOVER∧0≠≢clean ⍝ Was a recovery expression provided?
          ⍎clean
      :AndIf ~0∊{0::0 ⋄ ⍎⍵}expr ⍝ Did it work?
          ⎕←'*** Warning: ',txt
          ⎕←'***    recovered via ',clean
          :Return
      :EndIf
     
      ⍝ No recovery, or recovery failed
      :If ASSERT_ERROR
          txt ⎕SIGNAL 11
      :Else ⍝ Just muddle on, not recommended!
          ⎕←txt
      :EndIf
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
              data←↑⍣(extn≡'.charmat')##.U.GetFile file
              ⍎nsname,'.',(2⊃parts),'←data'
              r←0 ⍝ As above
          :EndSelect
      :EndIf
    ∇

    ∇ r←onBasicWrite args;ns;name;oldname;nc;src;file;⎕TRAP;extn;link;nameq
      (ns name oldname nc src file link nameq)←8↑args
      :If nameq ⋄ r←'' ⋄ :Return ⋄ :EndIf  ⍝ let link choose the file name
      r←1 ⍝ Link should carry on; we're not handling this one
      :If 2=⌊nc ⍝ A variable
          :Select ⎕DR src
          :CaseList 80 82 160 320
              :If 2=⍴⍴src ⋄ src←↓src ⋄ :Else ⋄ :Return ⋄ :EndIf
              extn←⊂'.charmat'
          :Case 326
              :If (1≠⍴⍴src)∨~∧/,(10|⎕DR¨src)∊0 2 ⋄ :Return ⋄ :EndIf
              extn←⊂'.charvec'
          :EndSelect
     
          (⊂src)NPUT(∊(extn@3)⎕NPARTS file)1
          r←0 ⍝ We're done; Link doesn't need to do any more
      :EndIf
    ∇


      assert_create←{  ⍝ ⍺=newapl ⋄ ⍵=newfile
          _←assert(⍺/'new'),'var≡⍎subname,''.var'''
          _←assert(⍺/'new'),'foosrc≡⎕NR subname,''.foo'''
          _←assert(⍺/'new'),'nssrc≡⎕SRC ⍎subname,''.ns'''
          _←assert(⍵/'new'),'varsrc≡⊃⎕NGET (subfolder,''/var.apla'') 1'
          _←assert(⍵/'new'),'foosrc≡⊃⎕NGET (subfolder,''/foo.aplf'') 1'
          _←assert(⍵/'new'),'nssrc≡⊃⎕NGET (subfolder,''/ns.apln'') 1'
      }

    ∇ r←test_create folder;foosrc;name;newfoosrc;newnssrc;newvar;newvarsrc;nssrc;opts;subfolder;subname;var;varsrc;z
      r←0 ⋄ opts←⎕NS ⍬
      ⎕EX name←'#.',2⊃⎕NPARTS folder
     
      ⍝ test failing creations
      3 ⎕NDELETE folder ⋄ opts.source←'dir'
      z←opts ⎕SE.Link.Create name folder
      assert'∨/''not found''⍷z'
      ⎕EX name ⋄ opts.source←'ns'
      z←opts ⎕SE.Link.Create name folder
      assert'∨/''not found''⍷z'
      assert'0=≢⎕SE.Link.Links'
     
      ⍝ test source=dir watch=dir
      opts.source←'dir' ⋄ opts.watch←'dir'
      2 ⎕MKDIR folder
      2 ⎕MKDIR subfolder←folder,'/sub' ⋄ subname←name,'.sub'
      (⊂foosrc←' r←foo x' ' ⍝ comment' ' r←''foo''x')∘⎕NPUT¨folder subfolder,¨⊂'/foo.aplf'
      (⊂varsrc←,↓⎕SE.Link.Serialise var←((⊂'hello')@2)¨⍳1 1 2)∘⎕NPUT¨folder subfolder,¨⊂'/var.apla'
      (⊂nssrc←':Namespace ns' ' ⍝ comment' 'foo←{''foo''⍵}' ':EndNamespace')∘⎕NPUT¨folder subfolder,¨⊂'/ns.apln'
      z←opts ⎕SE.Link.Create name folder
      assert'''Linked:''≡7↑z'
      assert'var∘≡¨⍎¨name subname,¨⊂''.var'''
      assert'foosrc∘≡¨⎕NR¨name subname,¨⊂''.foo'''
      assert'nssrc∘≡¨⎕SRC¨⍎¨name subname,¨⊂''.ns'''
      ⍝ watch=dir must reflect changes from files to APL
      {}(⊂newvarsrc←,↓⎕SE.Link.Serialise newvar←((⊂'world')@2)¨var)QNPUT(subfolder,'/var.apla')1
      {}(⊂newfoosrc←(⊂' ⍝ new comment')@2⊢foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newnssrc←(⊂' ⍝ new comment')@2⊢nssrc)QNPUT(subfolder,'/ns.apln')1
      1 assert_create 1
      ⍝ watch=dir must not reflect changes from APL to files
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      Breathe
      0 assert_create 1
      {}⎕SE.Link.Break name ⋄ ⎕EX name  ⍝ expunge whole linked namespace
     
     
      ⍝ now try source=dir watch=ns
      opts.source←'dir' ⋄ opts.watch←'ns'
      {}opts ⎕SE.Link.Create name folder
      1 assert_create 1
      ⍝ APL changes must be reflected to file
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      0 assert_create 0
      ⍝ file changes must not be reflected back to APL
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1
      Breathe
      0 assert_create 1
      {}⎕SE.Link.Break name ⋄ ⎕EX name  ⍝ expunge whole linked namespace
     
      ⍝ now try source=dir watch=none
      opts.source←'dir' ⋄ opts.watch←'none'
      {}opts ⎕SE.Link.Create name folder
      1 assert_create 1
      {}(⊂varsrc)QNPUT(subfolder,'/var.apla')1
      {}(⊂foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂nssrc)QNPUT(subfolder,'/ns.apln')1
      Breathe
      1 assert_create 0
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1
      Breathe
      1 assert_create 1
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      Breathe
      0 assert_create 1
      {}⎕SE.Link.Break name
      3 ⎕NDELETE folder
     
      ⍝ now try source=ns watch=dir
      opts.source←'ns' ⋄ opts.watch←'dir'
      {}opts ⎕SE.Link.Create name folder
      0 assert_create 0
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1
      1 assert_create 1
      Breathe  ⍝ not sure why need a breath here on windows/.netframework
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      Breathe
      0 assert_create 1
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder
     
      ⍝ now try source=ns watch=ns
      opts.source←'ns' ⋄ opts.watch←'ns'
      {}opts ⎕SE.Link.Create name folder
      0 assert_create 0
      subname'var'⎕SE.Link.Fix newvarsrc
      subname'foo'⎕SE.Link.Fix newfoosrc
      subname'ns'⎕SE.Link.Fix newnssrc
      1 assert_create 1
      {}(⊂varsrc)QNPUT(subfolder,'/var.apla')1
      {}(⊂foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂nssrc)QNPUT(subfolder,'/ns.apln')1
      Breathe
      1 assert_create 0
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder
     
      ⍝ now try source=ns watch=none
      opts.source←'ns' ⋄ opts.watch←'none'
      {}opts ⎕SE.Link.Create name folder
      1 assert_create 1
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      Breathe
      0 assert_create 1
      subname'var'⎕SE.Link.Fix newvarsrc
      subname'foo'⎕SE.Link.Fix newfoosrc
      subname'ns'⎕SE.Link.Fix newnssrc
      1 assert_create 1
      {}(⊂varsrc)QNPUT(subfolder,'/var.apla')1
      {}(⊂foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂nssrc)QNPUT(subfolder,'/ns.apln')1
      Breathe
      1 assert_create 0
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder
     
     
      CleanUp folder name
    ∇

:EndNamespace
