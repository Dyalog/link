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

    USE_ISOLATES←1     ⍝ Boolean : 0=handle files locally ⋄ 1=handle files in isolate
    ⍝ the isolate is to off-load this process from file operations give it more room to run filewatcher callbacks
    ⍝ the namespace will be #.SLAVE, and only file operations that trigger a filewatcher callback need to be run in that namespace
    ⍝ unfortunately isolates have to be put in # because they copy DRC into #, and therefore hold references to #, and can't be held in ⎕SE at the cost of preventing )CLEAR.

    NAME←'#.linktest'  ⍝ namespace used by link tests
    FOLDER←''          ⍝ empty defaults to default to a new directory in (739⌶0)

    ASSERT_DORECOVER←0 ⍝ Attempt recovery if expression provided
    ASSERT_ERROR←1     ⍝ Boolean : 1=assert failures will error and stop ⋄ 0=assert failures will output message to session and keep running
    STOP_TESTS←0       ⍝ Can be used in a failing thread to stop the action

    ∇ {ok}←{debug}Run test_filter;all;aplv;core;crawler;dnv;docrawler;dotnet;folder;ok;opts;showmsg;slow;test;tests;time;udebug;z;rep
    ⍝ Do (⎕SE.Link.Test.Run'all') to run ALL the Link Tests, including slow ones
    ⍝ Do (⎕SE.Link.Test.Run'') to run the basic Link Tests
      :If (~0∊⍴test_filter)∧(⍬≡0⍴test_filter)  ⍝ right arg prepended with a number
          rep←⊃test_filter ⋄ test_filter↓⍨←1
      :Else ⋄ rep←1
      :EndIf
      test_filter←,⊆,test_filter
      docrawler←⎕SE.Link.Watcher.CRAWLER
      tests←{((5↑¨⍵)∊⊂'test_')⌿⍵}'t'⎕NL ¯3 ⍝ ALL tests
      slow←'test_threads' 'test_watcherror'  ⍝ slow tests
      :If all←(⊂'all')∊test_filter  ⍝ all tests - nothing to do
      :ElseIf (0∊⍴test_filter)∨(test_filter≡,⊂'') ⋄ tests~←slow  ⍝ basic tests
          Log'Not running slow tests:',(⍕slow),' - use (',(⊃⎕XSI),' ''all'') to run all tests'  ⍝ remove slow tests
      :Else ⋄ tests/⍨←∨⌿1∊¨(test_filter)∘.⍷tests  ⍝ selected tests
      :EndIf
      tests←⊃,/rep⍴⊂tests    ⍝ repeat tests if requested
      :If 0=⎕SE.Link.DEBUG ⋄ Log'Running:',⍕tests ⋄ :EndIf
      :If docrawler>×all ⋄ Log'Not running tests with file crawler - use (',(⊃⎕XSI),' ''all'') to run all tests' ⋄ :EndIf
      :If ok←0≠≢folder←Setup FOLDER NAME
          ⍝ touch ⎕SE.Link settings
          :If 0=⎕NC'⎕SE.Link.DEBUG' ⋄ ⎕SE.Link.DEBUG←0 ⋄ :EndIf
          :If 0=⎕NC'debug' ⋄ debug←⎕SE.Link.DEBUG ⋄ :EndIf
          (⎕SE.Link.DEBUG debug)←(debug ⎕SE.Link.DEBUG)
          udebug←4↓,⎕SE.UCMD']udebug ','off' 'on'⊃⍨0 1⍸⎕SE.Link.DEBUG
          (showmsg ⎕SE.Link.U.SHOWMSG)←(⎕SE.Link.U.SHOWMSG)(0<⎕SE.Link.DEBUG)  ⍝ do not show messages if not debugging
          (dotnet crawler)←⎕SE.Link.Watcher.(DOTNET CRAWLER)
     
          time←⎕AI[3] ⋄ ok←1
          :For test :In tests
              :If 0<⎕SE.Link.DEBUG ⋄ Log'Running: ',test ⋄ :EndIf
              :If docrawler∧×all  ⍝ test with file watcher
                  ⎕SE.Link.Watcher.(CRAWLER DOTNET)←0 dotnet
              :EndIf
⍝ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ⍝ run the test_* function
              ok∧←(⍎test)folder NAME    ⍝ ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
⍝ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
              :If docrawler∧×all ⍝ test with file crawler
                  ⎕SE.Link.Watcher.(CRAWLER DOTNET)←1 0
⍝ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ⍝ run the test_* function
                  ok∧←(⍎test)folder NAME    ⍝ ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
⍝ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
              :EndIf
          :EndFor
          time←⎕AI[3]-time
          UnSetup
          ⍝ restore ⎕SE.Link settings
          {}⎕SE.UCMD']udebug ',udebug
          ⎕SE.Link.DEBUG←debug
          ⎕SE.Link.U.SHOWMSG←showmsg
          ⎕SE.Link.Watcher.(DOTNET CRAWLER)←(dotnet crawler)
          ⍝ display results
          dnv←{0::'none' ⋄ ⎕USING←'' ⋄ System.Environment.Version.(∊⍕¨Major'.'(|MajorRevision))}''
          core←(1+⎕SE.Link.Watcher.DOTNETCORE)⊃'Framework' 'Core'
          aplv←{⍵↑⍨¯1+2⍳⍨+\'.'=⍵}2⊃'.'⎕WG'APLVersion'
          opts←' (USE_ISOLATES: ',(⍕USE_ISOLATES),', USE_NQ: ',(⍕⎕SE.Link.Watcher.USE_NQ),')'
          Log(⍕≢tests),' test[s] passed OK in',(1⍕time÷1000),'s with Dyalog ',aplv,' and .Net',core,' ',dnv,opts
      :EndIf
     
    ∇

    :EndSection Main entry point and global settings






    :Section test_functions

    ∇ ok←test_flattened(folder name);main;dup;opts;ns;goo;goofile;dupfile;foo;foofile;z;_
     ⍝ Test the flattened scenario
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
      z←opts ⎕SE.Link.Create name folder
     
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
     
      CleanUp folder name
      ok←1
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










    ∇ ok←test_failures(folder name);debug;err;errf;erru;mod;names;opts;warn;z
      assertError('⎕SE.Link.Export''',name,'.ns_not_here'' ''',folder,'''')'Source not found'
      assertError('⎕SE.Link.Import''',name,''' ''',folder,'/dir_not_here''')'Source not found'
     
      z←⎕SE.Link.Break'#'
      assert'∨/''No active links''⍷z'
     
      opts←⎕NS''
      opts.source←'ns'
      assertError('opts ⎕SE.Link.Create''',name,'.ns_not_here'' ''',folder,'''')'Source namespace not found'
     
      opts←⎕NS''
      opts.source←'dir'
      assertError('opts ⎕SE.Link.Create''',name,''' ''',folder,'/dir_not_here''')'Source directory not found'
     
      name ⎕NS'' ⋄ 3 ⎕MKDIR folder
      opts←⎕NS'' ⋄ opts.source←'dir'
      name⍎'var←1 2 3'
      'link issue #182'assertError('opts ⎕SE.Link.Create ',⍕Stringify¨name folder)('Destination namespace not empty: ',name)
      ⎕EX name,'.var' ⋄ 3 ⎕NDELETE folder
     
      opts.source←'ns'
      ⍝ link issue #162 test unknown modifiers and invalid values - ⎕EN is almost impossible to predict : 911 when ⎕SE.Link.DEBUG←1, 701, 702 or 704 when ⎕SE.Link.DEBUG←0
      'link issue #162'assertError('⎕SE.UCMD '']link.create -BADMOD=BADVAL '',name,'' "'',folder,''"'' ')'unknown modifier' 0
      'link issue #162'assertError'''{BADMOD:1 2 3}''⎕SE.Link.Create name folder' 'Unknown modifier'
      :For mod :In 'source' 'watch' 'flatten' 'caseCode' 'forceExtensions' 'forceFilenames' 'fastLoad' 'beforeWrite' 'beforeRead' 'getFilename'
          :Select mod
          :CaseList 'source' 'watch' ⋄ err←1 ⋄ erru←819⌶errf←'Invalid value'
          :CaseList 'flatten' 'caseCode' 'forceExtensions' 'forceFilenames' 'fastLoad' ⋄ err←1 ⋄ erru←'no value allowed' ⋄ errf←'Invalid value'
          :CaseList 'beforeWrite' 'beforeRead' 'getFilename' ⋄ err←0 ⋄ erru←errf←'must be the name of an APL function'
          :EndSelect
          :If err  ⍝ UCMD expected to error (misusage of the UCMD syntax)
              'link issue #162'assertError('⎕SE.UCMD '']link.create -'',(819⌶mod),''=BADVAL '',name,'' "'',folder,''"'' ')erru 0
          :Else ⍝ Error in link - UCMD must not error and return a shorter message (link issue #217)
              z←⎕SE.UCMD']link.create -',(819⌶mod),'=BADVAL ',name,' "',folder,'"'
              'link issue #162'assert'∨/erru⍷z'
          :EndIf
          'link issue #162'assertError('''{',mod,':''''BADVAL''''}''⎕SE.Link.Create name folder')errf
      :EndFor
      ⍝ Mantis 18638 - handle lost source
      3 ⎕MKDIR folder
      (⊂':Class lostclass' ':EndClass')⎕NPUT(folder,'/lostclass.aplc')1
      2(⍎name).⎕FIX'file://',folder,'/lostclass.aplc'
      ⎕NDELETE folder,'/lostclass.aplc'
      (warn ⎕SE.Link.U.WARN)←(⎕SE.Link.U.WARN 1) ⋄ ⎕SE.Link.U.WARNLOG/⍨←0
      z←opts ⎕SE.Link.Create name folder
      'Mantis 18638'assert'(∨/''failed''⍷z)∧(∨/''',name,'.lostclass''⍷z)'
      (⍎name).⎕EX'lostclass'
      'Mantis 18638'assert'~0∊⍴(''File not found: '',folder,''/lostclass.aplc'')⎕S ''\0''⊢⎕SE.Link.U.WARNLOG'
      ⎕SE.Link.U.WARN←warn
      assertError('name ''foo'' ⎕SE.Link.Fix '';;;'' '';;;'' ')('Invalid source')
      assertError('name ''foo'' ⎕SE.Link.Fix '''' ')('No source')
      assertError('name ''¯1'' ⎕SE.Link.Fix '''' ')('Invalid name')
      assertError(' ''¯1'' ''foo'' ⎕SE.Link.Fix '''' ')('Not a namespace')
     
      z←⎕SE.Link.Break'#'
      assert'∨/''Not linked:''⍷z'
      z←⎕SE.Link.Break'#.unlikelyname'
      assert'∨/''Not found:''⍷z'
     
      z←name'foo'⎕SE.Link.Fix,⊂'foo←{''foo'' arg}'
      assert'z≡1'
      z←'#' 'foo'⎕SE.Link.Fix,⊂'foo←{''foo'' arg}'
      assert'z≡0'
      Breathe ⍝ windows needs some time to clean up the file ties
     
      {}⎕SE.Link.Break name ⋄ ⎕EX name
     
      3 ⎕MKDIR folder,'/sub/.git/info'
      {}(⊂,⊂'goo←{''goo'' arg}')QNPUT(folder,'/sub/goo.aplf')1
      {}(⊂'hoo arg' '⎕←''hoo'' arg')QNPUT(folder,'/sub/.git/info/hoo.aplf')1
      {}(⊂'joo arg' '⎕←''joo'' arg')QNPUT(folder,'/.joo.aplf')1
      {}(⊂'koo arg' '⎕←''koo'' arg')QNPUT(folder,'/koo.tmp')1
      (warn ⎕SE.Link.U.WARN)←(⎕SE.Link.U.WARN 1) ⋄ ⎕SE.Link.U.WARNLOG/⍨←0
      z←⎕SE.Link.Create name folder
      assert'~∨/''failed''⍷z'
      names←'#.linktest.foo' '#.linktest.sub' '#.linktest.sub.goo'
      'link issue #156'assert'({⍵[⍋⍵]}names)≡({⍵[⍋⍵]}1 NSTREE name)'
     
      {}(⊂,⊂'foo2←{''foo2'' arg}')QNPUT(folder,'/foo2.aplf')1
      {}(⊂,⊂'goo2←{''goo2'' arg}')QNPUT(folder,'/sub/goo2.aplf')1
      {}(⊂'hoo2 arg' '⎕←''hoo2'' arg')QNPUT(folder,'/sub/.git/info/hoo2.aplf')1
      {}(⊂'joo2 arg' '⎕←''joo2'' arg')QNPUT(folder,'/.joo2.aplf')1
      {}(⊂'koo2 arg' '⎕←''koo2'' arg')QNPUT(folder,'/koo2.tmp')1
      names,←'#.linktest.foo2' '#.linktest.sub.goo2'
      'link issue #156'assert'({⍵[⍋⍵]}names)≡({⍵[⍋⍵]}1 NSTREE name)'
     
      {}QNDELETE(folder,'/foo2.aplf')
      {}QNDELETE(folder,'/sub/goo2.aplf')
      {}QNDELETE(folder,'/sub/.git/info/hoo2.aplf')
      {}QNDELETE(folder,'/.joo2.aplf')
      {}QNDELETE(folder,'/koo2.tmp')
      names↓⍨←¯2
      'link issue #156'assert'({⍵[⍋⍵]}names)≡({⍵[⍋⍵]}1 NSTREE name)'
      'link issue #158'assert'0=≢⎕SE.Link.U.WARNLOG'
     
      ⎕SE.Link.U.WARN←warn
      {}⎕SE.Link.Break name
     
      z←⎕SE.UCMD']Link.Create ',name,' ',folder
      'link issue #217'assert'⊃''⎕SE.Link.Create: Cannot link a non-empty namespace to a non-empty directory''⍷z'
     
      CleanUp folder name
      ok←1
    ∇







    ∇ ok←test_export(folder name);ExportCmd;arrays;cmd;foosrc;foosrc2;nssrc;nssrc2;opts;ref;subref;varsrc;z
      ref←⍎name ⎕NS''
      varsrc←⎕SE.Dyalog.Array.Serialise ref.var←(2 3 4⍴○⍳100)(5 6⍴⎕A)
      2 ref.⎕FIX foosrc←,¨'     ∇ res  ←foo arg ; local' 'res←''foo''   arg' '∇'
      2 ref.⎕FIX nssrc←,¨'  :Namespace ns' 'where←''ns'' ' ':EndNamespace'
      :If ~⎕SE.Link.U.IS181 ⋄ foosrc←ref.⎕NR'foo' ⋄ :EndIf  ⍝ Dyalog v19.0 can preserve source !
      subref←⍎(name,'.sub')⎕NS''
      subref.(var1 var2 var3 var4)←'VAR1' 'VAR2' 'VAR3' 'VAR4'
     
      z←⎕SE.Link.Export name folder
      assert'~∨/''failed''⍷z'
      assert'⎕NEXISTS ''',folder,''''
      3 ⎕NDELETE folder ⋄ 3 ⎕MKDIR folder
      (⊂'This is total garbage !!!!!;;;;')⎕NPUT folder,'/garbage.ini'
      z←⎕SE.Link.Export name folder
      'link issue #175'assert'~∨/''failed''⍷z'
      assert'foosrc≡⊃⎕NGET ''',folder,'/foo.aplf'' 1'
      assert'nssrc≡⊃⎕NGET ''',folder,'/ns.apln'' 1'
      assert'1=1⎕NINFO ''',folder,'/sub'''
      assert'~⎕NEXISTS ''',folder,'/var.apla'''
      2 ref.⎕FIX foosrc2←,¨'     ∇ res  ←foo arg ; local' 'res←''foo2''   arg' '∇'
      2 ref.⎕FIX nssrc2←,¨'  :Namespace ns' 'where←''ns2'' ' ':EndNamespace'
      :If ~⎕SE.Link.U.IS181 ⋄ foosrc2←ref.⎕NR'foo' ⋄ :EndIf
      'link issue #175'assertError'z←⎕SE.Link.Export name folder' 'Files already exist'
      opts←⎕NS ⍬ ⋄ opts.overwrite←1
      z←opts ⎕SE.Link.Export name folder
      'link issue #175'assert'~∨/''failed''⍷z'
      assert'foosrc2≡⊃⎕NGET ''',folder,'/foo.aplf'' 1'
      assert'nssrc2≡⊃⎕NGET ''',folder,'/ns.apln'' 1'
      assert'~⎕NEXISTS ''',folder,'/var.apla'''
     
      3 ⎕NDELETE folder ⋄ 2 ref.⎕FIX foosrc
      z←⎕SE.Link.Export(name,'.foo')folder
      'link issue #79'assert'~∨/''failed''⍷z'
      'link issue #79'assert'foosrc≡⊃⎕NGET ''',folder,'/foo.aplf'' 1'
      z←⎕SE.Link.Export(name,'.foo')(folder,'/foo')  ⍝ check that destination is always interpreted as directory
      'link issue #79'assert'~∨/''failed''⍷z'
      'link issue #79'assert'foosrc≡⊃⎕NGET ''',folder,'/foo/foo.aplf'' 1'
      z←⎕SE.Link.Export(name,'.foo')(folder,'/foo2.aplf')
      'link issue #79'assert'~∨/''failed''⍷z'
      'link issue #79'assert'foosrc≡⊃⎕NGET ''',folder,'/foo2.aplf'' 1'
      2 ref.⎕FIX foosrc2
      assertError'⎕SE.Link.Export(name,''.foo'')(folder,''/foo2.aplf'')'(⎕SE.Link.U.WinSlash folder,'/foo2.aplf')
      opts.overwrite←1
      z←opts ⎕SE.Link.Export(name,'.foo')(folder,'/foo2.aplf')
      'link issue #79'assert'~∨/''failed''⍷z'
      'link issue #79'assert'foosrc2≡⊃⎕NGET ''',folder,'/foo2.aplf'' 1'
     
      3 ⎕NDELETE folder ⋄ 2 ref.⎕FIX foosrc
      ExportCmd←{'Link.Export ',(⍺/'-overwrite'),' ',⍵,' ',name,' ',folder}∘{⍵≡0:'' ⋄ ⍵≡1:'-arrays' ⋄ '-arrays=',∊⍵,[1.5]','}
      z←ref.{⎕SE.UCMD ⍵}0 ExportCmd 0
      'link issue #37'assert'~∨/''failed''⍷z'
      'link issue #37'assert'0 0 0 0≡⎕NEXISTS (folder,''/sub/'')∘,¨''var1.apla'' ''var2.apla'' ''var3.apla'' ''var4.apla'''
      cmd←0 ExportCmd arrays←(name,'.sub.var1')('sub.var2')('⎕THIS.sub.##.sub.var3')('NOT_FOUND')('sub.⎕IO')('sub.##.sub.⎕THIS.⎕ML')
      ⍝assertError'z←ref.{⎕SE.UCMD ⍵}cmd' 'Files already exist' 0      ⍝ UCMD may throw nearly any error number
      z←ref.{⎕SE.UCMD ⍵}cmd  ⍝ link issue #217 - UCMD must not error
      assert '⊃''⎕SE.Link.Export: Files already exist:''⍷z' 
      z←ref.{⎕SE.UCMD ⍵}1 ExportCmd 1
      'link issue #37'assert'~∨/''failed''⍷z'
      'link issue #37'assert'1 1 1 1 0 0≡⎕NEXISTS (folder,''/sub/'')∘,¨''var1.apla'' ''var2.apla'' ''var3.apla'' ''var4.apla'' ''⎕IO.apla'' ''⎕ML.apla'' '
      3 ⎕NDELETE folder
      z←ref.{⎕SE.UCMD ⍵}0 ExportCmd arrays
      'link issue #37'assert'~∨/''failed''⍷z'
      'link issue #37'assert'1 1 1 0 1 1≡⎕NEXISTS (folder,''/sub/'')∘,¨''var1.apla'' ''var2.apla'' ''var3.apla'' ''var4.apla'' ''⎕IO.apla'' ''⎕ML.apla'' '
      3 ⎕NDELETE folder
      ⎕EX name
      ok←1
    ∇


    ∇ ok←test_import(folder name);foo;cm;cv;ns;z;opts;_;bc;ac
     
      3 ⎕MKDIR Retry⊢folder∘,¨'/sub/sub1' '/sub/sub2'
     
      ⍝ make some content
      (⊂foo←' r←foo x' ' x x')⎕NPUT folder,'/foo.dyalog'
      (⊂⊂cv←'Line 1' 'Line two')⎕NPUT¨folder∘,¨'/cm.charmat' '/cv.charvec'
      cm←↑cv
      (⊂'[''one'' 1' '''two'' 2]')⎕NPUT folder,'/sub/sub2/one2.apla'
      (⊂bc←':Class bClass' ':EndClass')⎕NPUT folder,'/sub/sub2/bClass.dyalog'
      (⊂ac←':Class aClass : bClass' ':EndClass')⎕NPUT folder,'/sub/sub2/aClass.dyalog'
      (⊂,⊂,'0')⎕NPUT folder,'/sub/⎕IO.dyalog'
     
      opts←⎕NS''
      opts.beforeRead←'⎕SE.Link.Test.onBasicRead'
      opts.beforeWrite←'⎕SE.Link.Test.onBasicWrite'
      ⍝opts.customExtensions←'charmat' 'charvec'
     
      ⍝ link issue #174
      ⎕EX name ⋄ name ⎕NS ⍬ ⋄ name⍎'oldvar←342 ⋄ oldfoo←{''oldfoo''}'
      opts.overwrite←0
      name⍎'foo←''this seat is taken'' ⋄ sub←{''this one is too''}'
      'link issue #174'assertError'opts ⎕SE.Link.Import name folder' 'Names already exist'
      'link issue #174'assertError'opts ⎕SE.Link.Import name folder'(name,'.foo')
      'link issue #174'assertError'opts ⎕SE.Link.Import name folder'(name,'.sub')
      opts.overwrite←1
      z←opts ⎕SE.Link.Import name folder
      'link issue #174'assert'(⊃''Imported: ''⍷z)∧(~∨/''failed''⍷z)'
      'link issue #174'assert'2.1 3.2≡',name,'.⎕NC''oldvar'' ''oldfoo'' '
      'link issue #174'assert'foo≡',name,'.⎕NR ''foo'''
      'link issue #174'assert'(2 2⍴''one'' 1 ''two'' 2)≡',name,'.sub.sub2.one2'
      'link issue #184'assert'1 0≡',name,'.(⎕IO sub.⎕IO)'
      ⎕EX name ⋄ name ⎕NS ⍬ ⋄ name⍎'oldvar←342 ⋄ oldfoo←{''oldfoo''}'
      opts.overwrite←0
      z←opts ⎕SE.Link.Import name folder
      'link issue #174'assert'(⊃''Imported: ''⍷z)∧(~∨/''failed''⍷z)'
      'link issue #174'assert'2.1 3.2≡',name,'.⎕NC''oldvar'' ''oldfoo'' '
      ⎕EX name
     
      z←opts ⎕SE.Link.Import name folder
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
      z←opts ⎕SE.Link.Import name folder
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
     
      ⎕EX name ⋄ name ⎕NS''
      assertError'z←⎕SE.Link.Import name(folder,''/not_there.dyalog'')' 'Source not found'
     
      z←⎕SE.Link.Import name(folder,'/foo.dyalog')
      'link issue #79'assert'~∨/''failed''⍷z'
      'link issue #79'assert'3.1=⎕NC⊂''',name,'.foo'''
      ⎕EX name,'.foo'
      z←⎕SE.Link.Import name(folder,'/foo')  ⍝ automatic file extension
      'link issue #81'assert'~∨/''failed''⍷z'
      'link issue #81'assert'3.1=⎕NC⊂''',name,'.foo'''
      (⊂'foo')⎕NPUT(folder,'/foo.aplf')1  ⍝ two files with extensions
      'link issue #81'assertError'z←⎕SE.Link.Import name(folder,''/foo'')' 'More than one source'
     
      name⍎'one2←1 2'
      assertError'⎕SE.Link.Import name(folder,''/sub/sub2/one2.apla'')'(name,'.one2')
      opts.overwrite←1
      z←opts ⎕SE.Link.Import name(folder,'/sub/sub2/one2.apla')
      'link issue #79'assert'~∨/''failed''⍷z'
      'link issue #79'assert'(2 2⍴''one'' 1 ''two'' 2)≡',name,'.one2'
      name⍎'one2←1 2'
      (⊂'foo')⎕NPUT(folder,'/sub/sub2/one2.ini')1  ⍝ must be ignored, leaving one2.apla as sole candidate for one2.*
      z←opts ⎕SE.Link.Import name(folder,'/sub/sub2/one2')
      'link issue #81'assert'~∨/''failed''⍷z'
      'link issue #81'assert'(2 2⍴''one'' 1 ''two'' 2)≡',name,'.one2'
      (⊂'foo')⎕NPUT(folder,'/sub/sub2/one2.dyalog')1  ⍝ will clash
      'link issue #81'assertError'z←opts ⎕SE.Link.Import name(folder,''/sub/sub2/one2'')' 'More than one source'
     
     
      ⍝ Now tear it all down again:
      _←2 QNDELETE folder
      assert'9=⎕NC ''ns'''
      #.⎕EX name
      ok←1
    ∇







    ∇ ok←test_basic(folder name);_;ac;bc;cb;cm;cv;file;foo;goo;goofile;link;m;new;nil;nl;ns;o2file;old;olddd;opts;otfile;start;t;tn;value;z;zoo;zzz
     
      3 ⎕MKDIR Retry⊢folder
     
      opts←⎕NS''
      opts.beforeRead←'⎕SE.Link.Test.onBasicRead'
      opts.beforeWrite←'⎕SE.Link.Test.onBasicWrite'
      opts.customExtensions←'charmat' 'charvec'
      opts.watch←'both'
      z←opts ⎕SE.Link.Create name folder
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
      {}⎕SE.Link.Add'ns.sub.onetwo'
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
      :Else ⋄ Log'Unable to instantiate aClass: ',⊃⎕DM
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
     
      CleanUp folder name
      ok←1
    ∇

   ⍝ Callback functions to implement .charmat & .charvec support
    ∇ r←onBasicRead args;data;event;extn;file;link;name;nc;parts
      (event link file name nc)←5↑args
      r←1 ⍝ Link should carry on; we're not handling this one
      :If (⊂extn←3⊃parts←⎕NPARTS file)∊'.charmat' '.charvec'
          data←↑⍣(extn≡'.charmat')⎕SE.Link.U.GetFile file
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









    ∇ ok←test_casecode(folder name);DummyFn;FixFn;actfiles;actnames;expfiles;expnames;files;fn;fn2;fnfile;fns;goo;mat;name;nl;nl3;ns;opts;var;var2;varfile;winfolder;z
     
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
      actfiles←{⍵[⍋⍵]}(1+≢folder)↓¨0 NTREE folder    ⍝ NB sorting is different in classic VS unicode
      expfiles←{⍵[⍋⍵]}'SUB-7/DUP-7.aplf' 'SUB-7/SUBSUB-77/DUPDUP-77.aplf' 'sub-0/dup-0.aplf'
      'link issue #43'assert'actfiles≡expfiles'
      ⍝ TODO : export cannot export arrays ? (ns.var)
      3 ⎕NDELETE folder
     
      ⍝ try variables too
      z←opts ⎕SE.Link.Create name folder
      assert'z≡''Linked: ',name,' ←→ ',winfolder,''''
      actfiles←{⍵[⍋⍵]}(1+≢folder)↓¨0 NTREE folder
      'link issue #43'assert'actfiles≡expfiles'
      {}⎕SE.Link.Add name,'.var'
      actfiles←{⍵[⍋⍵]}(1+≢folder)↓¨0 NTREE folder
      expfiles←{⍵[⍋⍵]}expfiles,⊂'var-0.apla'
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
      {}⎕SE.Link.Break name ⋄ ⎕EX name
     
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
     
      {}⎕SE.Link.Break name ⋄ ⎕EX name
     
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
      var←⍳4 5 7
      varfile←⎕SE.Link.CaseCode folder,'/HeLLo.apla'
      assert'varfile≡folder,''/HeLLo-15.apla'''
      assert'(folder,''/HeLLo.apla'')≡⎕SE.Link.StripCaseCode varfile'
      :If ⎕SE.Link.U.IS181 ⋄ fn←'   r   ← OhMyOhMy  ( oh   my  )' 'r←  oh my   oh my'
      :Else ⋄ fn←' r←OhMyOhMy(oh my)' ' r←oh my oh my'
      :EndIf
      fnfile←⎕SE.Link.CaseCode folder,'/OhMyOhMy.aplf'
      assert'fnfile≡folder,''/OhMyOhMy-125.aplf'''
      assert'(folder,''/OhMyOhMy.aplf'')≡⎕SE.Link.StripCaseCode fnfile'
     
      ⍝ Test that explicit Fix updates the right file
      assert'0 0≡⎕NEXISTS varfile fnfile'
      name'HeLLo'⎕SE.Link.Fix ⎕SE.Dyalog.Array.Serialise var
      name'OhMyOhMy'⎕SE.Link.Fix fn
      assert'var≡',name,'.HeLLo'
      assert'fn≡NR''',name,'.OhMyOhMy'''
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
      assert'varfile≡⎕SE.Link.GetFileName name,''.HeLLo'''
      assert'(name,''.HeLLo'')≡⎕SE.Link.GetItemName varfile'
     
      ⍝ Test that Expunge deletes the right file
      assert'1 1≡⎕NEXISTS varfile fnfile'
      assert'0∧.≠⎕NC''',name,'.HeLLo'' ''',name,'.OhMyOhMy'''
     
      z←⎕SE.Link.Expunge name∘,¨'.HeLLo' '.OhMyOhMy'
      assert'1 1≡z'
      assert'0 0≡⎕NEXISTS varfile fnfile'
      assert'0∧.=⎕NC''',name,'.HeLLo'' ''',name,'.OhMyOhMy'''
     
      {}⎕SE.Link.Break name
      CleanUp folder name
      ok←1
    ∇











    ∇ ok←test_bugs(folder name);foo;newbody;nr;opts;props;root;src;src2;sub;todelete;unlikelyclass;unlikelyfile;unlikelyname;var;z;engine;server;warn
    ⍝ Github issues
      name ⎕NS''
      ⎕MKDIR Retry⊢folder ⍝ folder must be non-existent
     
      ⍝ link issue #112 : cannot break an empty link
      z←⎕SE.Link.Create name folder
      'link issue #112'assert'~∨/''failed''⍷z'
      z←⎕SE.Link.Break name ⋄ ⎕EX name
      'link issue #112'assert'(∨/''Unlinked''⍷z)'
     
      ⍝ link issue #118 : create link in #
      root←⎕NS ⍬ ⋄ root NSMOVE #  ⍝ clear # - prevents using #.SLAVE
      '#.unlikelyname must be non-existent'assert'0∧.=⎕NC''#.unlikelyname'' ''⎕SE.unlikelyname'''
      {}(⊂unlikelyclass←,¨':Class unlikelyname' '∇ foo x' ' ⎕←x' '∇' '∇ goo ' '∇' ':Field var←123' ':EndClass')⎕NPUT unlikelyfile←folder,'/unlikelyname.dyalog'
      z←'{source:''dir''}'⎕SE.Link.Create # folder
      :If ~0.6∊1||#.⎕NC #.⎕NL-⍳10  ⍝ Options → Configure → Object Syntax → Expose Root Properties
          Log'"Expose Root Properties" not turned on - cannot QA issue #161'
      :EndIf
      'link issue #118 or #161'assert'1=≢⎕SE.Link.Links'
      'link issue #161'assert'~∨/''not empty''⍷z'
      'link issue #118'assert'~∨/''failed''⍷z'
      'link issue #118'assert'9.4=⎕NC⊂''#.unlikelyname'''
      z←⎕SE.Link.Break #
      assert'0=≢⎕SE.Link.Links'
      ⎕EX'#.unlikelyname'
      # NSMOVE root ⋄ ⎕EX'root' ⍝ put back #
     
      z←⎕SE.Link.Create(name,'.⎕THIS')folder
      'link issue #145'assert'~∨/''failed''⍷z'
      'link issue #145'assert'1=≢⎕SE.Link.Links'
      z←⎕SE.Link.Create('⎕THIS.',name,'.sub')folder
      'link issue #145'assert'~∨/''failed''⍷z'
      'link issue #145'assert'2=≢⎕SE.Link.Links'
      :Trap ⎕SE.Link.U.ERRNO
          {}⎕SE.Link.Break name  ⍝ must error because of linked children
          assert'0'
      :Else
          assert'∨/''Cannot break children''⍷⊃⎕DM'
      :EndTrap
      {}'{recursive:''off''}'⎕SE.Link.Break name  ⍝ break only name and not children
      assert'1=≢⎕SE.Link.Links'  ⍝ children remains
      z←'{recursive:''off''}'⎕SE.Link.Break name
      assert'1=≢⎕SE.Link.Links'
      z←'{recursive:''on''}'⎕SE.Link.Break name
      assert'0=≢⎕SE.Link.Links'
      ⎕EX name
     
      ⍝ link issue #204
      z←⎕SE.Link.Create name folder
      'link issue #204'assert'~∨/''failed''⍷z'
      'link issue #204'assert'1=≢⎕SE.Link.Links'
      ⎕EX name
      z←⎕SE.Link.Create'#.unlikelyname'folder
      'link issue #204'assert'~∨/''failed''⍷z'
      'link issue #204'assert'1=≢⎕SE.Link.Links'
      {}⎕SE.Link.Expunge'#.unlikelyname'
      'link issue #204'assert'0=≢⎕SE.Link.Links'
     
      ⍝ link issue #111 : ]link.break -all must work
      '⎕SE.unlikelyname must be non-existent'assert'0=⎕NC''⎕SE.unlikelyname'''
      z←⎕SE.Link.Create'⎕SE.unlikelyname'folder
      z←⎕SE.Link.Create'#.unlikelyname'folder
      z←⎕SE.Link.Create'#.unlikelyname.sub'folder
      assert'3=≢⎕SE.Link.Links'
      props←'Namespace' 'Directory' 'Items'
      'link issue #142'assert'(props⍪ ''⎕SE.unlikelyname'' ''#.unlikelyname'' ''#.unlikelyname.sub'',3 2⍴folder 1)≡⎕SE.Link.Status '''''
      'link issue #142'assert'(props,[.5] ''⎕SE.unlikelyname'' folder 1 )≡⎕SE.Link.Status ⎕SE'
     
      {}'{all:1}'⎕SE.Link.Break ⍬
      'link issue #111'assert'0=≢⎕SE.Link.Links'
      ⎕EX'⎕SE.unlikelyname' '#.unlikelyname'
      z←⎕SE.Link.Create'⎕SE.unlikelyname'folder
      z←⎕SE.Link.Create'#.unlikelyname'folder
      z←⎕SE.Link.Create'#.unlikelyname.sub'folder
      assert'3=≢⎕SE.Link.Links'
      {}'{recursive:''on''}'⎕SE.Link.Break'#.unlikelyname'
      'link issue #111'assert'1=≢⎕SE.Link.Links'
      {}⎕SE.Link.Break'⎕SE.unlikelyname'
      'link issue #111'assert'0=≢⎕SE.Link.Links'
      ⎕EX'⎕SE.unlikelyname' '#.unlikelyname'
     
     
      ⍝ link issue #117 : leave trailing slash in dir
      ⍝ superseeded by issue #146 when trailing slash was disabled altogether
      'link issue #146'assertError'⎕SE.Link.Create name(folder,''/'')' 'Trailing slash reserved'
      'link issue #146'assert'0=≢⎕SE.Link.Links'
      z←⎕SE.Link.Create name folder
      'link issue #117'assert'1=≢⎕SE.Link.Links'
      'link issue #117'assert'~∨/''failed''⍷z'
     ⍝ link issue #116 : ⎕SE.Link.Refresh should not error when given a dir
      z←⎕SE.Link.Refresh folder
      'link issue #117'assert'∨/''Not linked''⍷z'
      z←⎕SE.Link.Refresh name
      assert'⊃''Imported:''⍷z'
      assert'~∨/''failed''⍷z'
     
      ⍝ link issue #109 : fixing invalid function makes it disappear
      unlikelyname←name,'.unlikelyname' ⋄ newbody←'unlikelyname x;' '⎕←x'
      'link issue #109'assertError('name ''unlikelyname''⎕SE.Link.Fix newbody ')('Invalid source')
      'link issue #109'assert'unlikelyclass≡⊃⎕NGET unlikelyfile 1'    ⍝ changes not put back to file
      'link issue #109'assert'unlikelyclass≡⎕SRC ⍎unlikelyname'         ⍝ fix failed
      'link issue #109'assert'unlikelyfile≡4⊃5179⌶ name,''.unlikelyname''' ⍝ still tied
     
      ⍝ link issue #108 : UCMD returned empty
      'link issue #108'assert'(⎕SE.UCMD '']Link.GetFileName '',unlikelyname)≡,⊂⎕SE.Link.GetFileName unlikelyname'
      {}⎕SE.Link.Break name ⋄ ⎕EX name
     
      opts←⎕NS ⍬
      opts.watch←'dir'
      opts.typeExtensions←↑(2 'myapla')(3 'myaplf')(4 'myaplo')(9.1 'myapln')(9.4 'myaplc')(9.5 'myapli')
      (⊂newbody)⎕NPUT unlikelyfile 1  ⍝ make it invalid source
      z←opts ⎕SE.Link.Create name folder
      assert'∧/∨/¨''failed'' (⎕SE.Link.U.WinSlash unlikelyfile)⍷¨⊂z'
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
          (⍎sub).⎕FIX src←,¨':Namespace script' '∇ res←function arg' 'res←arg' '∇' '∇ goo' '∇' 'var←123' ':EndNamespace'
      :EndFor
     
      RDFILES←RDNAMES←WRFILES←WRNAMES←⍬
      opts←⎕NS ⍬
      opts.beforeRead←'⎕SE.Link.Test.beforeReadAdd'
      opts.beforeWrite←'⎕SE.Link.Test.beforeWriteAdd'
     
      ⍝ TODO allow exporting variables ?
      {}opts ⎕SE.Link.Export name folder
      'link issue #21'assert'WRFILES ≡ folder∘,¨''/foo.aplf''  ''/script.apln'' ''/sub/'' ''/sub/foo.aplf''  ''/sub/script.apln'' '
      'link issue #21'assert'WRNAMES ≡ name∘,¨''.foo''  ''.script'' ''.sub'' ''.sub.foo''  ''.sub.script''  '
      'link issue #21'assert'0∊⍴RDFILES,RDNAMES'
      WRFILES←WRNAMES←⍬
      ⎕EX name
     
      (⊂⍕var)⎕NPUT folder,'/var.apla'
      (⊂⍕var)⎕NPUT folder,'/sub/var.apla'
      {}opts ⎕SE.Link.Import name folder
      'link issue #68'assert'RDFILES ≡ folder∘,¨''/''  ''/sub/''  ''/foo.aplf''  ''/script.apln''  ''/sub/foo.aplf''  ''/sub/script.apln'' ''/sub/var.apla'' ''/var.apla'''
      'link issue #68'assert'RDNAMES ≡ name∘,¨''''  ''.sub''  ''.foo''  ''.script''  ''.sub.foo''  ''.sub.script'' ''.sub.var'' ''.var'''
      'link issue #68'assert'0∊⍴WRFILES,WRNAMES'
      ⎕EX name
     
      ⍝ .apln must clash with directory of the same name
      {}(⊂':Namespace sub' ':EndNamespace')QNPUT folder,'/sub.apln'
      assertError'z←⎕SE.Link.Create name folder' 'clashing APL names'
      ⎕NDELETE folder,'/sub.apln'
     
      ⍝ attempt to change a function to an operator
      {}⎕SE.Link.Create name folder
      name'foo'⎕SE.Link.Fix foo←' r←(op foo)arg' ' r←op arg' ⍝ turn foo into an operator
      Breathe
      {}(folder,'/foo.aplo')#.SLAVE.⎕NMOVE folder,'/foo.aplf'
      Breathe
      'link issue #142'assert'(props,[.5]name folder 7)≡⎕SE.Link.Status name'
     
      ⍝ attempt to create invalid directory
      (warn ⎕SE.Link.U.WARN)←(⎕SE.Link.U.WARN 1) ⋄ ⎕SE.Link.U.WARNLOG/⍨←0
      3 ⎕MKDIR folder,'/New directory (1)/'
      'link issue #183'assert'~0∊⍴''invalid name defined by file''⎕S ''\0''⊢⎕SE.Link.U.WARNLOG'
      ⎕SE.Link.WARN←warn
      3 ⎕NDELETE folder,'/New directory (1)/'
     
      ⍝ attempt to rename a script
      src2←,¨':Namespace script2' '∇ res←function2 arg' 'res←arg' '∇' ':EndNamespace'
      {}(⊂src2)QNPUT(folder,'/script.apln')1
      'link issue #36'assert'0=⎕NC ''',name,'.script'''
      'link issue #36'assert'src2≡⎕SRC ',name,'.script2'
      {}(⊂src)QNPUT(folder,'/script.apln')1
      'link issue #36'assert'0=⎕NC ''',name,'.script2'''
      'link issue #36'assert'src≡⎕SRC ',name,'.script'
     
      z←⎕SE.Link.GetFileName 1 NSTREE name
      'link issue #128'assert'({⍵[⍋⍵]}z)≡({⍵[⍋⍵]} 1 NTREE folder)'
      z←⎕SE.Link.GetItemName 1 NTREE folder
      'link issue #128'assert'({⍵[⍋⍵]}z)≡({⍵[⍋⍵]} 1 NSTREE name)'
      z←⎕SE.Link.GetFileName'⎕SE.nope' '⎕SE.nope.nope',name∘,¨'.nope' '.sub.nope' '.nope.nope'
      z,←⎕SE.Link.GetItemName'/nope.nope' '/nope/nope.nope',folder∘,¨'/nope.nope' '/sub/nope.nope' '/nope/nope.nope'
      assert'∧/z≡¨⊂'''' '
     
      ⍝ add some sysvars
      name⍎'⎕IO←⎕ML←0'
      z←⎕SE.Link.Add(name,'.⎕IO')(name,'.⎕ML')
      'link issue #184'assert'1 0≡(∨/''Added:''⍷z)(∨/''Not found:''⍷z)'
      'link issue #184'assert'1 1 0 0≡⎕NEXISTS folder∘,¨''/⎕IO.apla'' ''/⎕ML.apla'' ''/⎕RL.apla'' ''/⎕CT.apla'' '
      z←⎕SE.Link.Add(name,'.⎕WSID')(name,'.⎕PATH')
      'link issue #184'assert'0 1≡(∨/''Added:''⍷z)(∨/''Not found:''⍷z)'
      'link issue #184'assert'0 0≡⎕NEXISTS folder∘,¨''/⎕WSID.apla'' ''/⎕PATH.apla'' '
     
      ⍝ attempt to write control characters
      :Trap 0
          name'foo'⎕SE.Link.Fix'res←(op foo)arg'('res←''',(⎕UCS 10),''',arg')
          'link issue #151'assert'0'
      :Else
          'link issue #151'assert'∨/''cannot have newlines''⍷⊃⎕DM'
      :EndTrap
      'link issue #151'assert'foo≡⎕NR ''',name,'.foo'''
     
      ⍝ link issue #205 - check round-trip of arrays
      name⍎'limit_error←⍉(9⍴3)⊤⍳3*9'
      'link issue #205'assertError('⎕SE.Link.Add ''',name,'.limit_error'' ')'Cannot round-trip serialisation of array'
     
      ⍝ attempt to refresh
      ⎕SE.UCMD'z←]link.refresh ',name
      'link issue #132 and #133'assert'⊃''Imported:''⍷z'
      {}⎕SE.Link.Break name
      :If ~0∊⍴5177⌶⍬ ⋄ :AndIf ⎕SE∨.≠{⍵.##}⍣≡⊢2⊃¨5177⌶⍬
          assert'0'  ⍝ no more links in #
      :EndIf
      ⎕EX name
     
      ⍝ attempt to recover the source after deletion when not watching the directory
      opts←⎕NS ⍬
      opts.watch←'ns'
      {}(⊂todelete←':Namespace todelete' 'todelete←1' ':EndNamespace')QNPUT(folder,'/todelete.apln')1
      z←opts ⎕SE.Link.Create name folder
      'link issue #184'assert'0 0≡name⍎''⎕IO ⎕ML'''
     
      'link issue #140'assert'todelete≡⎕SRC ',name,'.todelete'
      ⎕NDELETE folder,'/todelete.apln'
      Breathe ⋄ Breathe
      'link issue #140'assert'todelete≡⎕SRC ',name,'.todelete' ⍝ source still available
      ⎕SE.Link.Expunge name,'.todelete'
      (⍎name).{⎕THIS.jsondict←⎕SE.Dyalog.Array.Deserialise ⍵}'{var:42 ⋄ list:1 2 3}'  ⍝ ⎕JSON'{"var":42,"list":[1,2,3]}' hits Mantis 18652
      ⍝'link issue #177'assertError'z←(⍎name).{⎕SE.UCMD''z←]Link.Add jsondict.list''}⍬'('Not a properly named namespace')0 ⍝ UCMD may trigger any error number
      z←(⍎name).{⎕SE.UCMD']Link.Add jsondict.list'}⍬
      'link issue #177'assert'⊃''⎕SE.Link.Add: Not a properly named namespace:''⍷z'  ⍝ link issue #217 - UCMD must not error
     
      ⎕EX name,'.jsondict'
      {}⎕SE.Link.Break name
      assert'⎕SE∧.= {⍵.##}⍣≡⊢2⊃¨5177⌶⍬'  ⍝ no more links in #
     
      ⍝ attempt to export
      3 ⎕NDELETE folder
      (⍎name).⎕FX'res←failed arg'('res←''',(⎕UCS 13),''',arg')
      {}⎕SE.UCMD'z←]link.export ',name,' ',folder
      'link issue #151'assert'∧/∨/¨''failed:'' ''',name,'.failed''⍷¨⊂z'
      'link issue #131'assert'({⍵[⍋⍵]}1 NTREE folder)≡{⍵[⍋⍵]}folder∘,¨''/sub/'' ''/sub/foo.aplf''  ''/foo.aplo'' ''/script.apln'' ''/sub/script.apln'' '
     
      ⍝ link issue #159 - using casecode from namespace
      3 ⎕NDELETE folder
      root←⎕NS ⍬ ⋄ root NSMOVE #  ⍝ clear # - prevents using #.SLAVE
      #.⎕FX'UnlikelyName' '⎕←''UnlikelyName'''
      {}⎕SE.UCMD'z←]link.create -casecode # "',folder,'"'
      'link issue #159'assert'1=≢⎕SE.Link.Links'
      'link issue #159'assert'~∨/''failed''⍷z'
      'link issue #159'assert'(,⊂folder,''/UnlikelyName-401.aplf'')≡0 NTREE folder'
      'link issue #177'assert'~⎕NEXISTS ''',folder,'/jsondict/list.apla'''
      #.jsondict←#.⎕JSON'{"var":42,"list":[1,2,3]}'
      ⍝'link issue #177'assertError'#.{⎕SE.UCMD''z←]Link.Add jsondict.list''}⍬' 'Not a properly named namespace' 0  ⍝ UCMD may trigger any error number
      z←#.{⎕SE.UCMD']Link.Add jsondict.list'}⍬
      'link issue #177'assert'⊃''⎕SE.Link.Add: Not a properly named namespace:''⍷z'  ⍝ link issue #217 - UCMD must not error
      ⎕EX'#.jsondict' ⋄ '#.jsondict'⎕NS'' ⋄ #.jsondict.(var list)←42(1 2 3)
      z←#.{⎕SE.UCMD']Link.Add jsondict.list'}⍬
      'link issue #177'assert'⎕NEXISTS ''',folder,'/jsondict-0/list-0.apla'''
      z←⎕SE.Link.Break #
      assert'0=≢⎕SE.Link.Links'
      ⎕EX'#.UnlikelyName' '#.jsondict'
      3 ⎕NDELETE folder,'/jsondict-0'
      # NSMOVE root ⋄ ⎕EX'root' ⍝ put back #
     
      :If ⎕SE.Link.U.IS181 ⍝ link issue #155 - :Require doesn't work - ensure we have dependecies in both alphabetic orders
          ⎕EX name
          {}(⊂server←':Require file://Engine.apln' ':Namespace  Server' ' dup ← ##.Engine.dup' ':EndNamespace')QNPUT(folder,'/Server.apln')1
          {}(⊂engine←':Namespace  Engine' ' dup ← {⍵ ⍵}' ':EndNamespace')QNPUT(folder,'/Engine.apln')1
          {}(⊂master←':Require file://Slave.apln' ':Namespace  Master' ' dup ← ##.Slave.dup' ':EndNamespace')QNPUT(folder,'/Master.apln')1
          {}(⊂slave←':Namespace  Slave' ' dup ← {⍵ ⍵}' ':EndNamespace')QNPUT(folder,'/Slave.apln')1
          z←⎕SE.Link.Create name folder
          'link issue #155'assert'1=≢⎕SE.Link.Links'
          'link issue #155'assert'~∨/''failed''⍷z'
          'link issue #155'assert' ''Engine'' ''Master''  ''Server'' ''Slave'' ''UnlikelyName'' ≡ (⍎name).⎕NL -⍳10'
          'link issue #155'assert'(1↓server)≡⎕SRC ',name,'.Server'    ⍝ :Require statement missing from ⎕SRC but shown in editor
          'link issue #155'assert'(1↓master)≡⎕SRC ',name,'.Master'    ⍝ :Require statement missing from ⎕SRC but shown in editor
          'link issue #155'assert'(engine)≡⎕SRC ',name,'.Engine'
          'link issue #155'assert'(slave)≡⎕SRC ',name,'.Slave'
          {}⎕SE.Link.Break name
      :EndIf
     
     
     
      CleanUp folder name
      ok←1
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
          _←assert(⍺/'new'),'foonr≡NR subname,''.foo'''
          _←assert(⍺/'new'),'nssrc≡⎕SRC ⍎subname,''.ns'''   ⍝ problem is that ⎕SRC reads directly from file !
          _←assert(⍵/'new'),'varsrc≡⊃⎕NGET (subfolder,''/var.apla'') 1'
          _←assert(⍵/'new'),'foonget≡⊃⎕NGET (subfolder,''/foo.aplf'') 1'
          _←assert(⍵/'new'),'nssrc≡⊃⎕NGET (subfolder,''/ns.apln'') 1'
      }

    ∇ ok←test_create(folder name);badsrc1;badsrc2;dl;failed;files;foonget;foonr;foosrc;footok;newfoonget;newfoonr;newfoosrc;newfootok;newnssrc;newvar;newvarsrc;ns2;nssrc;nstree;opts;ref;reqfile;reqsrc;root;subfolder;subname;var;varsrc;z
      opts←⎕NS ⍬
      subfolder←folder,'/sub' ⋄ subname←name,'.sub'
     
      ⍝ test default UCMD to ⎕THIS
      2 ⎕MKDIR subfolder ⋄ name ⎕NS ⍬
      ⍝:With name ⋄ z←⎕SE.UCMD']Link.Create ',folder ⋄ :EndWith  ⍝ not goot - :With brings in locals into the target namespace
      z←(⍎name).{⎕SE.UCMD ⍵}']Link.Create ',folder
      assert'∨/''Linked:''⍷z'
      assert'1=≢⎕SE.Link.Links'
      ⍝:With name ⋄ z←⎕SE.UCMD']Link.Break ⎕THIS' ⋄ :EndWith
      z←(⍎name).{⎕SE.UCMD ⍵}']Link.Break ⎕THIS.⎕THIS'
      assert'∨/''Unlinked''⍷z'
      assert'0=≢⎕SE.Link.Links'
      ⎕EX name ⋄ 3 ⎕NDELETE folder
     
      ⍝ test failing creations
      assert'0=≢⎕SE.Link.Links'
      3 ⎕NDELETE folder ⋄ ⎕EX name ⋄ opts.source←'dir'
      assertError'opts ⎕SE.Link.Create name folder' 'Source directory not found'
      2 ⎕MKDIR subfolder ⋄ subname ⎕NS ⍬
      assertError'opts ⎕SE.Link.Create name folder' 'Destination namespace not empty'
      3 ⎕NDELETE folder ⋄ ⎕EX name ⋄ opts.source←'ns'
      assertError'opts ⎕SE.Link.Create name folder' 'Source namespace not found'
      2 ⎕MKDIR subfolder ⋄ subname ⎕NS ⍬
      assertError'opts ⎕SE.Link.Create name folder' 'Destination directory not empty'
      ⎕EX name ⋄ 3 ⎕NDELETE folder
      assert'0=≢⎕SE.Link.Links'
     
      opts.source←'auto'
      ⍎name,'←⎕NS ⍬'  ⍝ unnamed namespace name
      2 ⎕MKDIR subfolder
      (⊂':Namespace ns' ':EndNamespace')⎕NPUT folder,'/ns.apln'
      'link issue #197'assertError'opts ⎕SE.Link.Create name folder' 'Not a properly named namespace'
      'link issue #197'assertError'⎕SE.Link.Import name folder' 'Not a properly named namespace'
      'link issue #197'assertError'⎕SE.Link.Import name (folder,''/ns.apln'')' 'Not a properly named namespace'
      ⎕EX name ⋄ ref←⎕NS ⍬  ⍝ unnamed namespace reference
      'link issue #197'assertError'opts ⎕SE.Link.Create ref folder' 'Not a properly named namespace'
      'link issue #197'assertError'⎕SE.Link.Import ref folder' 'Not a properly named namespace'
      'link issue #197'assertError'⎕SE.Link.Import ref (folder,''/ns.apln'')' 'Not a properly named namespace'
      3 ⎕NDELETE folder
     
      ⍝ link issue #163
      2 ⎕MKDIR folder
      root←⎕NS ⍬ ⋄ root NSMOVE #  ⍝ clear # - prevents using #.SLAVE
      (⊂' uc←{' ' ⍝ uppercase conversion' '     1 ⎕C ⍵' ' }')⎕NPUT folder,'/uc.aplf'
      (⊂' lc←{' ' ⍝ lowercase conversion' '     ¯1 ⎕C ⍵' ' }')⎕NPUT folder,'/lc.aplf'
      z←#.{⎕SE.UCMD ⍵}']Link.Create # ',folder  ⍝ Run UCMD from #
      'link issue #163'assert'1=≢⎕SE.Link.Links'
      'link issue #163'assert'3.2 3.2≡#.⎕NC''uc'' ''lc'''
      {}⎕SE.Link.Break #
      #.⎕EX #.⎕NL-⍳10
      # NSMOVE root ⋄ ⎕EX'root'  ⍝ restore #
      3 ⎕NDELETE folder
     
      ⍝ test source=auto
      opts.source←'auto'
      ⍝ both don't exist
      assertError'opts ⎕SE.Link.Create name folder' 'Cannot link a non-existing namespace to a non-existing directory'
      assert'(~⎕NEXISTS folder)∧(0=⎕NC name)'
      assert'0=≢⎕SE.Link.Links'
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder ⋄ ⎕EX name
      ⍝ only dir exists
      2 ⎕MKDIR folder
      z←opts ⎕SE.Link.Create name folder
      assert'(⎕NEXISTS folder)∧(9=⎕NC name)'
      assert'⎕SE.Link.Links.source≡,⊂''dir'''
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder ⋄ ⎕EX name
      ⍝ only ns exists
      name ⎕NS ⍬
      z←opts ⎕SE.Link.Create name folder
      assert'(⎕NEXISTS folder)∧(9=⎕NC name)'
      assert'⎕SE.Link.Links.source≡,⊂''ns'''
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder ⋄ ⎕EX name
      ⍝ both exist
      2 ⎕MKDIR folder ⋄ name ⎕NS ⍬
      z←opts ⎕SE.Link.Create name folder
      assert'(⎕NEXISTS folder)∧(9=⎕NC name)'
      assert'⎕SE.Link.Links.source≡,⊂''dir'''
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder ⋄ ⎕EX name
      ⍝ only dir is populated
      2 ⎕MKDIR subfolder ⋄ name ⎕NS ⍬
      z←opts ⎕SE.Link.Create name folder
      assert'(⎕NEXISTS folder)∧(9=⎕NC name)'
      assert'⎕SE.Link.Links.source≡,⊂''dir'''
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder ⋄ ⎕EX name
      ⍝ only ns is populated
      2 ⎕MKDIR folder ⋄ subname ⎕NS ⍬
      z←opts ⎕SE.Link.Create name folder
      assert'(⎕NEXISTS folder)∧(9=⎕NC name)'
      assert'⎕SE.Link.Links.source≡,⊂''ns'''
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder ⋄ ⎕EX name
      ⍝ both are populated
      2 ⎕MKDIR subfolder ⋄ subname ⎕NS ⍬
      assertError'opts ⎕SE.Link.Create name folder' 'Cannot link a non-empty namespace to a non-empty directory'
      assert'0=≢⎕SE.Link.Links'
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder ⋄ ⎕EX name
     
      2 ⎕MKDIR subfolder
      ⍝ actual contents
      foosrc←'  r ← foo  x ' '   ⍝  comment  ' '  r ← ''foo'' x '  ⍝ source-as-typed (⎕INFO)
      footok←' r←foo x' '   ⍝  comment' ' r←''foo''x'  ⍝ de-tokenised form (⎕NR)
      (⊂foosrc)∘⎕NPUT¨folder subfolder,¨⊂'/foo.aplf'
      (⊂varsrc←⎕SE.Dyalog.Array.Serialise var←((⊂'hello')@2)¨⍳1 1 2)∘⎕NPUT¨folder subfolder,¨⊂'/var.apla'
      (⊂nssrc←':Namespace ns' ' ⍝ comment' 'foo ← { ''foo'' ⍵ } ' ':EndNamespace')∘⎕NPUT¨folder subfolder,¨⊂'/ns.apln'
      (⊂';some text')⎕NPUT folder,'/config.ini'  ⍝ should be ignored
      (⊂badsrc1←,¨':Namespace badns1' '  ∇  res  ←  foo  arg  ;  ' '  res  ←  arg  ' '∇' ':EndNamespace')⎕NPUT folder,'/badns1.apln'
      (⊂badsrc2←,¨':Namespace badns2' '  ∇  res  ←  foo  arg  ' '  res  ←  arg  ' '∇' ':EndClass')⎕NPUT folder,'/badns2.apln'
      newvarsrc←⎕SE.Dyalog.Array.Serialise newvar←((⊂'new hello')@2)¨var
      newfoosrc←('  ⍝  new  comment  ' '  r ← ''newfoo'' x ')@2 3⊢foosrc
      newnssrc←('  ⍝  new  comment  ' 'foo ← { ''newfoo'' ⍵ } ')@2 3⊢nssrc
      newfootok←('  ⍝  new  comment' ' r←''newfoo''x')@2 3⊢footok
      ⍝ expected results
      (foonr newfoonr)←(1+⎕SE.Link.U.IS181)⊃¨(footok foosrc)(newfootok newfoosrc)  ⍝ v18.0 can't read source of APL functions as typed
      (foonget newfoonget)←(foosrc newfoosrc)
      ⍝ bug from Morten
      ns2←,¨':Namespace ns2' '∇res←{larg}fn rarg' 'sub←{1:∇⍵⋄⍵}' 'sub←{1:∇⍵' '⍵}' 'sub←{' '1:∇⍵⋄⍵' '}' 'res←{1:∇⍵⋄⍵}rarg' 'res←{1:∇⍵⋄⍵}rarg' 'res←{1:∇⍵' '⍵}rarg' 'res←{' '1:∇⍵⋄⍵' '}rarg' '∇' 'dfn←{' 'sub←{1:∇⍵⋄⍵}' 'sub←{1:∇⍵' '⍵}' 'sub←{' '1:∇⍵⋄⍵' '}' 'res←{1:∇⍵⋄⍵}rarg' 'res←{1:∇⍵' '⍵}rarg' 'res←{1:∇⍵⋄⍵}rarg' 'res←{' '1:⍵⋄⍵' '}rarg' '}' ':EndNamespace'
      (⊂ns2)⎕NPUT folder,'/ns2.apln'
      ⍝ some more tests with :Require and Class/Interface inheritance - in particular that it survives all possible grading orders byt name and by timestamp
      dl←0.1  ⍝ delay between creation in case files are ordered by time rather than by name
      ⎕DL dl ⋄ (⊂':Namespace REQ1A' 'testvar←1234' ':EndNamespace')⎕NPUT folder,'/AREQ1A.apln'
      ⎕DL dl ⋄ (⊂(':Require file://',folder,'/AREQ1A.apln')':Namespace REQ1B' '∇ res←TestVar' ':Access Public Shared' 'res←##.REQ1A.testvar' '∇' ':EndNamespace')⎕NPUT folder,'/AREQ1B.apln'
      ⎕DL dl ⋄ (⊂':Interface CLASS1A' '∇ res←foo arg' '∇' ':EndInterface')⎕NPUT folder,'/CLASS1A.aplc'
      ⎕DL dl ⋄ (⊂':Class CLASS1B:,CLASS1A' ':Include REQ1B' '∇ res←foo arg' ':Implements Method CLASS1A.foo' 'res←''foo''arg' '∇' ':EndClass')⎕NPUT folder,'/CLASS1B.aplc'
      ⎕DL dl ⋄ (⊂':Interface CLASS1C' '∇ res←goo arg' '∇' ':EndInterface')⎕NPUT folder,'/CLASS1C.aplc'
      ⎕DL dl ⋄ (⊂':Class CLASS1D:CLASS1B,CLASS1C' ':Include REQ1B' '∇ res←goo arg' ':Implements Method CLASS1C.goo' 'res←''goo'' arg' '∇' ':EndClass')⎕NPUT folder,'/CLASS1D.aplc'
      ⎕DL dl ⋄ (⊂':Class CLASS2A:CLASS2C,CLASS2B' ':Include REQ2A' '∇ res←goo arg' ':Implements Method CLASS2B.goo' 'res←''goo'' arg' '∇' ':EndClass')⎕NPUT folder,'/CLASS2A.aplc'
      ⎕DL dl ⋄ (⊂':Interface CLASS2B' '∇ res←goo arg' '∇' ':EndInterface')⎕NPUT folder,'/CLASS2B.aplc'
      ⎕DL dl ⋄ (⊂':Class CLASS2C:,CLASS2D' ':Include REQ2A' '∇ res←foo arg' ':Implements Method CLASS2D.foo' 'res←''foo''arg' '∇' ':EndClass')⎕NPUT folder,'/CLASS2C.aplc'
      ⎕DL dl ⋄ (⊂':Interface CLASS2D' '∇ res←foo arg' '∇' ':EndInterface')⎕NPUT folder,'/CLASS2D.aplc'
      ⎕DL dl ⋄ (⊂(':Require file://',folder,'/ZREQ2B.apln')':Namespace REQ2A' '∇ res←TestVar' ':Access Public Shared' 'res←##.REQ1A.testvar' '∇' ':EndNamespace')⎕NPUT folder,'/ZREQ2A.apln'
      ⎕DL dl ⋄ (⊂':Namespace REQ2B' 'testvar←1234' ':EndNamespace')⎕NPUT folder,'/ZREQ2B.apln'
      (⊂':Namespace required' 'testvar←1234' ':EndNamespace')⎕NPUT folder,'/required.apln'
      reqfile←subfolder,'/require.apln'
      reqsrc←'' '   ⍝ :Namespace notyet '(':Require "file://',folder,'/required.apln"')':Namespace require' 'testvar←##.required.testvar' ':EndNamespace'
     
      :If ⎕SE.Link.U.IS181 ⍝ link issue #144
          opts.source←'dir' ⋄ opts.watch←'both'
          z←opts ⎕SE.Link.Create name folder
          'link issue #144'assert'badsrc1≡⎕SRC ',name,'.badns1'
          'link issue #144'assert'badsrc2≡⎕SRC ',name,'.badns2'
          {}⎕SE.Link.Break name ⋄ ⎕EX name
      :EndIf
     
      ⍝ Link issue #173
      (⊂reqsrc)⎕NPUT reqfile 1 ⋄ opts.source←'dir'
      opts.watch←'dir' ⋄ 'link issue #173'assertError'opts ⎕SE.Link.Create name folder' ':Require' ⋄ ⎕EX name
      opts.watch←'ns' ⋄ 'link issue #173'assertError'opts ⎕SE.Link.Create name folder' ':Require' ⋄ ⎕EX name
      opts.watch←'none' ⋄ 'link issue #173'assertError'opts ⎕SE.Link.Create name folder' ':Require' ⋄ ⎕EX name
      opts.watch←'both' ⋄ z←opts ⎕SE.Link.Create name folder
      :If ⎕SE.Link.U.IS181 ⋄ assert'~∨/''failed''⍷z'
      :Else ⋄ assert' ~∨/folder⍷ ''^Linked:.*$''  ''^.*badns.*$'' ⎕R '''' ⊢z '  ⍝ no failure apart from badns1 and badns2
      :EndIf
      nstree←(name,'.')∘,¨'ns2' 'foo' 'ns' 'required' 'sub' 'var' 'sub.foo' 'sub.ns' 'sub.require' 'sub.required' 'sub.var'
      nstree,←(name,'.')∘,¨'REQ1A' 'REQ1B' 'REQ2A' 'REQ2B' 'CLASS1A' 'CLASS1B' 'CLASS1C' 'CLASS1D' 'CLASS2A' 'CLASS2B' 'CLASS2C' 'CLASS2D'
      ⍝ only v19.0 has ⎕FIX⍠'FixWithErrors'1
      :If ⎕SE.Link.U.IS181 ⋄ nstree,←'#.linktest.badns1' '#.linktest.badns2' ⋄ :EndIf
      ⍝:If 82=⎕DR'' ⋄ nstree~←'#.linktest.sub.require' '#.linktest.sub.required' ⋄ :EndIf  ⍝ BUG this line was due to Mantis 18628
      'link issue #173'assert'({⍵[⍋⍵]}1 NSTREE name)≡{⍵[⍋⍵]}',⍕Stringify¨nstree
      'link issue #173'assert'(≢{(2≠⌊|⎕NC⍵)/⍵}0 NSTREE name)≡(+/~3⊃⎕SE.Link.U.GetFileTiesIn ',name,')'  ⍝ Mantis 18626 required ⎕SE.Link.U.IS181++/~3⊃⎕SE.Link.U.GetFileTiesIn
      failed←0⍴⊂'' ⍝ BUG this line was due to Manti 18635 : ⍝ failed←⊂'CLASS2A'
      assert'∧/1234∘≡¨',⍕name∘{⍺,'.',⍵,'.TestVar'}¨failed~⍨('REQ'∘,¨'1B' '2A'),('CLASS'∘,¨'1B' '1D' '2A' '2C')
      assert'∧/',⍕name∘{'(''foo''1234≡(⎕NEW ',⍺,'.',⍵,').foo 1234)'}¨failed~⍨'CLASS'∘,¨'1B' '1D' '2A' '2C'
      assert'∧/',⍕name∘{'(''goo''1234≡(⎕NEW ',⍺,'.',⍵,').goo 1234)'}¨failed~⍨'CLASS'∘,¨'1D' '2A'
      {}⎕SE.Link.Break name ⋄ ⎕EX name ⋄ ⎕NDELETE reqfile
      ⎕NDELETE⍠1⊢(folder,'/')∘,¨'AREQ*.apln' 'ZREQ*.apln'  ⍝ link issue #173
     
      ⍝ test source=dir watch=dir
      opts.source←'dir' ⋄ opts.watch←'dir' ⋄ z←opts ⎕SE.Link.Create name folder
      assert'''Linked:''≡7↑z'
      assert'var∘≡¨⍎¨name subname,¨⊂''.var'''
      :If ⎕SE.Link.U.IS181 ⋄ assert'foosrc∘≡¨NR¨name subname,¨⊂''.foo'''  ⍝ source-as-typed
      :Else ⋄ assert'foonr∘≡¨NR¨name subname,¨⊂''.foo'''                  ⍝ de-tokenised form
      :EndIf
      assert'nssrc∘≡¨⎕SRC¨⍎¨name subname,¨⊂''.ns'''
      0 assert_create 0
      'link issue #173'assert'0=+/~3⊃⎕SE.Link.U.GetFileTiesIn ',name
      ⍝ watch=dir must reflect changes from files to APL
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      1 assert_create 1
      ⍝ watch=dir must not reflect changes from APL to files
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      Breathe ⋄ 0 assert_create 1   ⍝ breathe to ensure it's not reflected
      {}(⊂nssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂varsrc)QNPUT(subfolder,'/var.apla')1
      0 assert_create 0
      ⍝ link issue #176 - test Pause - can't test Pause on watch='both' because the file would be tied with 2 ⎕FIX 'file://'
      {}⎕SE.Link.Pause name
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      Breathe ⋄ Breathe ⋄ Breathe   ⍝ ensure changes are not reflected
      0 assert_create 1
      z←'{source:''dir''}'⎕SE.Link.Refresh name
      1 assert_create 1
      z←⎕SE.Link.Expunge name  ⍝ expunge whole linked namespace
      assert'(0=≢⎕SE.Link.Links)∧(z≡1)'
     
      ⍝ now try source=dir watch=ns
      opts.source←'dir' ⋄ opts.watch←'ns' ⋄ {}opts ⎕SE.Link.Create name folder
      1 assert_create 1
      'link issue #173'assert'0=+/~3⊃⎕SE.Link.U.GetFileTiesIn ',name
      ⍝ APL changes must be reflected to file
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      0 assert_create 0
      ⍝ file changes must not be reflected back to APL
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      Breathe ⍝ breathe to ensure it's not reflected
      0 assert_create 1
      {}⎕SE.Link.Expunge name
     
      ⍝ now try source=dir watch=none
      opts.source←'dir' ⋄ opts.watch←'none' ⋄ {}opts ⎕SE.Link.Create name folder
      1 assert_create 1
      'link issue #173'assert'0=+/~3⊃⎕SE.Link.U.GetFileTiesIn ',name
      {}(⊂nssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂varsrc)QNPUT(subfolder,'/var.apla')1
      Breathe ⋄ 1 assert_create 0
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      Breathe ⋄ 1 assert_create 1
      subname'var'⎕SE.Link.Fix varsrc
      subname'foo'⎕SE.Link.Fix foosrc
      subname'ns'⎕SE.Link.Fix nssrc
      Breathe ⋄ 0 assert_create 1
      {}⎕SE.Link.Break name
      3 ⎕NDELETE folder
     
     
      ⍝ now try source=ns watch=dir
      :If ~⎕SE.Link.U.IS181 ⋄ (foonget newfoonget)←(footok newfootok) ⋄ :EndIf  ⍝ source=ns means 18.0 can't export whitespace-preserved
      opts.source←'ns' ⋄ opts.watch←'dir' ⋄ opts.arrays←name,'.var,',name,'.sub.var'
      name⍎'derived←∧.∧'
      name⍎'array←1 2 3'
      z←opts ⎕SE.Link.Create name folder
      'link issue #186'assert'∨/''',name,'.derived''⍷z'   ⍝ must warn about unsupported names
      'link issue #186'assert'~∨/''',name,'.array''⍷z'    ⍝ arrays must be silently ignored
      'link issue #186'assert'0∊⍴⊃⎕NINFO⍠1⊢folder,''/derived.*'''
      'link issue #186'assert'0∊⍴⊃⎕NINFO⍠1⊢folder,''/array.*'''
      'link issue #186'assertError'⎕SE.Link.Add name,''.derived''' 'Invalid name class'
      0 assert_create 0
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      :If ~⎕SE.Link.U.IS181 ⋄ newfoonget←newfoosrc ⋄ :EndIf   ⍝ we just wrote it to file
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
      ⎕SE.UCMD'z←]Link.Add ',name,'.array ',name,'.var ',subname,'.var'  ⍝ can't add variable automatically when source=ns
      'link issue #194'assert'⊃''Added: ''⍷z'
      'link issue #194'assert'∧/⎕NEXISTS folder folder subfolder,¨''/array.apla'' ''/var.apla'' ''/var.apla'' '
      0 assert_create 0
      'link issue #173'assert'0=+/~3⊃⎕SE.Link.U.GetFileTiesIn ',name
      subname'var'⎕SE.Link.Fix newvarsrc
      subname'foo'⎕SE.Link.Fix newfoosrc
      subname'ns'⎕SE.Link.Fix newnssrc
      1 assert_create 1
      {}(⊂nssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂varsrc)QNPUT(subfolder,'/var.apla')1
      :If ~⎕SE.Link.U.IS181 ⋄ foonget←foosrc ⋄ :EndIf  ⍝ just wrote to file
      Breathe
      1 assert_create 0
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder
     
      ⍝ now try source=ns watch=none
      :If ~⎕SE.Link.U.IS181 ⋄ (foonget newfoonget)←(footok newfootok) ⋄ :EndIf  ⍝ start again from ns
      opts.source←'ns' ⋄ opts.watch←'none'
      {}opts ⎕SE.Link.Create name folder
      {}⎕SE.Link.Add subname,'.var'  ⍝ can't add variable automatically when source=ns
      1 assert_create 1
      'link issue #173'assert'0=+/~3⊃⎕SE.Link.U.GetFileTiesIn ',name
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
      {}(⊂nssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂foosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂varsrc)QNPUT(subfolder,'/var.apla')1
      :If ~⎕SE.Link.U.IS181 ⋄ foonget←foosrc ⋄ :EndIf  ⍝ just wrote to file
      Breathe
      1 assert_create 0
      {}⎕SE.Link.Break name ⋄ 3 ⎕NDELETE folder
     
      ⍝ link issue #160 try having items in the namespace already tied to items in the folder
      :If ~⎕SE.Link.U.IS181 ⋄ (foonget newfoonget)←(foosrc newfoosrc) ⋄ :EndIf  ⍝ start again from dir
      ⎕EX name ⋄ subname ⎕NS'' ⋄ 3 ⎕MKDIR subfolder
      {}(⊂nssrc)QNPUT(folder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂foosrc)QNPUT(folder,'/foo.aplf')1
      {}(⊂varsrc)QNPUT(folder,'/var.apla')1
      {}(⊂newnssrc)QNPUT(subfolder,'/ns.apln')1    ⍝ write ns first because ⎕SRC is deceiptful
      {}(⊂newfoosrc)QNPUT(subfolder,'/foo.aplf')1
      {}(⊂newvarsrc)QNPUT(subfolder,'/var.apla')1
      2(⍎name).⎕FIX'file://',folder,'/foo.aplf'
      2(⍎subname).⎕FIX'file://',subfolder,'/foo.aplf'
      opts.source←'auto' ⋄ opts.watch←'both'  ⍝ try source=auto
      assert'0=≢⎕SE.Link.Links'
      z←opts ⎕SE.Link.Create name folder
      'link issue #160'assert'1=≢⎕SE.Link.Links'
      'link issue #160'assert'(,⊂''dir'')≡⎕SE.Link.Links.source'
      1 assert_create 1
      'link issue #160'assert'({⍵[⍋⍵]}1 NSTREE name)≡{⍵[⍋⍵]} ',⍕Stringify¨(name,'.')∘,¨'foo' 'ns' 'sub' 'sub.foo' 'sub.ns' 'sub.var' 'var'
      'link issue #173'assert'(≢{(2≠⌊|⎕NC⍵)/⍵}0 NSTREE name)≡(+/~3⊃⎕SE.Link.U.GetFileTiesIn ',name,')'
      z←⎕SE.Link.Break name
      ⎕EX name ⋄ subname ⎕NS''
      2(⍎name).⎕FIX'file://',subfolder,'/foo.aplf'  ⍝ this time name from subfolder was linked into the root namespace
      opts.source←'dir' ⋄ opts.watch←'both'  ⍝ try source=dir
      assert'0=≢⎕SE.Link.Links'
      'link issue #160'assertError'opts ⎕SE.Link.Create name folder' 'Destination namespace not empty'
      assert'0=≢⎕SE.Link.Links'
      ⎕EX subname
      z←opts ⎕SE.Link.Create name folder
      'link issue #160'assert'1=≢⎕SE.Link.Links'
      1 assert_create 1
      'link issue #160'assert'({⍵[⍋⍵]}1 NSTREE name)≡{⍵[⍋⍵]} ',⍕Stringify¨(name,'.')∘,¨'foo' 'ns' 'sub' 'sub.foo' 'sub.ns' 'sub.var' 'var'
      z←⎕SE.Link.Break name
      opts.source←'ns' ⋄ opts.watch←'both'  ⍝ try source=ns
      2(⍎name).⎕FIX'file://',folder,'/foo.aplf'
      2(⍎subname).⎕FIX'file://',subfolder,'/foo.aplf'
      assert'0=≢⎕SE.Link.Links'
      assertError'opts ⎕SE.Link.Create name folder' 'Destination directory not empty'  ⍝ TODO : should recognise that the files are correctly linked to the namespace
      'link issue #160'assert'0=≢⎕SE.Link.Links'
      :If ⎕SE.Link.U.IS181 ⋄ 2(⍎name).⎕FIX NR name,'.foo' ⋄ 2(⍎subname).⎕FIX NR subname,'.foo'  ⍝ the ⎕NDELETE would make (0⎕INFO) produce ⎕NULL
      :Else ⋄ (foonget newfoonget)←(footok newfootok) ⋄ :EndIf  ⍝ start again from ns
      3 ⎕NDELETE folder
      z←opts ⎕SE.Link.Create name folder
      'link issue #160'assert'1=≢⎕SE.Link.Links'
      {}⎕SE.Link.Add name subname,¨⊂'.var'
      1 assert_create 1
      assert'({⍵[⍋⍵]}1 NSTREE name)≡{⍵[⍋⍵]} ',⍕Stringify¨(name,'.')∘,¨'foo' 'ns' 'sub' 'sub.foo' 'sub.ns' 'sub.var' 'var'
      z←⎕SE.Link.Break name
      assert'0=≢⎕SE.Link.Links'
      ⎕EX name ⋄ 3 ⎕NDELETE folder
     
      ⍝ test exporting arrays and sysvars
      (name,'.sub')⎕NS''
      name⍎'var←1 2 3 ⋄ sub.subvar←4 5 6'
      files←,'' 'sub/'∘.,'⎕AVU' '⎕CT' '⎕DCT' '⎕DIV' '⎕FR' '⎕IO' '⎕ML' '⎕PP' '⎕RL' '⎕RTL' '⎕USING' '⎕WX'
      files,←'var' 'sub/subvar'
      files←(folder,'/')∘,¨files,¨(⊂'.apla')
      ⍝(opts←⎕NS'').source←'ns'
      ⍝z←opts ⎕SE.Link.Create name folder
      ⎕SE.UCMD'z←]link.create -source=ns ',name,' ',folder
      'link issue #187'assert'~∨/''failed''⍷z'
      'link issue #187'assert'0∧.=⎕NEXISTS files'
      {}⎕SE.Link.Break name
      3 ⎕NDELETE folder
      ⍝opts.(arrays sysVars)←1
      ⍝z←opts ⎕SE.Link.Create name folder
      ⎕SE.UCMD'z←]link.create -source=ns -arrays=1 -sysvars ',name,' ',folder  ⍝ link issue #194
      'link issue #187'assert'~∨/''failed''⍷z'
      'link issue #187'assert'1∧.=⎕NEXISTS files'
      {}⎕SE.Link.Break name
      ⎕EX name ⋄ 3 ⎕NDELETE folder
     
      CleanUp folder name
      ok←1
    ∇




    ∇ ok←test_classic(folder name);foosrc;foobytes;read;goosrc;goobytes
      :If 82≠⎕DR''  ⍝ Classic interpreter required for classic QA !
          Log'Not a classic interpreter - not running ',⊃⎕SI
          ok←1 ⋄ :Return
      :EndIf
      3 ⎕MKDIR folder
     
      ⍝ check that key and friends are correctly translated in classic edition
      {}⎕SE.Link.Create name folder
      name'foo'⎕SE.Link.Fix foosrc←' res←foo arg' ' res←{⍺ ⍵}⎕U2338 arg'
      read←{tie←⍵ ⎕NTIE 0 ⋄ r←⎕NREAD tie 83 ¯1 0 ⋄ _←⎕NUNTIE tie ⋄ r}folder,'/foo.aplf'
      foobytes←32 114 101 115 ¯30 ¯122 ¯112 102 111 111 32 97 114 103 13 10 32 114 101 115 ¯30 ¯122 ¯112 123 ¯30 ¯115 ¯70 32 ¯30 ¯115 ¯75 125 ¯30 ¯116 ¯72 32 97 114 103 13 10
      assert'(read~13)≡(foobytes~13)'
     
      goobytes←1+@8⊢foobytes  ⍝ turn foo into goo
      goosrc←{'g'@6⊢⍵}¨@1⊢foosrc
      goobytes{tie←⍵ ⎕NCREATE 0 ⋄ _←⍺ ⎕NAPPEND tie 83 ⋄ 1:_←⎕NUNTIE tie}folder,'/goo.aplf'
      assert'goosrc≡⎕NR ''',name,'.goo'''
     
      {}⎕SE.Link.Break name
      CleanUp folder name
      ok←1
    ∇



    Stringify←{'''',((1+⍵='''')/⍵),''''}

    ∇ ok←test_gui(folder name);NL;NO_ERROR;NO_WIN;class;class2;classbad;ed;errors;foo;foo2;foobad;foowin;goo;mat;new;newdfn;ns;output;prompt;res;ride;tracer;ts;var;varsrc;windows;z
    ⍝ Test editor and tracer
      :If 82=⎕DR''  ⍝ GhostRider requires Unicode
          Log'Not a unicode interpreter - not running ',⊃⎕SI
          ok←1 ⋄ :Return
      :EndIf
     
      ride←NewGhostRider ⋄ (NL NO_WIN NO_ERROR)←ride.(NL NO_WIN NO_ERROR)
     
      ⎕MKDIR Retry⊢folder
      varsrc←⎕SE.Dyalog.Array.Serialise var←'hello' 'world' '!!!'
      foo←' res←foo arg' '⍝ this is foo[1]' ' res←arg' ' res←''foo''res'
      foo2←' res←foo arg' '⍝ this is foo[2]' ' res←arg' ' res←''foo2''res'
      foobad←' res←foo arg;' '⍝ this is foobad[1]' ' res←arg' ' res←''foobad''res'
      goo←' res←goo arg' '⍝ this is goo[1]' ' res←arg' ' res←''goo''res'
      class←':Class class' '    :Field Public Shared    var   ←    4 5 6' '    ∇ res   ←   dup    arg' '      :Access Public Shared' '      res←arg arg' '    ∇' ':EndClass'
      classbad←(¯1↓class),⊂':EndNamespace'
      class2←(1↑class),(⊂':Field Public Shared class2←1'),(1↓class)
      ns←':Namespace ns' '    var← 4 5 6' '    ∇ res←dup arg' '      res←arg arg' '    ∇' ':EndNamespace'
     
      ⍝ start with flattened repository
      ⎕MKDIR folder,'/sub'
      {}(⊂varsrc)QNPUT(folder,'/sub/var.apla')1
      {}(⊂foo)QNPUT(folder,'/sub/foo.aplf')1
      {}(⊂class)QNPUT(folder,'/sub/class.aplc')1
      output←ride.APL' ''{flatten:1}'' ⎕SE.Link.Create ',(Stringify name),' ',(Stringify folder)
      assert'(∨/''Linked:''⍷output)'
     
      ⍝ https://github.com/Dyalog/link/issues/48
      :If ⎕SE.Link.U.IS181≤⎕SE.Link.U.ISWIN  ⍝ because of Mantis 18655
          ride.Edit(name,'.new')(new←' res←new arg' ' res←''new''arg')
          'link issue #48'assert'new≡⊃⎕NGET ''',folder,'/new.aplf'' 1'  ⍝ with flatten, new objects should go into the root
          output←ride.APL' +⎕SE.Link.Expunge ''',name,'.new'' '
          'link issue #48'assert'(output≡''1'',NL)∧(0≡⎕NEXISTS ''',folder,'/new.aplf'')'  ⍝ with flatten, new objects should go into the root
      :EndIf
     
      ⍝ https://github.com/Dyalog/link/issues/49
      ride.Edit(name,'.foo')(goo)  ⍝ edit foo and type goo in it
      'link issue #49'assert'(,(↑foo),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '  ⍝ foo is untouched
      'link issue #49'assert'(,(↑goo),NL)≡ride.APL '' ',name,'.⎕CR ''''goo'''' '' '  ⍝ goo is defined
      'link issue #49'assert' foo≡⊃⎕NGET (folder,''/sub/foo.aplf'') 1 '   ⍝ foo is untouched
      'link issue #49'assert' goo≡⊃⎕NGET (folder,''/sub/goo.aplf'') 1 '   ⍝ goo is defined in the same directory as foo
      {}QNDELETE folder,'/sub/goo.aplf'
      'link issue #49'assert'('''')≡ride.APL '' ',name,'.⎕CR ''''goo'''' '' '  ⍝ goo is gone
     
      ⍝ now copy files in the root to have two namespace (root and root.sub)
      output←ride.APL' ⎕SE.Link.Break ',(Stringify name),' ⋄ ⎕EX ',(Stringify name)
      assert'(⊃''Unlinked''⍷output)'
      {}(⊂varsrc)QNPUT(folder,'/var.apla')1
      {}(⊂foo)QNPUT(folder,'/foo.aplf')1
      {}(⊂class)QNPUT(folder,'/class.aplc')1
      output←ride.APL'  ⎕SE.Link.Create ',(Stringify name),' ',(Stringify folder)
      assert'(⊃''Linked:''⍷output)'
     
     ⍝ link issue #190: edit a non-existing name, and change its name before fixing
      ride.Edit(name,'.doesntexist')('res←exists arg' 'res←arg')
      'link issue #190'assert'(''1'',NL)≡ride.APL ''0 3.1≡',name,'.⎕NC''''doesntexist'''' ''''exists'''' '' '
      'link issue #190'assert'0=≢⊃⎕NINFO⍠1⊢''',folder,'/doesntexist.*'' '
      'link issue #190'assert'1=≢⊃⎕NINFO⍠1⊢''',folder,'/exists.*'' '
     
     ⍝ link issue #196: whitespace not preserved on first fix
      ride.Edit(name,'.newdfn')(newdfn←,⊂'   newdfn   ←   {  ⍺ + ⍵  }   ')
      'link issue #196'assert'(¯3↓¨newdfn)≡⊃⎕NGET (folder,''/newdfn.aplf'') 1'  ⍝ Mantis 18758 trailing whitespaces are dropped
     
     ⍝ https://github.com/Dyalog/link/issues/154
      z←{(~⍵∊⎕UCS 13 10)⊆⍵}ride.APL']link.status'
      'link issue #154'assert'2=≢z'
      {}ride.APL')CLEAR'
      z←{(~⍵∊⎕UCS 13 10)⊆⍵}ride.APL']Link.Status'
      'link issue #154'assert'(1=≢z)∧(∨/''No active links''⍷∊z)'
      output←ride.APL']Link.Create ',(Stringify name),' ',(Stringify folder)
      assert'(⊃''Linked:''⍷output)'
     
     
     ⍝ https://github.com/Dyalog/link/issues/30
      tracer←⊃3⊃(prompt output windows errors)←ride.Trace name,'.foo 123.456'  ⍝ (prompt output windows errors) ← {wait} Trace expr
      {}(⊂goo)QNPUT(folder,'/foo.aplf')1  ⍝ change name of object in file
      'link issue #30'assert'('''')≡ride.APL '' ⎕CR ''''foo'''' '' '  ⍝ foo has disappeared
      'link issue #30'assert'(,(↑goo),NL)≡ride.APL '' ⎕CR ''''goo'''' '' '  ⍝ goo is there
      (prompt output windows errors)←ride.TraceResume tracer  ⍝ resume execution - not within assert to avoid calling TraceResume repeatedly
      'link issue #30'assert'1 ('' foo  123.456'',NL)(,tracer)(NO_ERROR)≡prompt output windows errors'        ⍝ traced code has NOT changed - sounds reasonable
      'link issue #30'assert'('''')≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '  ⍝ foo has disappeared
      'link issue #30'assert'(,(↑goo),NL)≡ride.APL '' ',name,'.⎕CR ''''goo'''' '' '  ⍝ goo is there
      ⍝ do the same thing without modifying the name of the function
      {}(⊂foo)QNPUT(folder,'/foo.aplf')1  ⍝ put back original foo
      'link issue #30'assert'('''')≡ride.APL '' ',name,'.⎕CR ''''goo'''' '' '  ⍝ goo is gone
      'link issue #30'assert'(,(↑foo),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '  ⍝ foo is back
      tracer←⊃3⊃(prompt output windows errors)←ride.Trace name,'.foo 123.456'  ⍝ (prompt output windows errors) ← {wait} Trace expr
      {}(⊂foo2)QNPUT(folder,'/foo.aplf')1  ⍝ change name of object in file
      'link issue #30'assert'(,(↑foo2),NL)≡ride.APL '' ⎕CR ''''foo'''' '' '  ⍝ foo has changed
      (prompt output windows errors)←ride.TraceResume tracer  ⍝ resume execution - not within assert to avoid calling TraceResume repeatedly
      'link issue #30'assert'1 ('' foo2  123.456'',NL)(,tracer)(NO_ERROR)≡prompt output windows errors'        ⍝ ⎕BUG? traced code HAS changed although the tracer window still displays the old code
      'link issue #30'assert'(,(↑foo2),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '  ⍝ goo is there
      ⍝ restore what we've done
      {}(⊂foo)QNPUT(folder,'/foo.aplf')1  ⍝ put back original foo
      'link issue #30'assert'(,(↑foo),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '  ⍝ foo is back
      'link issue #30'assert'(''0'',NL)≡ride.APL'' ⎕NC⊂''''foo2'''' '' '
     
     ⍝ https://github.com/Dyalog/link/issues/35
      ride.Edit(name,'.foo')goo   ⍝ change name in editor
      'link issue #35'assert'(,(↑goo),NL)≡ride.APL '' ',name,'.⎕CR ''''goo'''' '' '  ⍝ goo is defined
      'link issue #35'assert' goo≡⊃⎕NGET (folder,''/goo.aplf'') 1 '   ⍝ goo is correctly linked
      'link issue #35'assert'(,(↑foo),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '  ⍝ foo hasn't changed
      'link issue #35'assert' foo≡⊃⎕NGET (folder,''/foo.aplf'') 1 '  ⍝ foo hasn't changed
      ride.Edit(name,'.foo')foo2  ⍝ change original function
      'link issue #35'assert'(,(↑foo2),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '  ⍝ foo is foo2
      'link issue #35'assert' foo2≡⊃⎕NGET (folder,''/foo.aplf'') 1 '  ⍝ foo is correctly linked
      res←ride.APL'+⎕SE.Link.Expunge ''',name,'.goo'' '  ⍝ delete goo
      'link issue #35'assert'res≡''1'',NL'
      ride.Edit(name,'.foo')foo  ⍝ put back original foo
      'link issue #35'assert' foo≡⊃⎕NGET (folder,''/foo.aplf'') 1 '  ⍝ foo is correctly linked
      'link issue #35'assert' ~⎕NEXISTS folder,''/goo.aplf'' '   ⍝ goo does not exist
     
     ⍝ https://github.com/Dyalog/link/issues/83
      '-'ride.Edit'mat'(mat←'first row' 'second row')
      'link issue #83'assert' (,(↑mat),NL) ≡ ride.APL''mat'' '
     
     ⍝ https://github.com/Dyalog/link/issues/109
      ed←ride.EditOpen name,'.foo'
      res←ed ride.EditFix foobad
      'link issue #109'assert'(9=⎕NC''res'')∧(''Task''≡res.type)∧(''Save file content''≡res.text)∧(''Fix as code in the workspace''≡28↑(res.index⍳100)⊃res.options)'
      100 ride.Reply res
      res←ride.Wait ⍬ 1
      'link issue #109'assert'(res[1 2 4]≡¯1 '''' NO_ERROR)∧(1=≢3⊃res)'
      res←⊃3⊃res
      'link issue #109'assert'(9=⎕NC''res'')∧(''Options''≡res.type)∧(''Can''''t Fix''≡res.text)'
      ride.Reply res  ⍝ just close the error message
      ed.saved←⍬
      res←ride.Wait ⍬ 1  ⍝ should ReplySaveChanges with error
      'link issue #109'assert'res≡¯1 '''' (,ed) NO_ERROR'
      'link issue #109'assert'ed.saved≡1'  ⍝ fix failed (saved≠0)
      ride.CloseWindow ed
      'link issue #109'assert'(,(↑foo),NL)≡ride.APL'' ',name,'.⎕CR''''foo'''' '' '  ⍝ Mantis 18412 foo has not changed within workspace because fix has failed
      'link issue #109'assert'foobad≡⊃⎕NGET(folder,''/foo.aplf'')1'  ⍝ but file correctly has new code
      :If ⎕SE.Link.U.IS181≤⎕SE.Link.U.ISWIN  ⍝ Mantis 18762
          ride.Edit(name,'.foo')foo2  ⍝ check that foo is still correctly linked
          'link issue #109'assert'(,(↑foo2),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '
          'link issue #109'assert' foo2≡⊃⎕NGET (folder,''/foo.aplf'') 1 '
          ride.Edit(name,'.foo')foo  ⍝ put back original foo
          'link issue #109'assert'(,(↑foo),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '
          'link issue #109'assert' foo≡⊃⎕NGET (folder,''/foo.aplf'') 1 '
      :EndIf
     
      ⍝ https://github.com/Dyalog/link/issues/153
      'link issue #153'assert'~⎕NEXISTS folder,''/text.apla'' '
      {}ride.APL name,'.text←''hello'''
      ed←ride.EditOpen name,'.text'
      res←ed ride.EditFix'hello world'
      ride.CloseWindow ed
      'link issue #153'assert'1≡res'  ⍝ fix succeeded
      'link issue #153'assert' (''hello world'',NL) ≡ ride.APL name,''.text'' '
      'link issue #153'assert'~⎕NEXISTS folder,''/text.apla'' ' ⍝ file must NOT be created
      {}ride.APL')ERASE ',name,'.text'
      'link issue #153'assert'~⎕NEXISTS folder,''/text.aplf'' '
      {}ride.APL name,'.⎕FX ''text'' ''⎕←1 2 3'''
      ed←ride.EditOpen name,'.text'
      res←ed ride.EditFix'res←text' 'res←4 5 6'
      ride.CloseWindow ed
      'link issue #153'assert'1≡res'  ⍝ fix succeeded
      'link issue #153'assert' (''4 5 6'',NL) ≡ ride.APL name,''.text'' '
      'link issue #153'assert' ''res←text'' ''res←4 5 6'' ≡ ⊃⎕NGET (folder,''/text.aplf'') 1 ' ⍝ file must NOT be created
     
       ⍝ link issue #139 and #86 - Fixed by replacing ⎕SE.Link.U.Fix by ⎕SE.Link.U.Sniff
      {}ride.APL'#.FIXCOUNT←0'  ⍝ just write the file
      {}(⊂':Namespace FixCount' '#.FIXCOUNT+←1' ':EndNamespace')QNPUT(folder,'/FixCount.apln')1  ⍝ could produce two Notify events (created + changed), where each one fix in U.DetermineAplName, plus the actual QFix
      'link issue #139'assert' (''1'',NL) ≡ ride.APL ''#.FIXCOUNT'' '
      {}ride.APL'#.FIXCOUNT←0'  ⍝ force a Notify event
      {}ride.APL'⎕SE.Link.Notify ''changed'' (''',folder,'/FixCount.apln'') '  ⍝ spurious notify when no change has happened
      'link issue #139'assert' (''0'',NL) ≡ ride.APL ''#.FIXCOUNT'' '
      {}ride.APL'#.FIXCOUNT←0'    ⍝ change through editor
      ed←ride.EditOpen name,'.FixCount'
      res←ed ride.EditFix':Namespace FixCount' '#.FIXCOUNT+←1' '' ':EndNamespace'
      100 ride.Reply res
      ed.saved←⍬
      res←ride.Wait ⍬ 1
      assert'res ≡ 1 '''' (,ed) (NO_ERROR)'
      assert'ed.saved≡0'  ⍝ save OK
      ride.CloseWindow ed
      'link issue #139'assert' (''1'',NL) ≡ ride.APL ''#.FIXCOUNT'' '
      {}ride.APL'#.FIXCOUNT←0'   ⍝ force a Refresh
      {}ride.APL' ''{source:''''dir''''}'' ⎕SE.Link.Refresh ',name
      'link issue #86'assert' (''0'',NL) ≡ ride.APL ''#.FIXCOUNT'' '
      {}ride.APL' ⎕SE.Link.Expunge ''',name,'.FixCount'' '
      {}ride.APL' ⎕EX''#.FIXCOUNT'' '
     
     
      ⍝ https://github.com/Dyalog/link/issues/129 https://github.com/Dyalog/link/issues/148
      :If 0 ⍝ requires fix to Mantis 18408
          res←ride.APL' (+1 3 ⎕STOP ''',name,'.foo'')(+1 2⎕TRACE ''',name,'.foo'')(+2 3⎕MONITOR ''',name,'.foo'') '
          'link issues #129 #148'assert'res≡'' 1 3  1 2  2 3 '',NL'
          ride.Edit(name,'.foo')foo2
          'link issues #129 #148'assert'(,(↑foo2),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '
          'link issues #129 #148'assert' foo2≡⊃⎕NGET (folder,''/foo.aplf'') 1 '
          res←ride.APL' (+ ⎕STOP ''',name,'.foo'')(+⎕TRACE ''',name,'.foo'')(+⊣/⎕MONITOR ''',name,'.foo'') '
          'link issues #129 #148'assert'res≡'' 1 3  1 2  2 3 '',NL'
          ride.Edit(name,'.foo')foo
          'link issues #129 #148'assert'(,(↑foo),NL)≡ride.APL '' ',name,'.⎕CR ''''foo'''' '' '
          'link issues #129 #148'assert' foo≡⊃⎕NGET (folder,''/foo.aplf'') 1 '
          res←ride.APL' (+⍬ ⎕STOP ''',name,'.foo'')(+⍬ ⎕TRACE ''',name,'.foo'')(+⍬ ⎕MONITOR ''',name,'.foo'') '
          'link issues #129 #148'assert'res≡''      '',NL'
      :EndIf
     
     ⍝ https://github.com/Dyalog/link/issues/143
      :If 0 ⍝ requires fix to Mantis 18409, 18410 and 18411
          ed←ride.EditOpen name,'.class'
          res←ed ride.EditFix classbad
          'link issue #143'assert'(9=⎕NC''res'')∧(''Task''≡res.type)∧(''Save file content''≡res.text)∧(''Fix as code in the workspace''≡28↑(res.index⍳100)⊃res.options)'
          100 ride.Reply res
          res←ride.Wait ⍬ 1
          'link issue #143'assert'(res[1 2 4]≡¯1 '''' NO_ERROR)∧(1=≢3⊃res)'
          res←⊃3⊃res
          'link issue #143'assert'(9=⎕NC''res'')∧(''Options''≡res.type)∧(''Can''''t Fix''≡res.text)'
          ride.Reply res  ⍝ just close the error message
          ed.saved←⍬
          res←ride.Wait ⍬ 1  ⍝ should ReplySaveChanges with error
          'link issue #143'assert'res≡¯1 '''' (,ed) NO_ERROR'
          'link issue #143'assert'ed.saved≡1'  ⍝ fix failed (saved≠0)
          ride.CloseWindow ed
          'link issue #143'assert'(,(↑classbad),NL)≡ride.APL'' ↑⎕SRC ',name,'.class '' '   ⍝ Mantis 18412 class has changed within workspace even though fix has failed
          'link issue #143'assert'classbad≡⊃⎕NGET(folder,''/class.aplc'')1'  ⍝ file correctly has new code
          ride.Edit(name,'.class')class  ⍝ put back original class
          'link issue #143'assert'(,(↑class),NL)≡ride.APL'' ↑⎕SRC ',name,'.class '' '
          'link issue #143'assert'class≡⊃⎕NGET(folder,''/class.aplc'')1'
      :EndIf
     
      ⍝ https://github.com/Dyalog/link/issues/152 - attempt to change the name and script type of a class in editor
      ride.Edit(name,'.sub.class')(ns) ⍝ change name and script type
      assert'(,(↑ns),NL)≡ride.APL '' ↑⎕SRC ',name,'.sub.ns '' '  ⍝ ns is defined
      assert' ns≡⊃⎕NGET (folder,''/sub/ns.apln'') 1 '   ⍝ ns is correctly linked
      assert'(,(↑class),NL)≡ride.APL '' ↑⎕SRC ',name,'.sub.class '' '  ⍝ class hasn't changed
      assert' class≡⊃⎕NGET (folder,''/sub/class.aplc'') 1 '  ⍝ class hasn't changed
      ride.Edit(name,'.sub.class')(class2) ⍝ check that class is still linked
      assert'(,(↑class2),NL)≡ride.APL '' ↑⎕SRC ',name,'.sub.class '' '  ⍝ class has changed
      assert' class2≡⊃⎕NGET (folder,''/sub/class.aplc'') 1 '  ⍝ class has changed
      ⎕NDELETE folder,'/sub/ns.apln'
      assert' (''0'',NL)≡ride.APL '' ⎕NC ''''',name,'.sub.ns'''' '' '
      ride.Edit(name,'.sub.class')(class) ⍝ put back original class
      assert'(,(↑class),NL)≡ride.APL '' ↑⎕SRC ',name,'.sub.class '' '
      assert' class≡⊃⎕NGET (folder,''/sub/class.aplc'') 1 '
     
      output←ride.APL'⎕SE.Link.Break ',(Stringify name)
      assert'(∨/''Unlinked''⍷output)'
      CleanUp folder name
      ok←1
    ∇

    ∇ loops RunTestThread(folder name);sub;z
      ⎕EX name ⋄ 3 ⎕NDELETE folder ⋄ 3 ⎕MKDIR folder
      (⊂⎕SE.Dyalog.Array.Serialise 2 3 4⍴0)⎕NPUT folder,'/var.apla'
      (⊂'r←foo arg' 'r←''foo'' arg')⎕NPUT folder,'/foo.aplf'
      (⊂'r←(foo op) arg' 'r←''op'' foo arg')⎕NPUT folder,'/op.aplo'
      (⊂':Interface api' '∇ r←foo arg' '∇' ':EndInterface')⎕NPUT folder,'/api.apli'
      (⊂':Class base:,api' ':Field Public Shared base←1' '∇ r←foo arg' ':Access Public Shared' 'r←''foo'' arg' '∇' ':EndClass')⎕NPUT folder,'/base.aplc'
      (⊂':Class main:base,api' ':Field Public Shared main←1' ':EndClass')⎕NPUT folder,'/main.aplc'
      :While 0≤loops←loops-1
          z←⎕SE.Link.Create name folder
          assert'~∨/''failed''⍷z'
          z←⎕SE.Link.Refresh name
          assert'~∨/''failed''⍷z'
          ⎕MKDIR folder,'/sub'
          assert'9=⎕NC',Stringify sub←name,'.sub'
          (⍎sub).newvar←⎕TS
          (⍎sub).⎕FX'r←goo arg' 'r←''goo'' arg'
          z←⎕SE.Link.Add sub∘,¨'.goo' '.newvar'
          assert'~∨/''Not found''⍷z'
          assert'∧/⎕NEXISTS',⍕Stringify¨(folder,'/sub/')∘,¨'goo.aplf' 'newvar.apla'
          z←sub ⎕SE.Link.Fix':Namespace ns' 'ns←1' ':EndNamespace'
          assert'z∧⎕NEXISTS',Stringify folder,'/sub/ns.apln'
          z←⎕SE.Link.Refresh name
          assert'~∨/''failed''⍷z'
          z←⎕SE.Link.Expunge sub
          assert'z'
          assert'~⎕NEXISTS',Stringify folder,'/sub/'
          {}⎕SE.Link.Break name
          ⎕EX name
      :EndWhile
      3 ⎕NDELETE folder
    ∇

    ∇ ok←test_threads(folder name);dir1;dir2;folders;loops;names;threads;warn
      loops←10 ⋄ threads←10
      ⍝ disable warnings which happen because the Notify caused the Add or the Expunge may happen after the Break - which is ok because it would do nothing anyways
      (⎕SE.Link.U.WARN warn)←(0 ⎕SE.Link.U.WARN)
      ⍝ run once to avoid triggering lots of errors for failures not related to multithreading
      1 RunTestThread folder name
      ⍝ run many times
      folders←(folder,'/link')∘,¨⍕¨⍳threads
      names←(name,'.link')∘,¨⍕¨⍳threads
      ⎕TSYNC loops∘RunTestThread&¨↓⍉↑folders names
      ⎕SE.Link.U.WARN←warn
      ok←1
    ∇


    ∇ ok←test_watcherror(folder name);i;link;n;src;warn
      :If ~⎕SE.Link.Watcher.CanWatch
          Log'FileSystemWatcher not available - not running ',⊃⎕SI
          ok←1
          :Return
      :EndIf
      3 ⎕MKDIR src←folder,'/src'
      {(⊂'foo',⍵)⎕NPUT(src,'/foo',⍵,'.aplf')1}¨⍕¨⍳n←10000
      3 ⎕MKDIR link←folder,'/link'
      (warn ⎕SE.Link.U.WARN)←(⎕SE.Link.U.WARN 1) ⋄ ⎕SE.Link.U.WARNLOG/⍨←0
      {}⎕SE.Link.Create name link
      link ⎕NMOVE⍠1⊢src,'/foo*.aplf'
      :If ⎕SE.Link.Watcher.DOTNET>⎕SE.Link.Watcher.DOTNETCORE ⍝ DOTNETCORE does not support FileSystemWatcher errors yet ?
          'link issue #120'assert'~0∊⍴''FileSystemWatcher error on linked directory''⎕S ''\0''⊢⎕SE.Link.U.WARNLOG'
      :EndIf
      'link issue #120'assert'n≠≢',name,'.⎕NL ¯3.1'
      {}⎕SE.Link.Refresh name
      'link issue #120'assert'n=≢',name,'.⎕NL ¯3.1'
      ⎕SE.Link.U.WARN←warn
      ⎕SE.Link.Break name
      CleanUp folder name
      ok←1
    ∇


    :EndSection  test_functions










    :Section GhostRider QAs
    GhostRider←⎕NULL
    ⍝ WARNING we Import the GhostRider instead of Link.Create because some QAs check ≢⎕SE.Link.Links.
    ∇ file←GetSourceFile
      file←4⊃5179⌶⊃⎕SI
    ∇

    ∇ instance←NewGhostRider;Env;env;file;msg;names;ok
      :If GhostRider≡⎕NULL
          file←(⊃⎕NPARTS GetSourceFile),'GhostRider/GhostRider.dyalog'  ⍝ in the directory of the git submodule
          ⎕EX'GhostRider'  ⍝ GhostRider≡⎕NULL prevents ⎕SE.Link.Create from creating the namespace
          :Trap 0 ⋄ names←2 ⎕FIX'file://',file
          :Else ⋄ names←0⍴⊂''
          :EndTrap
          :If names≢,⊂'GhostRider'   ⍝ GhostRider correctly fixed
          :OrIf 9.4≠⎕NC⊂'GhostRider' ⍝ GhostRider class present
              GhostRider←⎕NULL
              msg←'GhostRider class not found in "',file,'"',⎕UCS 13
              msg,←'Try : git submodule update --init --recursive'
              msg ⎕SIGNAL 999
          :EndIf
      :EndIf
      Env←{⍵,'="',(2 ⎕NQ'.' 'GetEnvironment'⍵),'"'}
      env←⍕Env¨'SESSION_FILE' 'MAXWS' 'DYALOGSTARTUPSE' 'DYALOGSTARTUPKEEPLINK' 'DYALOG_NETCORE'
      instance←⎕NEW GhostRider env
      {}instance.APL'⎕SE.Link.Watcher.CRAWLER←',⍕⎕SE.Link.Watcher.CRAWLER  ⍝ because ⎕SE.Link.Test.Run sets it
      {}instance.APL'⎕SE.Link.Watcher.DOTNET←',⍕⎕SE.Link.Watcher.DOTNET  ⍝ because ⎕SE.Link.Test.Run sets it
      {}instance.APL'⎕SE.Link.DEBUG←0 ⋄ ⎕SE.Link.U.SHOWMSG←0'  ⍝ keep quiet
    ∇
    :EndSection





    :Section Setup and Utils

    ∇ r←Setup(folder name);udebug
      r←'' ⍝ Run will abort if empty
      :If ~⎕SE.Link.Watcher.DOTNET
          Log'.Net Framework or .NetCore required to run tests'
          :Return
      :ElseIf ~⎕SE.Link.U.IS181
          Log'Not running Dyalog v18.1 or later - some tests will be skipped'
      :EndIf
      :If 0≠⎕NC'⎕SE.Link.Links'
      :AndIf 0≠≢⎕SE.Link.Links
          Log'Please break all links and try again.'
          ⎕←⎕SE.UCMD']Link.Status'
          ⎕←'      ]Link.Break -all    ⍝ to break all links'
          :Return
      :EndIf
      :If 0≠⎕NC name
          ⍝⎕←name,' exists. Expunge? [Y|n]'
          ⍝:If 'yYjJ1 '∊⍨⊃⍞~' '
          ⎕EX name
          ⍝:Else
          ⍝    ⎕→name,' must be non-existent.'
          ⍝    :Return
          ⍝:EndIf
      :EndIf
      :If ~0∊⍴folder  ⍝ specific folder
          folder←∊1 ⎕NPARTS folder,(0=≢folder)/(739⌶0),'/linktest'
          :If ⎕NEXISTS folder
              Log folder,' exists. Clean it out? [Y|n] '
              :If 'yYjJ1 '∊⍨⊃⍞~' '
                  3 ⎕NDELETE Retry⊢folder
              :Else
                  Log'Directory must be non-existent.'
                  :Return
              :EndIf
          :EndIf
      :Else  ⍝ generate a new directory - avoids prompting for deletion
          folder←CreateTempDir 0
      :EndIf
      :If USE_ISOLATES
          :If 9.1≠#.⎕NC⊂'isolate'
              'isolate'#.⎕CY'isolate.dws'
          :EndIf
          {}#.isolate.Reset 0  ⍝ in case not closed properly last time
          {}#.isolate.Config'processors' 1 ⍝ Only start 1 slave
          #.SLAVE←#.isolate.New''
          QNDELETE←{⍺←⊢ ⋄ ⍺ #.SLAVE.⎕NDELETE ⍵}
          QNPUT←{⍺←⊢ ⋄ ⍺ #.SLAVE.⎕NPUT ⍵ ⋄ ⎕DL 0.001}  ⍝ ensure QNPUTS are not too tight for filewatcher
      :Else
          #.SLAVE←⎕NS''
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
          assert'4=#.SLAVE.(2+2)' ⍝ Make sure it finished what it was doing
          {}#.isolate.Reset 0
          #.SLAVE←⎕NULL
      :EndIf
    ∇

    ∇ CleanUp(folder name);z;m
    ⍝ Tidy up after test
      ⍝⎕SE.Link.DEBUG←0
      z←⎕SE.Link.Break name
      assert'{6::1 ⋄ 0=≢⎕SE.Link.Links}⍬'
      z←⊃¨5176⌶⍬ ⍝ Check all links have been cleared
      :If ∨/m←((≢folder)↑¨z)∊⊂folder
          Log'Links not cleared:'(⍪m/z)
      :EndIf
      3 ⎕NDELETE folder
      #.⎕EX name
    ∇


    ∇ {title}Log msg
      :If 900⌶⍬ ⋄ title←⊃1↓⎕XSI ⋄ :EndIf
      ⎕←1↓⍤1⊢⍕(title,':')msg ⍝ This might get more sophisticated someday
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
      :If ⎕SE.Link.Watcher.DOTNET ⋄ ⎕DL 0.1  ⍝ FileSystemWatcher
      :Else ⋄ ⎕DL 2.1×⎕SE.Link.Watcher.T_PERIOD ⍝ ensure two runs
      :EndIf
    ∇

      assertMsg←{
          msg←⍎⍵
          ('assertion failed: "',msg,'" instead of "',⍺,'" from: ',⍵)⎕SIGNAL 11/⍨~∨/⍺⍷msg
      }

    ∇ {txt}←{msg}assertError args;errmsg;errno;expr;ok
      :If 900⌶⍬ ⋄ msg←⊢ ⋄ :EndIf
      (expr errmsg errno)←(⊆args),(≢⊆args)↓'' ''⎕SE.Link.U.ERRNO
      :Trap errno
          {}⍎expr
          ok←1
      :Else
          ok←0
          txt←msg assert'∨/errmsg⍷⊃⎕DM'  ⍝ always true if errmsg≡''
      :EndTrap
      :If ok ⋄ txt←msg assert'0' ⋄ :EndIf
    ∇
    ∇ {txt}←{msg}assert args;clean;expr;maxwait;end;timeout;txt
      ⍝ Asynchronous assert: We don't know how quickly the FileSystemWatcher will do something
     
      :If STOP_TESTS
          Log'STOP_TESTS detected...'
          (1+⊃⎕LC)⎕STOP'assert'
      :EndIf
     
      (expr clean)←2↑(⊆args),⊂''
      end←3000+3⊃⎕AI ⍝ allow three seconds of wait time
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
          Log'Warning: ',txt,(~0∊⍴clean)/'- Recovered via ',clean
          :Return
      :EndIf
     
      ⍝ No recovery, or recovery failed
      :If ASSERT_ERROR
          txt ⎕SIGNAL 11
      :Else ⍝ Just muddle on, not recommended!
          Log txt
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
      r←≢bytes←{⍵-256×⍵≥128}'UTF-8'⎕UCS∊(⊃text),¨⊂⎕UCS 13 10
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
      names←trad ⎕SE.Link.U.ListNs ns
    ∇

    ∇ to NSMOVE from;name;nl
      :If ~0∊⍴⎕SE.Link.U.ListNames to ⋄ 'Destination must be empty'⎕SIGNAL 11 ⋄ :EndIf
      :For name :In nl←⎕SE.Link.U.ListNames from
          :If (⌊|from.⎕NC⊂name)∊2 9  ⍝ array (or scalar ref)
              name(to{⍺⍺⍎⍺,'←⍵'})from⍎name
          :Else  ⍝ function or operator
              to.⎕FX from.⎕NR name
          :EndIf
      :EndFor
      from.⎕EX nl
    ∇

    NR←{⍺←⊢ ⋄ ⍺ ⎕SE.Link.U.GetAplSource ⍵} ⍝ cover for ⎕NR

    ∇ nsname Watch watch;link
    ⍝ pause/resume file watching
      :If 0∊⍴link←⎕SE.Link.U.LookupRef(⍎nsname)
          ⎕SIGNAL 11
      :EndIf
      watch ⎕SE.Link.Watcher.Pause link
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
    ⍝ v2.1-alpha2: fastLoad=1:650  ⋄ fastLoad=0:1250
    ⍝ v2.1-alpha3: fastLoad=1:850  ⋄ fastLoad=0:1600
      :If 900⌶⍬ ⋄ opts←⍬ ⋄ :EndIf
      (fastload profile clear)←opts,(≢opts)↓1 0 0
      name←'#.largelink'
      :If temp←0∊⍴folder
          folder←CreateTempDir 0
          Log'building ',folder,' ...'
          clear build_large folder
      :EndIf
      filetype←⊃1 ⎕NINFO⍠1⍠'Recurse' 1⊢folder,'/*'
      dirs←filetype+.=1 ⋄ files←filetype+.=2
      opts←⎕NS ⍬
      opts.source←'dir'
      opts.fastLoad←fastload
      Log'linking ',name,' ...'
      :If profile ⋄ ⎕PROFILE¨'clear' 'start' ⋄ :EndIf
      time←3⊃⎕AI
      opts ⎕SE.Link.Create name folder
      time←(3⊃⎕AI)-time
      :If profile ⋄ ⎕PROFILE'stop' ⋄ :EndIf
      Log ⎕SE.Link.Status name
      Log'cleaning up...'
      ⎕EX name
      {}⎕SE.Link.Break name
      :If temp
          ⎕DL 1
          3 ⎕NDELETE folder
      :EndIf
    ∇





    ∇ {step}try_filecrawler(name folder);foofile;foofile2
    ⍝ manual testing of file crawler
      :If 900⌶⍬ ⋄ step←0 ⋄ :EndIf   ⍝ step-by-step crawling
      :If (0≠⎕NC name)∨(⎕NEXISTS folder) ⋄ ⎕SIGNAL 11 ⋄ :EndIf
      ⎕EX name ⋄ 3 ⎕MKDIR folder
      ⎕SE.Link.Watcher.T_PERIOD←1
      ⎕SE.Link.Watcher.CRAWLER←1
      ⎕SE.Link.Watcher.DOTNET←0
      {}⎕SE.Link.Create name folder
      ⍝{}⎕SE.Link.Pause ⎕SE.Link.Links
      :If step
          ⎕SE.Link.Watcher.TIMER←⎕NULL
          ⎕SE.Link.Watcher.T_WORKLOAD←9999999  ⍝ never time out until job finished
          ⎕SE.Link.Watcher.T_GRANULARITY←9999999  ⍝ never overload the timer
      :EndIf
      ⎕SE.Link.DEBUG←1
      ⎕SE.Link.Watcher.CrawlerEvent 0
      (⊂'this is total garbage !!!!;;;;')⎕NPUT folder,'/garbage.ini'
      ⎕SE.Link.Watcher.CrawlerEvent 0
      (⊂'foo')⎕NPUT foofile←folder,'/foo.aplf'
      ⎕SE.Link.Watcher.CrawlerEvent 0
      (⊂'res←foo arg' 'res←''foo'' arg')⎕NPUT foofile 1
      ⎕SE.Link.Watcher.CrawlerEvent 0
      (⊂'res←foo arg' 'res←''foo'' arg')⎕NPUT foofile 1
      ⎕SE.Link.Watcher.CrawlerEvent 0
      (foofile2←folder,'/foo2.aplf')⎕NMOVE foofile
      ⎕SE.Link.Watcher.CrawlerEvent 0
      (⊂'res←goo arg' 'res←''goo'' arg')⎕NPUT foofile 1
      ⎕SE.Link.Watcher.CrawlerEvent 0
      ⎕NDELETE foofile foofile2
      ⎕SE.Link.Watcher.CrawlerEvent 0
      ⎕SE.Link.Break name
      ⎕EX name ⋄ 3 ⎕NDELETE folder
    ∇


    ∇ {debug}try_newcrawler(name folder);Crawl;NS;NS2;debug;dop;dop2;folders;link;mat;mat2;matsrc;matsrc2;opts;sub2;sub6;subs;tradfn;tradfn2
      :If 0=⎕NC'debug' ⋄ debug←0⊣×⎕SE.Link.U.debug ⋄ :EndIf
      ⍝:If (0≠⎕NC name)∨(⎕NEXISTS folder)∨(0≠≢⎕SE.Link.Links) ⋄ ⎕SIGNAL 11 ⋄ :EndIf
      assert'0=≢⎕SE.Link.Links'
      ⎕SE.Link.Watcher.(CRAWLERLINKS/⍨←0)
      ⎕EX name ⋄ 3 ⎕NDELETE folder ⋄ 3 ⎕MKDIR folder
      opts←⎕NS ⍬ ⋄ opts.watch←'none'  ⍝ not only to disable watcher, but also to prevent tying source to files
      {}opts ⎕SE.Link.Create name folder
      assert'1=≢⎕SE.Link.Links'
      link←⊃⎕SE.Link.Links
      Crawl←{
          ⎕←0 0⍴⍣(~⍵)⊢'before'{⍺ ⍵}before←⎕SE.Link.Watcher.({⍵[I_FILE I_NAME;]}⊃CRAWLERLINKS[C_ITEMS;])
          ⎕←0⍴⍣(⍵)⊢'====================================='
          _←⎕SE.Link.Watcher.Crawl link
          ⎕←0 0⍴⍣(~⍵)⊢'after'{⍺ ⍵}after←⎕SE.Link.Watcher.({⍵[I_FILE I_NAME;]}⊃CRAWLERLINKS[C_ITEMS;])
      }
      ⎕SE.Link.Watcher.Crawl link
      assert'0∧.=≢¨( 1 NSTREE name)(1 NTREE folder)'
      ⍝ create files
      3 ⎕MKDIR¨(folder,'/')∘,¨'sub1' 'sub1/subsub1'
      (⊂matsrc←⎕SE.Dyalog.Array.Serialise mat←⍳3 4)⎕NPUT folder,'/sub1/mat.apla'
      (⊂tradfn←'   res ← tradfn (arg1 arg2)   ' '   res ← arg1 arg2   ')⎕NPUT folder,'/sub1/tradfn.aplf'
      (⊂dop←,⊂'dop←{⍺ ⍺⍺ ⍵⍵ ⍵}')⎕NPUT folder,'/sub1/dop.aplo'
      NS←{(':Namespace ',⍵)'mat←⍳3 4' '∇   res ← tradfn (arg1 arg2)   ' '   res ← arg1 arg2   ' '∇' 'dop←{⍺ ⍺⍺ ⍵⍵ ⍵}' ':EndNamespace'}
      (⊂NS'ns1')⎕NPUT folder,'/ns1.apln'
      Crawl debug
      assert'6∧.=≢¨( 1 NSTREE name)(1 NTREE folder)'
      ⍝ create apl items
      sub2←⍎(name,'.sub2')⎕NS'' ⋄ (name,'.sub2.subsub2')⎕NS''
      sub2.mat←mat
      sub2.⎕FX¨tradfn dop
      (⍎name).⎕FIX NS'ns2'
      Crawl debug
      assert'12∧.=≢¨( 1 NSTREE name)(1 NTREE folder)'
      ⍝ modify files
      (⊂matsrc2←⎕SE.Dyalog.Array.Serialise mat2←⍳2 3 4)⎕NPUT(folder,'/sub1/mat.apla')1
      (⊂tradfn2←'   res2 ← tradfn (arg1 arg2)   ' '   res2 ← arg1 arg2   ')⎕NPUT(folder,'/sub1/tradfn.aplf')1
      (⊂dop2←,⊂'dop←{⍵ ⍵⍵ ⍺⍺ ⍺}')⎕NPUT(folder,'/sub1/dop.aplo')1
      NS2←{(':Namespace ',⍵)'mat←⍳2 3 4' '∇   res2 ← tradfn (arg1 arg2)   ' '   res2 ← arg1 arg2   ' '∇' 'dop←{⍵ ⍵⍵ ⍺⍺ ⍺}' ':EndNamespace'}
      (⊂NS2'ns1')⎕NPUT(folder,'/ns1.apln')1
      Crawl debug
      assert'12∧.=≢¨( 1 NSTREE name)(1 NTREE folder)'
      ⍝ modify apl items
      sub2.mat←mat2
      sub2.⎕FX¨tradfn2 dop2
      (⍎name).⎕FIX NS2'ns2'
      Crawl debug
      assert'12∧.=≢¨( 1 NSTREE name)(1 NTREE folder)'
      ⍝ delete files
      3 ⎕NDELETE¨(folder,'/')∘,¨'sub1' 'ns1.apln'
      Crawl debug
      assert'6∧.=≢¨( 1 NSTREE name)(1 NTREE folder)'
      ⍝ delete apl items
      ⎕EX(name,'.')∘,¨'sub2' 'ns2'
      Crawl debug
      ⍝ check it worked
      assert'0∧.=≢¨( 1 NSTREE name)(1 NTREE folder)'
      ⍝ create items on both sides
      3 ⎕MKDIR¨folders←(folder,'/')∘,¨'sub1' 'sub3' 'sub1/subsub1' 'sub3/subsub3'
      folders←2↑folders
      (⊂⊂matsrc)⎕NPUT¨folders,¨⊂'/mat.apla'
      (⊂⊂tradfn)⎕NPUT¨folders,¨⊂'/tradfn.aplf'
      (⊂⊂dop)⎕NPUT¨folders,¨⊂'/dop.aplo'
      (⊂⊂NS'ns')⎕NPUT¨folders,¨⊂'/ns.apln'
      subs←⍎¨(name∘,¨'.sub2' '.sub4')⎕NS¨'' ''
      ((⍕¨subs),¨'.subsub2' '.subsub4')⎕NS¨'' ''
      subs.mat←⊂mat
      subs.⎕FX¨⊂¨tradfn dop
      subs.⎕FIX⊂NS'ns'
      Crawl debug
      assert'24∧.=≢¨( 1 NSTREE name)(1 NTREE folder)'
      ⍝ do modifications + creations + deletions on both sides
      (⊂matsrc2)⎕NPUT(folder,'/sub1/mat.apla')1
      (⊂tradfn2)⎕NPUT(folder,'/sub1/tradfn.aplf')1
      (⊂dop2)⎕NPUT(folder,'/sub1/dop.aplo')1
      (⊂NS2'ns')⎕NPUT(folder,'/sub1/ns.apln')1
      3 ⎕NDELETE folder,'/sub3'
      3 ⎕MKDIR folder,'/sub5/subsub5'
      (⊂matsrc2)⎕NPUT(folder,'/sub5/mat.apla')1
      (⊂tradfn2)⎕NPUT(folder,'/sub5/tradfn.aplf')1
      (⊂dop)⎕NPUT(folder,'/sub5/dop.aplo')1
      (⊂NS'ns')⎕NPUT(folder,'/sub5/ns.apln')1
      sub2←⍎name,'.sub2'
      sub2.mat←mat2
      sub2.⎕FX¨tradfn2 dop2
      sub2.⎕FIX NS2'ns'
      ⎕EX name,'.sub4'
      sub6←⍎(name,'.sub6')⎕NS'' ⋄ (name,'.sub6.subsub6')⎕NS''
      sub6.mat←mat
      sub6.⎕FX¨tradfn dop
      sub6.⎕FIX NS'ns'
      Crawl debug
      assert'24∧.=≢¨( 1 NSTREE name)(1 NTREE folder)'
      ⍝ clean up
      ⎕SE.Link.Expunge name
      3 ⎕NDELETE folder
    ∇


    ∇ res←bench_newcrawler(name folder);ALPHABET;FileName;Function;Name;Time;cmpx;cols;crawler;dotnet;files;fns;link;names;new;news;old;olds;opts;rows
      ALPHABET←'⍺⍵⍬⊢⊣⌷¨⍨/⌿\⍀<≤=≥>≠∨∧-+÷×?∊⍴~↑↓⍳○*⌈⌊∘⊂⊃∩∪⊥⊤|,⍱⍲⍒⍋⍉⌽⊖⍟⌹!⍕⍎⍪≡≢#&@:⋄←→⍝⎕⍞⍣'
      ALPHABET,←⎕A,10⍴' '
      Function←{(⊂'res←',⍵,' arg'),↓ALPHABET[?10 50⍴≢ALPHABET]}
      FileName←{folder,'/',⍵,'.aplf'}
      Name←{⎕A[?⍵⍴26]}
      Time←{
          start←3⊃⎕AI ⋄ _←⎕SE.Link.Watcher.Crawl link ⋄ end←3⊃⎕AI
          res[⍵;olds⍳old;news⍳new]+←end-start
      }
     
      opts←⎕NS ⍬ ⋄ opts.watch←'both'  ⍝ force tying to files so that DetermineFileName is fast
      (crawler dotnet)←⎕SE.Link.Watcher.(CRAWLER DOTNET)
      ⍝⎕SE.Link.Watcher.(CRAWLER DOTNET)←0  ⍝ disable file watching implementations
     
      olds←1 0 1 1/0 10 1000 100000
      news←1 0 0 1/1 10 100 1000
      res←(6,≢¨olds news)⍴0
      :For old :In olds   ⍝ items already linked before operations
          ⎕EX name
          3 ⎕NDELETE folder
          3 ⎕MKDIR folder
          fns←Function¨names←Name¨old⍴10 ⋄ files←FileName¨names
          fns{(⊂⍺)⎕NPUT ⍵ 1}¨files
          {}opts ⎕SE.Link.Create name folder
          {}⎕SE.Link.Pause name  ⍝ temporary disable watching to step our crawler
          assert'1=≢⎕SE.Link.Links'
          link←⊃⎕SE.Link.Links
          :For new :In news
              ⍝ 1 = create files
              fns←Function¨names←Name¨new⍴10
              files←FileName¨names
              fns{(⊂⍺)⎕NPUT ⍵ 1}¨files
              Time 1
              ⍝ 2 = modify files
              fns←Function¨names
              fns{(⊂⍺)⎕NPUT ⍵ 1}¨files
              Time 2
              ⍝ 3 = delete files
              3 ⎕NDELETE¨files
              Time 3
              ⍝ 4 = create apl items
              fns←Function¨names←Name¨new⍴10
              2(⍎name).⎕FIX¨fns
              Time 4
              ⍝ 5 = modify apl items
              fns←Function¨names
              2(⍎name).⎕FIX¨fns
              Time 5
              ⍝ 6 = delete apl items
              (⍎name).⎕EX names
              Time 6
          :EndFor
          {}⎕SE.Link.Expunge name
          3 ⎕NDELETE folder
      :EndFor
      :If 0
          cols←(≢news)/'create_files' 'mod_files' 'del_files' 'create_apl' 'mod_apl' 'del_apl'
          cols←cols,[0.5],{(6×⍴⍵)⍴⍵}⍕¨news
          rows←('linked_items' ''),⍕¨olds
          res←rows,cols⍪{(⍕⍵),'ms'}¨,[2 3]2 1 3⍉res
      :Else
          rows←'create_files' 'mod_files' 'del_files' 'create_apl' 'mod_apl' 'del_apl'
          rows←,rows∘.{'_'⎕R(' ',(⍕⍵),' ')⊢⍺}news
          cols←(⊂'pre-linked items'),⍕¨olds
          res←cols⍪rows,{⍵⊣(⍕⍵),'ms'}¨,[1 2]1 3 2⍉res
      :EndIf
      ⎕SE.Link.Watcher.(CRAWLER DOTNET)←(crawler dotnet)
    ∇


⍝         ⎕SE.Link.Test.bench_newcrawler '#.linktest' '/tmp/linktest'
⍝  pre-linked items      0  1000  100000
⍝  create 1 files       15   207   17266
⍝  create 1000 files  6578  7182  113374
⍝  mod 1 files           9   123   11067
⍝  mod 1000 files     7123  6807  105347
⍝  del 1 files           9   113   10254
⍝  del 1000 files     7605  6683   97521
⍝  create 1 apl          0   126   10267
⍝  create 1000 apl     122   209   10303
⍝  mod 1 apl             1   121   10274
⍝  mod 1000 apl        152   226   10062
⍝  del 1 apl            30   170   11264
⍝  del 1000 apl        108   190    9808

    :EndSection Benchmarks




:EndNamespace
