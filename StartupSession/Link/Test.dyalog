:Namespace Test
⍝ Put the Link system and FileSystemWatcher through it's paces
⍝ Call Run with a right argument containing a folder name which can be used for the test
⍝ For example:
⍝   Run 'c:\tmp\linktest'

    ⍝ TODO
    ⍝ - test quadVars.apln produced by Acre
    ⍝   ':Namespace quadVars'  '##.(⎕IO ⎕ML ⎕WX)←0 1 3'  ':EndNamespace'
    ⍝ - test ⎕SE.Link.Add '⎕IO', and that subsequent script fix observed it (⎕SIGNAL (⎕IO≠0)/11)
    ⍝ - proper QA for arrays and tradns add/expunge
    ⍝ - test invalid files / hidden files / files with nasty side effects on fix
    ⍝   and that ⎕SE.Link reports about them
    ⍝ - ensure beforeRead is called at Create/Import time
    ⍝   and that our special format is not loaded by link (which would fail)
    ⍝ - ensure beforeWrite is called at Create/Export time
    ⍝   and that files are not overwritten by link
    ⍝ - case-code+flatten (on sub-directories)
    ⍝ - test UCMD's with modifiers
    ⍝ - test basic git usage

    ⍝ TODO test ⎕ED :
    ⍝ - renaming a function in ⎕ED (to an existing name and to a non-existing name)
    ⍝ - changing nameclass in ⎕ED
    ⍝ - updating a function with stops
    ⍝ - changing valid source to invalid source (e.g. 'r←foo;')
    ⍝ - editiing a new name and giving it invalid source



    :Section Main entry point and global settings

    ⎕IO←1 ⋄ ⎕ML←1

    USE_ISOLATES←1   ⍝ Boolean : 0=handle files locally ⋄ 1=handle files in isolate
    ⍝ the isolate is to off-load this process from file operations give it more room to run filewatcher callbacks
    ⍝ the namespace will be #.SLAVE, and only file operations that trigger a filewatcher callback need to be run in that namespace

    NAME←'#.linktest'  ⍝ namespace used by link tests
    FOLDER←''          ⍝ empty defaults to default to a new directory in (739⌶0)

    ASSERT_DORECOVER←0 ⍝ Attempt recovery if expression provided
    ASSERT_ERROR←1     ⍝ Boolean : 1=assert failures will error and stop ⋄ 0=assert failures will output message to session and keep running
    STOP_TESTS←0       ⍝ Can be used in a failing thread to stop the action

    PAUSE_TIME←0.1   ⍝ Seconds of delays to insert at strategic points - See Breathe
    ASSERT_TIME←1    ⍝ Seconds of wait time trying to verify assertions


    ∇ r←{debug}Run test_filter;aplv;core;dnv;folder;opts;test;tests;time;z
    ⍝ Do (⎕SE.Link.Test.Run'') to run all the Link Tests.
    ⍝ If no folder name provided,
      :If 0≠⎕NC'debug' ⋄ ⎕SE.Link.DEBUG←debug ⋄ :EndIf
     
      tests←{((5↑¨⍵)∊⊂'test_')⌿⍵}'t'⎕NL ¯3 ⍝ by default: run all tests
      pause_tests←0                             ⍝ no manual testing
     
      :If 0≠⎕NC'test_filter'
          pause_tests←(⊂'pause')∊test_filter
          tests←(∨⌿1∊¨(,⊆test_filter)∘.⍷tests)/tests
      :EndIf
     
      →(0=≢folder←Setup FOLDER NAME)⍴0
      time←⎕AI[3]
      :For test :In tests
          ⍝⎕←'*** TESTING'test
          z←(⍎test)folder NAME   ⍝ run test_*
      :EndFor
      time←⎕AI[3]-time
      UnSetup
     
      dnv←{0::'none' ⋄ ⎕USING←'' ⋄ System.Environment.Version.(∊⍕¨Major'.'(|MajorRevision))}''
      core←(1+##.U.DotNetCore)⊃'Framework' 'Core'
      aplv←{⍵↑⍨¯1+2⍳⍨+\'.'=⍵}2⊃'.'⎕WG'APLVersion'
      opts←' (USE_ISOLATES: ',(⍕USE_ISOLATES),', USE_NQ: ',(⍕##.FileSystemWatcher.USE_NQ),', PAUSE_TIME: ',(⍕PAUSE_TIME),')'
      r←(⍕≢tests),' test[s] passed OK in',(1⍕time÷1000),'s with Dyalog ',aplv,' and .Net',core,' ',dnv,opts
    ∇

    :EndSection Main entry point and global settings






    :Section test_functions

    ∇ r←test_flattened(folder name);main;dup;opts;ns;goo;goofile;dupfile;foo;foofile;z;_
     ⍝ Test the flattened scenario
     
      r←0
     
      FLAT_TARGET←'app' ⍝ simulated user input to onFlatWrite: declare target folder for new function
     
      {}3 ⎕MKDIR Retry⊢folder
      {}3 ⎕MKDIR folder,'/app'
      {}3 ⎕MKDIR folder,'/utils'
     
      ⍝ ↓↓↓ Do not use QNPUT for these, they must NOT be asynchonous
      _←(⊂main←' r←main' 'r←dup 2')⎕NPUT folder,'/app/main.aplf'        ⍝ One "application" function
      _←(⊂dup←' r←dup x' 'r←x x')⎕NPUT dupfile←folder,'/utils/dup.aplf' ⍝ One "utility" function
     
      opts←⎕NS''
      opts.(flatten source)←1 'dir'
      opts.getFilename←'⎕SE.Link.Test.onFlatFilename'
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

    ∇ r←onFlatFilename args;event;ext;file;link;name;nc;oldname
    ⍝ Callback functions to implement determining target folder for flattened link
      (event link file name nc oldname)←6↑args
      :If 0≠≢r←4⊃5179⌶oldname     ⍝ we could find info for oldname
          :If name≢oldname ⍝ copy / rename of an existing function
              name←(⌽∧\⌽name≠'.')/name  ⍝ drop namespace specification
              r←∊((⊂name)@2)⎕NPARTS r     ⍝ just substitute the name
          :EndIf
      :Else            ⍝ a new function
          ⍝ A real application exit might prompt the user to pick a folder
          ⍝   in the QA example we look to a global variable
          ext←link ⎕SE.Link.TypeExtension nc        ⍝ Ask for correct extension for the name class
          name←(⌽∧\⌽name≠'.')/name  ⍝ drop namespace specification
          r←link.dir,'/',FLAT_TARGET,'/',name,'.',ext  ⍝ Return the file name
      :EndIf
    ∇










    ∇ r←test_failures(folder name);opts;z
      r←0
     
      'not found'assertMsg'⎕SE.Link.Export''#.',name,'.ns_not_here'' ''',folder,''''
      'not found'assertMsg'⎕SE.Link.Import''#.',name,''' ''',folder,'/dir_not_here'''
     
      opts←⎕NS''
      opts.source←'ns'
      'not found'assertMsg'opts ⎕SE.Link.Create''#.',name,'.ns_not_here'' ''',folder,''''
     
      opts←⎕NS''
      opts.source←'dir'
      'not found'assertMsg'opts ⎕SE.Link.Create''#.',name,''' ''',folder,'/dir_not_here'''
     
      name ⎕NS''
      opts←⎕NS'' ⋄ opts.source←'ns'
      {}opts ⎕SE.Link.Create name folder
      assertError('name ''foo'' ⎕SE.Link.Fix '';;;'' '';;;'' ')('Invalid source')
      assertError('name ''foo'' ⎕SE.Link.Fix '''' ')('No source')
      assertError('name ''¯1'' ⎕SE.Link.Fix '''' ')('Invalid name')
      assertError(' ''¯1'' ''foo'' ⎕SE.Link.Fix '''' ')('Not a namespace')
     
      z←name'foo'⎕SE.Link.Fix,⊂'foo←{1 2 3}'
      assert'z≡1'
      z←'#' 'foo'⎕SE.Link.Fix,⊂'foo←{1 2 3}'
      assert'z≡0'
      Breathe ⍝ windows needs some time to clean up the file ties
     
      {}⎕SE.Link.Break name
      CleanUp folder name
    ∇









    ∇ r←test_import(folder name);foo;cm;cv;ns;z;opts;_;bc;ac
      r←0
     
      3 ⎕MKDIR Retry⊢folder∘,¨'/sub/sub1' '/sub/sub2'
     
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







    ∇ r←test_basic(folder name);_;ac;bc;cb;cm;cv;file;foo;fsw;goo;goofile;link;m;new;nil;nl;ns;o2file;old;olddd;opts;otfile;start;t;tn;value;z;zoo;zzz
      r←0
     
      3 ⎕MKDIR Retry⊢folder
     
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
      assert'ns.one2≡⎕SE.Dyalog.Array.Deserialise ⊃⎕NGET o2file 1'
     
      ⍝ Rename the array
      Breathe ⋄ Breathe ⋄ Breathe   ⍝ because the previous Fix can trigger several "changed" filewatcher callbacks, and the following ⎕NMOVE would confuse them
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
      assert'0=⎕NC''ns.onetwo''' '⎕EX''ns.onetwo'''
     
      ⍝ Duplicate array (effect will be checked by looking at ⎕NL after renaming directory)
      ns.sub.onetwo←ns.sub.one2
      assert'~⎕NEXISTS folder,''/sub/onetwo.apla'''
      {}⎕SE.Link.Add'ns.sub.onetwo'  ⍝ BUG : watcher create event produces a warning that file attempts to redefine existing variable
      Breathe
      assert'⎕NEXISTS folder,''/sub/onetwo.apla'''
      assert'2=⎕NC''ns.sub.onetwo'''
     
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
      nl←'aClass' 'bClass' 'foo' 'onetwo'
      assert'nl≡ns.sub.⎕NL-⍳10'                             ⍝ contents are the same
      assert'0=ns.⎕NC''bus'''
      _←(folder,'/bus')#.SLAVE.⎕NMOVE folder,'/sub'
      assert'9.1=ns.⎕NC ⊂''bus''' '''ns.bus'' ⎕NS '''''     ⍝ bus is a namespace
      assert'3=ns.bus.⎕NC ''foo''' '2 ns.bus.⎕FIX ''file://'',folder,''/bus/foo.dyalog''' ⍝ bus.foo is a function
      assert'∨/''/bus/foo.dyalog''⍷4⊃ns.bus.(5179⌶)''foo''' ⍝ check connection is registered
      assert'0=ns.⎕NC ''sub''' '⎕EX ''ns.sub'''             ⍝ sub is gone
      assert'nl≡ns.bus.⎕NL-⍳10'                             ⍝ contents are the same
     
      ⍝ Now copy a file containing a function
      old←ns.(5179⌶)'foo'
      _←(folder,'/foo - copy.dyalog')#.SLAVE.⎕NCOPY folder,'/foo.dyalog' ⍝ simulate copy/paste
      Breathe ⋄ Breathe ⋄ Breathe ⍝ Allow FileSystemWatcher time to react (always needed)
      goofile←folder,'/goo.dyalog'
      _←goofile #.SLAVE.⎕NMOVE folder,'/foo - copy.dyalog' ⍝ followed by rename
      Breathe ⋄ Breathe ⋄ Breathe ⍝ Allow FileSystemWatcher some time to react (always needed)
      ⍝ Verify that the old function is still linked to the original file
      assert'old≡new←ns.(5179⌶)''foo''' '5178⌶''ns.foo'''
     
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
      assert'0=⎕NC''ns.goo'''
     
      ⍝ Now test the Notify function - and verify the System Variable setting trick
      name Watch 0  ⍝ pause file watching
      {}(⊂':Namespace _SV' '##.(⎕IO←0)' ':EndNamespace')QNPUT file←folder,'/bus/_SV.dyalog'
      ⎕SE.Link.Notify'created'file
      assert'0=ns.bus.⎕IO'
      assert'1=ns.⎕IO'
      name Watch 1  ⍝ resume watcher
     
     
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

   ⍝ Callback functions to implement .charmat & .charvec support
    ∇ r←onBasicRead args;data;event;extn;file;link;name;nc;parts
      (event link file name nc)←5↑args
      r←1 ⍝ Link should carry on; we're not handling this one
      :If (⊂extn←3⊃parts←⎕NPARTS file)∊'.charmat' '.charvec'
          data←↑⍣(extn≡'.charmat')##.U.GetFile file
          ⍎name,'←data'
          r←0 ⍝ We're done; Link doesn't need to do any more
      :EndIf
    ∇
    ∇ r←onBasicWrite args;event;extn;file;link;name;nc;oldname;src;value
      (event link file name nc oldname src)←7↑args
      r←1 ⍝ Link should carry on; we're not handling this one
      :If 2=⌊nc ⍝ A variable
          :Select ⎕DR value←⍎name
          :CaseList 80 82 160 320
              :If 2=⍴⍴value ⋄ src←↓value ⋄ :Else ⋄ :Return ⋄ :EndIf
              extn←⊂'.charmat'
          :Case 326
              :If (1≠⍴⍴value)∨~∧/,(10|⎕DR¨value)∊0 2 ⋄ :Return ⋄ :EndIf
              src←value
              extn←⊂'.charvec'
          :EndSelect
          {}(⊂src)QNPUT(∊(extn@3)⎕NPARTS file)1
          r←0 ⍝ We're done; Link doesn't need to do any more
      :EndIf
    ∇









    ∇ r←test_casecode(folder name);DummyFn;FixFn;actfiles;actnames;expfiles;expnames;files;fn;fn2;fnfile;fns;goo;mat;name;nl;nl3;ns;opts;var;var2;varfile;winfolder;z
      r←0
     
      ⍝ Test creating a folder from a namespace with Case Conflicts
      winfolder←⎕SE.Link.U.WinSlash folder
     
      ns←⍎name ⎕NS''
      ns.('sub'⎕NS'')
      ns.sub.⎕FX'r←dup x' 'r←x x'  ⍝ ns.sub.dup
      ns.('SUB'⎕NS'')
      ns.SUB.⎕FX'r←DUP x' 'r←x x'  ⍝ ns.SUB.DUP
      ns.SUB.('SUBSUB'⎕NS'')
      ns.SUB.SUBSUB.⎕FX'r←DUPDUP x' 'r←x x'
      ns.var←42 42
     
      opts←⎕NS''
      opts.caseCode←0  ⍝ No case coding
      opts.source←'ns' ⍝ Create folder from
     
      ⍝ Try saving namespace without case coding
      :Trap ⎕SE.Link.U.ERRNO
          z←opts ⎕SE.Link.Export name folder
          'Link issue #113'assert'0'
          ⎕NDELETE⍠1⊢folder
      :Else
          'Link issue #113'assert'∨/''File name case clash''⍷⊃⎕DM'
          ⍝assert'~⎕NEXISTS folder'        ⍝ folder must not exist
          assert'0∊⍴⊃⎕NINFO⍠1⊢folder,''/*'''  ⍝ folder must remain empty
      :EndTrap
      3 ⎕NDELETE folder
      :Trap ⎕SE.Link.U.ERRNO
          z←opts ⎕SE.Link.Create name folder
          'Link issue #113'assert'0'
          ⎕SE.Link.Break name
      :Else
          'Link issue #113'assert'∨/''File name case clash''⍷⊃⎕DM'
          ⍝assert'~⎕NEXISTS folder'        ⍝ folder must not exist
          assert'0∊⍴⊃⎕NINFO⍠1⊢folder,''/*'''  ⍝ folder must remain empty
      :EndTrap
      3 ⎕NDELETE folder
     
      ⍝ now do it properly
      opts.caseCode←1
      z←opts ⎕SE.Link.Export name folder
      assert'z≡''Exported: ',name,' → ',winfolder,''''
      actfiles←{⍵[⍋⍵]}(1+≢folder)↓¨0 NTREE folder
      expfiles←'SUB-7/DUP-7.aplf' 'SUB-7/SUBSUB-77/DUPDUP-77.aplf' 'sub-0/dup-0.aplf'
      'link issue #43'assert'actfiles≡expfiles'
      ⍝ TODO : export cannot export arrays ? (ns.var)
      3 ⎕NDELETE folder
     
      ⍝ try variables too
      z←opts ⎕SE.Link.Create name folder
      assert'z≡''Linked: ',name,' ←→ ',winfolder,''''
      actfiles←{⍵[⍋⍵]}(1+≢folder)↓¨0 NTREE folder
      'link issue #43'assert'actfiles≡expfiles'
      {}⎕SE.Link.Add name,'.var'  ⍝ BUG : ⍝ BUG : watcher create event produces a warning that file attempts to redefine existing variable
      actfiles←{⍵[⍋⍵]}(1+≢folder)↓¨0 NTREE folder
      expfiles,←⊂'var-0.apla'
      assert'actfiles≡expfiles'
     
      {}⎕SE.Link.Break name ⋄ ⎕EX name
     
      ⍝ now open it back without case coding
      opts.caseCode←0
      opts.source←'dir'
      z←opts ⎕SE.Link.Import name folder
      assert'z≡''Imported: ',name,' ← ',winfolder,''''
      actnames←{⍵[⍋⍵]}0 NSTREE name
      expnames←{⍵[⍋⍵]}(name,'.')∘,¨'SUB.DUP' 'SUB.SUBSUB.DUPDUP' 'sub.dup' 'var'
      assert'actnames≡expnames'
      ⎕EX name
     
      ⍝ open it back without case coding and with forcefilenames - must fail
      opts.forceFilenames←1
      assertError'opts ⎕SE.Link.Import name folder' 'clashing file names'
     
      opts.caseCode←1
      {}⎕SE.Link.Create name folder
      {}⎕SE.Link.Break name
     
      ⍝ survive clashing apl definitions despite different filenames
      {}(⊂'r←foo x' 'r←''foo'' x')∘QNPUT¨files←folder∘,¨'/clash1.aplf' '/clash2.aplf'
      assertError'opts ⎕SE.Link.Create name folder' 'clashing APL names'
      {}QNDELETE¨1↓files
     
      ⍝ forcefilename will rename file with proper casecoding
      assert'1 0≡⎕NEXISTS folder∘,¨''/clash1.aplf'' ''/foo-0.aplf'''
      {}opts ⎕SE.Link.Create name folder
      assert'0 1≡⎕NEXISTS folder∘,¨''/clash1.aplf'' ''/foo-0.aplf'''
     
      ⍝ check forcefilename on-the-fly
      fn←' r←Dup x' ' r←x x'  ⍝ whitespace not preserved because of ⎕NR
      {}(⊂fn)QNPUT folder,'/NotDup.aplf'
      assert'fn≡⎕NR name,''.Dup'''
      assert'0 1≡⎕NEXISTS folder∘,¨''/NotDup.aplf'' ''/Dup-1.aplf'''
     
      ⍝ check file rename on-the-fly
      Breathe ⋄ Breathe ⋄ Breathe   ⍝ the previous operation requires extensive post-processing so that Notify handles the ⎕NMOVE triggered by the original Notify
      {}(folder,'/NotDup.aplf')#.SLAVE.⎕NMOVE(folder,'/Dup-1.aplf')
      assert'0 1≡⎕NEXISTS folder∘,¨''/NotDup.aplf'' ''/Dup-1.aplf'''
     
      ⍝ check apl rename on-the-fly
      Breathe
      fn←' r←DupduP x' ' r←x x x'
      {}(⊂fn)QNPUT(folder,'/Dup-1.aplf')1
      assert'0=⎕NC name,''.Dup'''  ⍝ old definition should be expunged
      assert'fn≡⎕NR name,''.DupduP'''
      assert'0 1≡⎕NEXISTS folder∘,¨''/Dup-1.aplf'' ''/DupduP-41.aplf'''
      nl←(⍎name).⎕NL-⍳10
     
      ⍝ can't rename because it would clash
      Breathe
      fn2←' r←DupduP x' 'r←x x x x'
      {}(⊂fn2)QNPUT folder,'/NotDupduP.aplf'
      assert'nl≡(⍎name).⎕NL -⍳10'  ⍝ no change in APL
      assert'fn≡⎕NR name,''.DupduP'''
      assert'1 1≡⎕NEXISTS folder∘,¨''/NotDupduP.aplf'' ''/DupduP-41.aplf'''
     
      ⍝ very that delete that supplementary file has no effect
      Breathe
      {}QNDELETE folder,'/NotDupduP.aplf'  ⍝ delete
      assert'nl≡(⍎name).⎕NL -⍳10'  ⍝ no change in APL
      assert'fn≡⎕NR name,''.DupduP'''
     
      {}⎕SE.Link.Break name
     
      opts.forceFilenames←0
      opts.forceExtensions←1
     
      ⍝ survive clashing apl definitions despite different filenames
      {}(⊂'r←goo x' 'r←''goo'' x')∘QNPUT¨files←folder∘,¨'/goo.apla' '/goo.apln'
      {}(⊂'r←hoo x' 'r←''hoo'' x')QNPUT folder,'/hoo.aplf'  ⍝ this one should remain as is
      assertError'{}opts ⎕SE.Link.Create name folder' 'clashing APL names'
      {}QNDELETE¨1↓files
     
      ⍝ check forceextensions - should not enforce casecoding
      assert'1 0 0≡⎕NEXISTS folder∘,¨''/goo.apla'' ''/goo.aplf'' ''/goo-0.aplf'''
      assert'1 0≡⎕NEXISTS folder∘,¨''/hoo.aplf'' ''/hoo-0.aplf'''
      {}opts ⎕SE.Link.Create name folder
      assert'0 1 0≡⎕NEXISTS folder∘,¨''/goo.apla'' ''/goo.aplf'' ''/goo-0.aplf'''
      assert'1 0≡⎕NEXISTS folder∘,¨''/hoo.aplf'' ''/hoo-0.aplf'''
     
      ⍝ check forceextensions on-the-fly
      ⍝fn←'  ∇  r  ←  Dup  x' 'r  ←  x  x  ' '  ∇  '  ⍝ whitespace preserved (TODO : not for now)
      fn←' r←DupDup1 x' ' r←x x 1'  ⍝ whitespace not preserved because of ⎕NR
      {}(⊂fn)QNPUT folder,'/NotDupDup1.apla'
      assert'fn≡⎕NR name,''.DupDup1'''
      assert'0=⎕NC name,''.NotDupDup1'''
      assert'0 1≡⎕NEXISTS folder∘,¨''/NotDupDup1.apla'' ''/NotDupDup1.aplf'''
     
      ⍝ check file rename on-the-fly
      Breathe ⋄ Breathe ⋄ Breathe   ⍝ the previous operation requires extensive post-processing so that Notify handles the ⎕NMOVE triggered by the original Notify
      {}(folder,'/NotDupDup1.apla')#.SLAVE.⎕NMOVE(folder,'/NotDupDup1.aplf')
      assert'0 1≡⎕NEXISTS folder∘,¨''/NotDupDup1.apla'' ''/NotDupDup1.aplf'''
      assert'fn≡⎕NR name,''.DupDup1'''
      assert'0=⎕NC name,''.NotDupDup1'''
     
      ⍝ check apl rename on-the-fly
      Breathe
      var←⎕SE.Dyalog.Array.Serialise⍳2 3
      {}(⊂var)QNPUT(folder,'/NotDupDup1.aplf')1
      assert'0=⎕NC name,''.DupDup1'''     ⍝ ideal
      ⍝assert'fn≡⎕NR name,''.DupDup1'''   ⍝ arguable
      assert'(⍳2 3)≡',name,'.NotDupDup1'
      assert'0 1≡⎕NEXISTS folder∘,¨''/NotDupDup1.aplf'' ''/NotDupDup1.apla'''
      nl←(⍎name).⎕NL-⍳10
     
      ⍝ can't rename because it would clash
      Breathe
      var2←⎕SE.Dyalog.Array.Serialise⍳3 2
      {}(⊂var2)QNPUT(folder,'/NotDupDup1.aplf')1
      assert'nl≡(⍎name).⎕NL -⍳10'  ⍝ no change in APL
      assert'(⍳2 3)≡',name,'.NotDupDup1'
      assert'1 1≡⎕NEXISTS folder∘,¨''/NotDupDup1.apla'' ''/NotDupDup1.aplf'''
     
      ⍝ check that delete the supplementary file has no effect
⍝ BUG : doesn't work because link doesn't remember which files arrays were tied to
⍝      Breathe
⍝      {}QNDELETE folder,'/NotDupDup1.aplf'  ⍝ delete
⍝      assert'nl≡(⍎name).⎕NL -⍳10'
⍝      assert'(⍳2 3)≡',name,'.NotDupDup1'
      ⍝ but the bug isn't present if the first one is a function
      fn←' r←YetAnother' ' r←YetAnother'
      {}(⊂fn)QNPUT folder,'/YetAnother.aplf'
      assert'fn≡⎕NR name,''.YetAnother'''
      var←⎕SE.Dyalog.Array.Serialise⍳3 4
      {}(⊂var)QNPUT folder,'/YetAnother.apla'
      Breathe
      assert'fn≡⎕NR name,''.YetAnother'''
      {}QNDELETE folder,'/YetAnother.apla'
      Breathe
      assert'fn≡⎕NR name,''.YetAnother'''
     
      ⍝ Test that CaseCode and StripCaseCode functions work correctly
⍝ BUG Serialise/Deserialise doesn't work with rank 3
⍝      var←⍳2 3 4
      var←⍳5 6
      varfile←⎕SE.Link.CaseCode folder,'/HeLLo.apla'
      assert'varfile≡folder,''/HeLLo-15.apla'''
      assert'(folder,''/HeLLo.apla'')≡⎕SE.Link.StripCaseCode varfile'
⍝ BUG whitespace-sensitive code not possible
⍝      fn←'   r   ← OhMyOhMy  ( oh   my  )'   'r←  oh my   oh my'
      fn←' r←OhMyOhMy(oh my)' ' r←oh my oh my'
      fnfile←⎕SE.Link.CaseCode folder,'/OhMyOhMy.aplf'
      assert'fnfile≡folder,''/OhMyOhMy-125.aplf'''
      assert'(folder,''/OhMyOhMy.aplf'')≡⎕SE.Link.StripCaseCode fnfile'
     
      ⍝ Test that explicit Fix updates the right file
      assert'0 0≡⎕NEXISTS varfile fnfile'
      name'HeLLo'⎕SE.Link.Fix ⎕SE.Dyalog.Array.Serialise var
      name'OhMyOhMy'⎕SE.Link.Fix fn
      assert'var≡',name,'.HeLLo'
      assert'fn≡⎕NR''',name,'.OhMyOhMy'''
      assert'1 1≡⎕NEXISTS varfile fnfile'
     
      ⍝ Test that explicit Notify update the right name
      name Watch 0
      {}(⊂⎕SE.Dyalog.Array.Serialise var←⍳6 7)QNPUT varfile 1
      {}(⊂fn←' r←OhMyOhMy(oh my)' ' r←(oh my)(oh my)')QNPUT fnfile 1
      ⎕SE.Link.Notify'changed'varfile
      ⎕SE.Link.Notify'changed'fnfile
      assert'var≡',name,'.HeLLo'
      assert'fn≡⎕NR''',name,'.OhMyOhMy'''
      name Watch 1
     
      ⍝ Ditto for GetFileName and GetItemname
      assert'fnfile≡⎕SE.Link.GetFileName name,''.OhMyOhMy'''
      assert'(name,''.OhMyOhMy'')≡⎕SE.Link.GetItemName fnfile'
⍝ BUG doens't work for arrays and trad namespaces
⍝      assert'varfile≡⎕SE.Link.GetFileName name,''.HeLLo'''
⍝      assert'(name,''.HeLLo'')≡⎕SE.Link.GetItemName varfile'
     
      ⍝ Test that Expunge deletes the right file
      assert'1 1≡⎕NEXISTS varfile fnfile'
      assert'0∧.≠⎕NC''',name,'.HeLLo'' ''',name,'.OhMyOhMy'''
     
      z←⎕SE.Link.Expunge name∘,¨'.HeLLo' '.OhMyOhMy'
      assert'1 1≡z'
      assert'0 0≡⎕NEXISTS varfile fnfile'
      assert'0∧.=⎕NC''',name,'.HeLLo'' ''',name,'.OhMyOhMy'''
     
      {}⎕SE.Link.Break name
      CleanUp folder name
    ∇











    ∇ r←test_bugs(folder name);newbody;nr;opts;src;sub;unlikelyfile;unlikelyfn;unlikelyname;var;z
    ⍝ Github issues
      r←0
      ⍝ link issue #112 : cannot break an empty link
      name ⎕NS''
      ⎕MKDIR Retry⊢folder ⍝ folder must be non-existent
      z←⎕SE.Link.Create name folder
      'link issue #112'assert'~∨/''failed''⍷z'
      z←⎕SE.Link.Break name
      'link issue #112'assert'∨/''Unlinked''⍷z'
      ⎕EX name
     
      ⍝ link issue #118 : create link in #
      '#.unlikelyname must be non-existent'assert'0=⎕NC''#.unlikelyname'''
      (⊂unlikelyfn←' unlikelyname x' ' ⎕←x')⎕NPUT unlikelyfile←folder,'/unlikelyname.dyalog'
      z←⎕SE.Link.Create # folder
      'link issue #118'assert'1=≢⎕SE.Link.Links'
      'link issue #118'assert'~∨/''failed''⍷z'
      'link issue #118'assert'3=⎕NC''#.unlikelyname'''
      z←⎕SE.Link.Break #
      assert'0=≢⎕SE.Link.Links'
      ⎕EX'#.unlikelyname'
     
      z←⎕SE.Link.Create name folder
      assert'~∨/''failed''⍷z'
      assert'1=≢⎕SE.Link.Links'
      z←⎕SE.Link.Create(name,'.sub')folder
      assert'~∨/''failed''⍷z'
      assert'2=≢⎕SE.Link.Links'
      {}'{exact:1}'⎕SE.Link.Break name  ⍝ break only # and not children
      assert'1=≢⎕SE.Link.Links'
      {}⎕SE.Link.Break name  ⍝ break all chilren of #
      assert'0=≢⎕SE.Link.Links'
     
      ⍝ link issue #111 : ]link.break -all must work
      '⎕SE.unlikelyname must be non-existent'assert'0=⎕NC''⎕SE.unlikelyname'''
      z←⎕SE.Link.Create'⎕SE.unlikelyname'folder
      z←⎕SE.Link.Create'#.unlikelyname'folder
      assert'2=≢⎕SE.Link.Links'
      {}'{all:1}'⎕SE.Link.Break ⍬
      'link issue #111'assert'0=≢⎕SE.Link.Links'
      ⎕EX'⎕SE.unlikelyname' '#.unlikelyname'
     
      ⍝ link issue #117 : leave trailing slash in dir
      z←⎕SE.Link.Create name(folder,'/')
      'link issue #117'assert'1=≢⎕SE.Link.Links'
      'link issue #117'assert'~∨/''failed''⍷z'
     ⍝ link issue #116 : ⎕SE.Link.Refresh should not error when given a dir
      z←⎕SE.Link.Refresh folder
      'link issue #117'assert'∨/''Not linked''⍷z'
      z←⎕SE.Link.Refresh name
      assert'''Linked:''≡7↑z'
      assert'~∨/''failed''⍷z'
     
      ⍝ link issue #109 : fixing invalid function makes it disappear
      unlikelyname←name,'.unlikelyname' ⋄ newbody←'unlikelyname x;' '⎕←x'
      'link issue #109'assertError('name ''unlikelyname''⎕SE.Link.Fix newbody ')('Invalid source')
      'link issue #109'assert'unlikelyfn≡⊃⎕NGET unlikelyfile 1'    ⍝ changes not put back to file
      'link issue #109'assert'unlikelyfn≡⎕NR unlikelyname'         ⍝ fix failed
      'link issue #109'assert'unlikelyfile≡4⊃5179⌶ name,''.unlikelyname''' ⍝ still tied
     
      ⍝ link issue #108 : UCMD returned empty
      'link issue #108'assert'(⎕SE.UCMD '']Link.GetFileName '',unlikelyname)≡,⊂⎕SE.Link.GetFileName unlikelyname'
      {}⎕SE.Link.Break name
     
      opts←⎕NS ⍬
      opts.watch←'dir'
      opts.typeExtensions←↑(2 'myapla')(3 'myaplf')(4 'myaplo')(9.1 'myapln')(9.4 'myaplc')(9.5 'myapli')
      (⊂newbody)⎕NPUT unlikelyfile 1  ⍝ make it invalid source
      {}opts ⎕SE.Link.Create name folder
      assert'⎕SE.Link.Links.inFail≡,⊂,⊂unlikelyfile'
      name⍎'var←1 2 3'
      {}⎕SE.Link.Add name,'.var'
      'link issue #104 and #97'assert'(,⊂''1 2 3'')≡⊃⎕NGET (folder,''/var.myapla'') 1'
      z←⎕SE.Link.Expunge name,'.var'
      assert'(z≡1)∧(0=⎕NC name,''.var'')'  ⍝ variable effectively expunged
      'link issue #89 and #104'assert'~⎕NEXISTS folder,''/var.myapla'''
      {}⎕SE.Link.Break name ⋄ ⎕EX name ⋄ 3 ⎕NDELETE folder
     
      ⍝ rebuild a namespace from scratch
      (name,'.sub')⎕NS ⍬
      :For sub :In name∘,¨'' '.sub'
          ⍎sub,'.var←',⍕var←1 2 3 4
          (⍎sub).⎕FX nr←' r←foo r' ' r←r'
          (⍎sub).⎕FIX src←':Namespace script' ':EndNamespace'
      :EndFor
     
      RDFILES←RDNAMES←WRFILES←WRNAMES←⍬
      opts←⎕NS ⍬
      opts.beforeRead←'⎕SE.Link.Test.beforeReadAdd'
      opts.beforeWrite←'⎕SE.Link.Test.beforeWriteAdd'
     
      ⍝ TODO allow exporting variables ?
      {}opts ⎕SE.Link.Export name folder
      'link issue #21'assert'WRFILES ≡ folder∘,¨''/foo.aplf''  ''/script.apln''  ''/sub/foo.aplf''  ''/sub/script.apln'' '
      'link issue #21'assert'WRNAMES ≡ name∘,¨''.foo''  ''.script''  ''.sub.foo''  ''.sub.script''  '
      'link issue #21'assert'0∊⍴RDFILES,RDNAMES'
      WRFILES←WRNAMES←⍬
      ⎕EX name
     
      (⊂⍕var)⎕NPUT folder,'/var.apla'
      (⊂⍕var)⎕NPUT folder,'/sub/var.apla'
      {}opts ⎕SE.Link.Import name folder
      'link issue #68'assert'RDFILES ≡ folder∘,¨''/''  ''/sub/''  ''/foo.aplf''  ''/script.apln''  ''/sub/foo.aplf''  ''/sub/script.apln'' ''/sub/var.apla'' ''/var.apla'''
      'link issue #68'assert'RDNAMES ≡ name∘,¨''''  ''.sub''  ''.foo''  ''.script''  ''.sub.foo''  ''.sub.script'' ''.sub.var'' ''.var'''
      'link issue #68'assert'0∊⍴WRFILES,WRNAMES'
      {}⎕SE.Link.Break name
     
      ⍝ attempt to change a function to an operator
      {}⎕SE.Link.Create name folder
      name'foo'⎕SE.Link.Fix' r←(op foo) arg' ' r←op arg' ⍝ turn foo into an operator
      Breathe
      {}(folder,'/foo.aplo')#.SLAVE.⎕NMOVE folder,'/foo.aplf'
      Breathe
     
      z←⎕SE.Link.GetFileName 1 NSTREE name
      'link issue #128'assert'({⍵[⍋⍵]}z)≡({⍵[⍋⍵]} 1 NTREE folder)'
      z←⎕SE.Link.GetItemName 1 NTREE folder
      'link issue #128'assert'({⍵[⍋⍵]}z)≡({⍵[⍋⍵]} 1 NSTREE name)'
      z←⎕SE.Link.GetFileName'⎕SE.nope' '⎕SE.nope.nope',name∘,¨'.nope' '.sub.nope' '.nope.nope'
      z,←⎕SE.Link.GetItemName'/nope.nope' '/nope/nope.nope',folder∘,¨'/nope.nope' '/sub/nope.nope' '/nope/nope.nope'
      assert'∧/z≡¨⊂'''' '
     
      ⍝ attempt to refresh
      ⎕SE.UCMD'z←]link.refresh ',name
      'link issue #132 and #133'assert'∨/''Linked:''⍷z'
      {}⎕SE.Link.Break name
      assert'⎕SE∧.= {⍵.##}⍣≡⊢2⊃¨5177⌶⍬'  ⍝ no more links in #
     
      ⍝ attempt to export
      3 ⎕NDELETE folder
      {}⎕SE.UCMD']link.export ',name,' ',folder
      'link issue #131'assert'({⍵[⍋⍵]}1 NTREE folder)≡{⍵[⍋⍵]}folder∘,¨''/sub/'' ''/sub/foo.aplf''  ''/foo.aplo'' ''/script.apln'' ''/sub/script.apln'' '
     
      CleanUp folder name
    ∇

    ∇ r←beforeReadAdd args
      ⍝[1] Event name ('beforeRead')
      ⍝[2] Reference to a namespace containing link options for the active link.
      ⍝[3] Fully qualified filename that Link intends to read from
      ⍝[4] Fully qualified APL name of the item that Link intends to update
      ⍝[5] Name class of the APL item to be read
      r←1 ⋄ RDFILES,←args[3] ⋄ RDNAMES,←args[4]
    ∇
    ∇ r←beforeWriteAdd args
      ⍝[1] Event name ('beforeRead')
      ⍝[2] Reference to a namespace containing link options for the active link.
      ⍝[3] Fully qualified filename that Link intends to read from
      ⍝[4] Fully qualified APL name of the item that Link intends to update
      ⍝[5] Name class of the APL item to be read
      r←1 ⋄ WRFILES,←args[3] ⋄ WRNAMES,←args[4]
    ∇



      assert_create←{  ⍝ ⍺=newapl ⋄ ⍵=newfile
          _←assert(⍺/'new'),'var≡⍎subname,''.var'''
          _←assert(⍺/'new'),'foosrc≡⎕NR subname,''.foo'''
          _←assert(⍺/'new'),'nssrc≡⎕SRC ⍎subname,''.ns'''
          _←assert(⍵/'new'),'varsrc≡⊃⎕NGET (subfolder,''/var.apla'') 1'
          _←assert(⍵/'new'),'foosrc≡⊃⎕NGET (subfolder,''/foo.aplf'') 1'
          _←assert(⍵/'new'),'nssrc≡⊃⎕NGET (subfolder,''/ns.apln'') 1'
      }

    ∇ r←test_create(folder name);foosrc;newfoosrc;newnssrc;newvar;newvarsrc;nssrc;opts;subfolder;subname;var;varsrc;z
      r←0 ⋄ opts←⎕NS ⍬
     
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
      (⊂varsrc←⎕SE.Dyalog.Array.Serialise var←((⊂'hello')@2)¨⍳1 1 2)∘⎕NPUT¨folder subfolder,¨⊂'/var.apla'
      (⊂nssrc←':Namespace ns' ' ⍝ comment' 'foo←{''foo''⍵}' ':EndNamespace')∘⎕NPUT¨folder subfolder,¨⊂'/ns.apln'
      z←opts ⎕SE.Link.Create name folder
      assert'''Linked:''≡7↑z'
      assert'var∘≡¨⍎¨name subname,¨⊂''.var'''
      assert'foosrc∘≡¨⎕NR¨name subname,¨⊂''.foo'''
      assert'nssrc∘≡¨⎕SRC¨⍎¨name subname,¨⊂''.ns'''
      ⍝ watch=dir must reflect changes from files to APL
      {}(⊂newvarsrc←⎕SE.Dyalog.Array.Serialise newvar←((⊂'world')@2)¨var)QNPUT(subfolder,'/var.apla')1
      {}(⊂newfoosrc←(⊂' ⍝ new comment')@2⊢foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newnssrc←(⊂' ⍝ new comment')@2⊢nssrc)QNPUT(subfolder,'/ns.apln')1
      1 assert_create 1
      ⍝ watch=dir must not reflect changes from APL to files
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      Breathe  ⍝ breathe to ensure it's not reflected
      0 assert_create 1
      z←⎕SE.Link.Expunge name  ⍝ expunge whole linked namespace
      assert'(0=≢⎕SE.Link.Links)∧(z≡1)'
     
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
      Breathe ⍝ breathe to ensure it's not reflected
      0 assert_create 1
      {}⎕SE.Link.Expunge name
     
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
      {}⎕SE.Link.Add subname,'.var'  ⍝ can't add variable automatically when source=ns
      0 assert_create 0
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1
      1 assert_create 1
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      Breathe
      0 assert_create 1
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder
     
      ⍝ now try source=ns watch=ns
      opts.source←'ns' ⋄ opts.watch←'ns'
      {}opts ⎕SE.Link.Create name folder
      {}⎕SE.Link.Add subname,'.var'  ⍝ can't add variable automatically when source=ns
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
      {}⎕SE.Link.Add subname,'.var'  ⍝ can't add variable automatically when source=ns
      1 assert_create 1
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      Breathe
      0 assert_create 1
      subname'var'⎕SE.Link.Fix newvarsrc
      subname'foo'⎕SE.Link.Fix newfoosrc
      subname'ns'⎕SE.Link.Fix newnssrc
      Breathe
      1 assert_create 1
      {}(⊂varsrc)QNPUT(subfolder,'/var.apla')1
      {}(⊂foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂nssrc)QNPUT(subfolder,'/ns.apln')1
      Breathe
      1 assert_create 0
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder
     
     
      CleanUp folder name
    ∇

    :EndSection  test_functions










    :Section Setup and Utils

    ∇ r←Setup(folder name)
      r←'' ⍝ Run will abort if empty
     
      ⍝⎕PW⌈←300
      ⎕SE.Link.FileSystemWatcher.DEBUG←1 ⍝ Turn on event logging
     
      :If ~##.U.CanWatch
          ⎕←'Unable to run Link.Tests - .Net is required to test the FileSystemWatcher'
          →0
      :EndIf
     
      :If 0=⎕NC'⎕SE.Link.DEBUG' ⋄ ⎕SE.Link.DEBUG←0 ⋄ :EndIf
      {}⎕SE.UCMD'udebug ','off' 'on'⊃⍨0 1⍸⎕SE.Link.DEBUG
      ⍝⎕SE.Link.DEBUG←1 ⍝ 1 = Trace, 2 = Stop on entry
     
      :If 0≠⎕NC'⎕SE.Link.Links'
      :AndIf 0≠≢⎕SE.Link.Links
          Log'Please break all links and try again.'
          Log ⎕SE.UCMD'link.list'
          Log'      ]Link.Break -all    ⍝ to break all links'
          →0
      :EndIf
     
      :If 0≠⎕NC name
          ⍝⎕←name,' exists. Expunge? [Y|n]'
          ⍝:If 'yYjJ1 '∊⍨⊃⍞~' '
          ⎕EX name
          ⍝:Else
          ⍝    ⎕→name,' must be non-existent.'
          ⍝    →0
          ⍝:EndIf
      :EndIf
      :If ~0∊⍴folder  ⍝ specific folder
          folder←∊1 ⎕NPARTS folder,(0=≢folder)/(739⌶0),'/linktest'
          :If ⎕NEXISTS folder
              ⎕←folder,' exists. Clean it out? [Y|n] '
              :If 'yYjJ1 '∊⍨⊃⍞~' '
                  3 ⎕NDELETE Retry⊢folder
              :Else
                  ⎕→'Directory must be non-existent.'
                  →0
              :EndIf
          :EndIf
      :Else  ⍝ generate a new directory - avoids prompting for deletion
          folder←CreateTempDir 0
      :EndIf
     
      :If USE_ISOLATES
          :If 9.1≠⎕NC⊂'#.isolate'
              #.⎕CY'isolate.dws'
          :EndIf
          {}#.isolate.Reset 0  ⍝ in case not closed properly last time
          {}#.isolate.Config'processors' 1 ⍝ Only start 1 slave
          #.SLAVE←#.isolate.New''
          QNDELETE←{⍺←⊢ ⋄ ⍺ #.SLAVE.⎕NDELETE ⍵}
          QNPUT←{⍺←⊢ ⋄ ⍺ #.SLAVE.⎕NPUT ⍵ ⋄ ⎕DL 0.001}  ⍝ ensure QNPUTS are not too tight for filewatcher
      :Else
          #.SLAVE←#.⎕NS''
          QNDELETE←{⍺←⊢ ⋄ ⍺ NDELETE ⍵}
          QNPUT←{⍺ NPUT ⍵ ⋄ ⎕DL 0.001}
      :EndIf
      ⍝QNMOVE←#.SLAVE.⎕NMOVE
      ⍝QNCOPY←#.SLAVE.⎕NCOPY
      ⍝QNGET←#.SLAVE.⎕NGET
      ⍝QMKDIR←#.SLAVE.⎕MKDIR
     
      r←folder
    ∇

    ∇ UnSetup
      :If USE_ISOLATES
          z←4=#.SLAVE.(2+2) ⍝ Make sure it finished what it was doing
          {}#.isolate.Reset 0
          ⎕EX'#.SLAVE'
      :EndIf
    ∇

    ∇ CleanUp(folder name);z;m
    ⍝ Tidy up after test
      ⍝⎕SE.Link.DEBUG←0
      z←⎕SE.Link.Break'#.',name
      assert'0=≢⎕SE.Link.Links'
      z←⊃¨5176⌶⍬ ⍝ Check all links have been cleared
      :If ∨/m←((≢folder)↑¨z)∊⊂folder
          ⎕←'*** Links not cleared:'
          ⎕←⍪m/z
      :EndIf
      3 ⎕NDELETE folder
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

    ∇ {r}←{x}(F Retry)y;c;n
      :If 900⌶⍬
          x←⊢
      :EndIf
      :For n :In ⍳c←5  ⍝ number of retries
          :Trap 0
              r←x F y
              :Return
          :Else
              ⎕SIGNAL(n=c)/⊂⎕DMX.(('EN'EN)('Message'Message))
          :EndTrap
          Breathe  ⍝ pause between retries
      :EndFor
    ∇

    ∇ Breathe
    ⍝ Breathe is sometimes required to allow FileSystemWatcher events which are still in the
    ⍝ queue to be processed. They can sometimes exist despite asserts having succeeded
    ⍝ Without Breathe, such events can run in parallel with and interfere with the next test
    ⍝ causing "random" (timing-dependent) failures
    ⍝ Also sometimes the FSW has create+change events on file write,
    ⍝ producing two callbacks to notify, the first one making assert succeeds,
    ⍝ then the second one conflicting with whichever code is run after the assert (e.g. a ⎕FIX which would be undone by the pending second Notify)
      ⎕DL PAUSE_TIME
    ∇

      assertMsg←{
          msg←⍎⍵
          ('assertion failed: "',msg,'" instead of "',⍺,'" from: ',⍵)⎕SIGNAL 11/⍨~∨/⍺⍷msg
      }

    ∇ {txt}←{msg}assertError args;errmsg;errno;expr
      :If 900⌶⍬ ⋄ msg←⊢ ⋄ :EndIf
      (expr errmsg errno)←(⊆args),(≢⊆args)↓'' ''⎕SE.Link.U.ERRNO
      :Trap errno
          {}⍎expr
          txt←msg assert'0'
      :Else
          txt←msg assert'∨/errmsg⍷⊃⎕DM'  ⍝ always true if errmsg≡''
      :EndTrap
    ∇
    ∇ {txt}←{msg}assert args;clean;expr;maxwait;end;timeout;txt
      ⍝ Asynchronous assert: We don't know how quickly the FileSystemWatcher will do something
     
      :If STOP_TESTS
          ⎕←'STOP_TESTS detected...'
          (1+⊃⎕LC)⎕STOP'assert'
      :EndIf
     
      (expr clean)←2↑(⊆args),⊂''
      end←(1000×ASSERT_TIME)+3⊃⎕AI
      timeout←0
     
      :While 0∊{0::0 ⋄ ⍎⍵}expr
          Breathe
      :Until timeout←end<3⊃⎕AI
     
      :If 900⌶⍬ ⍝ Monadic
          msg←'assertion failed'
      :EndIf
      :If ~timeout ⋄ txt←'' ⋄ :Return ⋄ :EndIf
     
      txt←msg,': ',expr,' ⍝ at ',(2⊃⎕XSI),'[',(⍕2⊃⎕LC),']'
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




    ∇ {r}←{flag}NDELETE file;type;name;names;types;n;t
     ⍝ Cover for ⎕NERASE / ⎕NDELETE while we try to find out why it makes callbacks fail
     ⍝ Superseeded by #.SLAVE.⎕NDELETE
     ⍝ re-superseeded by QNDELETE
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
     ⍝ Cover for ⎕NPUT -
     ⍝ Superseeded by #.SLAVE.⎕NPUT when USE_ISOLATES←1
     ⍝ re-superseeded by QNPUT
     
      (file overwrite)←2↑(⊆args),1
      r←≢bytes←⎕UCS'UTF-8'⎕UCS∊(⊃text),¨⊂⎕UCS 13 10
      :If (⎕NEXISTS file)∧overwrite
          tn←file ⎕NTIE 0 ⋄ 0 ⎕NRESIZE tn ⋄ bytes ⎕NAPPEND tn ⋄ ⎕NUNTIE tn ⋄ ⎕DL 0.01
      :Else
          tn←file ⎕NCREATE 0 ⋄ bytes ⎕NAPPEND tn ⋄ ⎕NUNTIE tn ⋄ ⎕DL 0.01
      :EndIf
    ∇


    ∇ files←dirs NTREE folder;types
      (files types)←0 1 ⎕NINFO⍠1⍠'Recurse' 1⊢folder,'/*'
      files←files,¨(types=1)/¨'/'
      files←(dirs∨types≠1)/files  ⍝ dirs=0 : exclude directories
    ∇

    ∇ names←trad NSTREE ns;mask;pre;ref;refs;subns;tradns
      ref←⍎ns ⋄ pre←ns,'.'  ⍝ reference to namespce ⋄ prefix to names
      names←pre∘,¨ref.(⎕NL-⍳10)    ⍝ all names
      :If ~0∊⍴subns←ref.(⎕NL ¯9.1)   ⍝ sub-namespaces
          refs←ref⍎¨subns
      :AndIf ∨/mask←{0::1 ⋄ 0⊣⎕SRC ⍵}¨refs  ⍝ trad ns
          tradns←pre∘,¨mask/subns
          :If ~trad ⋄ names~←tradns ⋄ :EndIf  ⍝ trad=0 : exclude trad namespaces
          names,←⊃,/trad NSTREE¨tradns
      :EndIf
    ∇

    ∇ nsname Watch watch;fsw;link
    ⍝ pause/resume file watching
      :If 0∊⍴link←⎕SE.Link.U.LookupRef(⍎nsname)
          ⎕SIGNAL 11
      :EndIf
      :If 9=⎕NC'link.fsw.QUEUE'
          fsw←(⍕link.fsw.QUEUE)⎕WG'Data'
      :Else
          fsw←link.fsw
      :EndIf
      :If ~0∊⍴fsw
          fsw.EnableRaisingEvents←watch
      :EndIf
    ∇

    ∇ dir←CreateTempDir create;i;prefix;tmp
      prefix←(739⌶0),'/linktest-' ⋄ i←0
      :Repeat ⋄ dir←prefix,⍕i←i+1
      :Until ~⎕NEXISTS dir
      :If create ⋄ 2 ⎕MKDIR dir ⋄ :EndIf
    ∇
    ∇ dirs←DeleteTempDirs;dir;dirs;list
      3 ⎕NDELETE⊃⎕NINFO⍠1⊢'\d+'⎕R'*'⊢CreateTempDir
    ∇


    :EndSection Setup and Utils













    :Section Benchmarks

    ∇ clear build_large folder;Body;Constants;Lines;Names;Primitives;body;depth;dirs;files;i;maxdepth;names;ndirs;nfiles;nlines;primitives
    ⍝ A large company has about 1e5 files in about 1e4 directories - file sizes unknown
    ⍝ that correspondings roughly to ndirs←nfiles←10 and maxdepth←4
    ⍝ use small number of lines to increase the link overhead and measure it more accurately
      :If clear ⋄ 3 ⎕NDELETE folder ⋄ 3 ⎕MKDIR folder   ⍝ clear folder
      :ElseIf ⎕NEXISTS folder ⋄ 'folder exists'⎕SIGNAL 22   ⍝ folder must not exist
      :EndIf
      ndirs←10 ⋄ maxdepth←3 ⍝ number of subdirs per depth level - maximum depth level
      nfiles←10     ⍝ number of files per subdir
      nlines←0    ⍝ number of lines per file
      Names←{↓⎕A[?⍵ 10⍴26]}  ⍝ random names
      Constants←{⍕¨↓?⍵ 10⍴100}  ⍝ random constants
      primitives←'¨<≤=≥>≠∨∧×÷?⍵∊⍴~↑↓⍳○*←→⊢⍺⌈⌊∘⎕⍎⍕⊂⊃∩∪⊥⊤|⍀⌿⌺⌶⍒⍋⌽⍉⊖⍟⍱⍲!⌹⍷⍨↑↓⍸⍣⍞⍬⊣⍺⌊⍤⌸⌷≡≢⊆∩⍪⍠()[]@-'
      Primitives←primitives∘{⍺[?⍵⍴≢⍺]}   ⍝ random primitives
      Lines←{   ⍝ ⍵ random lines
          ,/(Primitives ⍵),(Names ⍵),(Primitives ⍵),(Constants ⍵),'⍝',[1.5](Names ⍵)
      }
      body←Lines nlines
      Body←body∘{(⊂⍵),⍺} ⍝ ⍵ is list of names
      dirs←⊂folder ⋄ files←⍬
      :For depth :In ⍳maxdepth
          ⍝ create subdirs
          dirs←(ndirs/dirs,¨'/'),¨Names ndirs×≢dirs
          ⍝ create files
          files,←(nfiles/dirs,¨'/'),¨Names nfiles×≢dirs
      :EndFor
      files,¨←⊂'.aplf'
      names←{2⊃⎕NPARTS ⍵}¨files
      {}3 ⎕MKDIR dirs
      {}names{(⊂Body ⍺)⎕NPUT ⍵ 1}¨files
    ∇

    ∇ (time dirs files)←{opts}bench_large folder;clear;fastload;filetype;name;opts;profile;temp;time
    ⍝ times with (ndirs nfiles nlines maxdepth)←10 10 0 3 → (dirs files)≡1110 11100
    ⍝ v2.0:        fastLoad=1:1500 ⋄ fastLoad=0:N/A
    ⍝ v2.1-alpha1: fastLoad=1:1800 ⋄ fastLoad=0:3500
    ⍝ v2.1.0:      fastLoad=1:650  ⋄ fastLoad=0:1250
      :If 900⌶⍬ ⋄ opts←⍬ ⋄ :EndIf
      (fastload profile clear)←opts,(≢opts)↓1 0 0
      name←'#.largelink'
      :If temp←0∊⍴folder
          folder←CreateTempDir 0
          ⎕←'building ',folder,' ...'
          clear build_large folder
      :EndIf
      filetype←⊃1 ⎕NINFO⍠1⍠'Recurse' 1⊢folder,'/*'
      dirs←filetype+.=1 ⋄ files←filetype+.=2
      opts←⎕NS ⍬
      opts.source←'dir'
      opts.fastLoad←fastload
      ⎕←'linking ',name,' ...'
      :If profile ⋄ ⎕PROFILE¨'clear' 'start' ⋄ :EndIf
      time←3⊃⎕AI
      opts ⎕SE.Link.Create name folder
      time←(3⊃⎕AI)-time
      :If profile ⋄ ⎕PROFILE'stop' ⋄ :EndIf
      ⍝⎕←⎕SE.Link.List name
      ⎕←'cleaning up...'
      ⎕EX name
      {}⎕SE.Link.Break name
      :If temp
          ⎕DL 1
          3 ⎕NDELETE folder
      :EndIf
    ∇

    :EndSection Benchmarks



:EndNamespace
