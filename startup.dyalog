 {ok}←startup
⍝ This is a boot strapping function run when APL starts.
⍝ It loads Link and possibly other user-specified things for directories of text files into namespaces in ⎕SE.
⍝ Then it optionally uses Link to load a directory structure of text files into #.
⍝ Please do not rely on any other current behaviour of this function, as it may change without warning.
⍝ For more information about...
⍝ ∘ Session Initialisation: https://help.dyalog.com/latest/#UserGuide/The%20APL%20Environment/Session%20Initialisation.htm
⍝ ∘ Linking into #: https://help.dyalog.com/latest/#UserGuide/Installation%20and%20Configuration/Configuration%20Parameters/LINK_DIR.htm
⍝ ∘ Link: https://github.com/dyalog/link

 ;⎕IO;⎕ML ⍝ sysvars
 ;Env;Dir;Path;NoSlash;FixEach;AutoStatus;Cut;FullMsg ⍝ fns
 ;win;dirs;dir;root;subdir;ref;files;paths;path;roots;os;ver;envVars;defaults;as;oldlinks;new;z;fulldir;dskl;type;exe;parent;load;msg ⍝ vars

 :Trap 0
     ⎕IO←⎕ML←1

     AutoStatus←2036⌶
     Env←{2 ⎕NQ #'GetEnvironment'⍵}
     NoSlash←{⍵↓⍨-'/\'∊⍨⊃⌽⍵} ⍝ remove trailing (back)slash
     Cut←{⎕ML←3 ⋄ ⍵⊂⍨⍺≠⍵}
     FullMsg←{⍵.(OSError{⍵,2⌽(×≢⊃⍬⍴2⌽⍺,⊂'')/'") ("',⊃⍬⍴2⌽⊆⍺}Message{⍵,⍺,⍨': '/⍨×≢⍺}⊃⍬⍴DM,⊂'')}
     FixEach←{ ⍝ cover for ⎕FIX
         0=≢⍵:⍬⊤⍬
         ⍬⊤⍺{
             0::⍺{
                 Fail←{⎕←'*** Fixing "',⍵,'" into ',(⍕⍺),' caused a ',FullMsg ⎕DMX} ⍝ msg on fail
                 0::⍺ Fail ⍵
                 ⎕DMX.(EN ENX)≡11 121:⍺.⎕FIX'file://',⍵ ⍝ re-try anonymous ns
                 ⍺ Fail ⍵
             }⍵
             ×≢⍵:2 ⍺.⎕FIX'file://',⍵ ⍝ fix there
         }¨⍵
     }
     Path←{
         ×≢⍵:⍵ Cut⍨':;'⊃⍨1+win ⍝ split on OS separator
         defaults,¨⊂⍺
     }
     Dir←{ ⍝ ⍺=1:dirs; ⍺=2:files
         pats←⍺⊃(,⊂'/*')('/*.dyalog' '/*.apl?')
         pats,¨⍨←⊂NoSlash ⍵
         ~∨/⎕NEXISTS ⎕OPT 1⊢pats:0⍴⊂''
         (names types)←⊃,¨/0 1 ⎕NINFO ⎕OPT 1⊢pats
         {(⊂⍋⍵)⌷⍵}names/⍨types=⍺
     }
     NJoin←{
         tail←⍺↑⍨-1⌊≢⍺
         ⍵,⍨⍺,'/'↓⍨∧/tail∊'/',win/'\:'
     }

     (os ver type exe)←# ⎕WG'APLVersion'
     win←'Windows'≡7↑os
     envVars←Env¨'DYALOGSTARTUPSE' 'DYALOGSTARTUPWS'

     :If 0∊≢¨envVars
         defaults←{
             dyalog←NoSlash Env'DYALOG'
             verSpec←{
                 ⍵:NoSlash 2⊃4070⌶⍬ ⍝ win only: version specific folder in user docs folder
                 home←NoSlash Env'HOME'
                 num←∊2↑'.'Cut ver
                 uc←'UC'/⍨80 82=⎕DR'' ⍝ unicode/classic
                 bits←¯2↑'32',{⍵↓⍨⍵⍳'-'}os
                 home,'/dyalog.',num,uc,bits,'.files'
             }⍵
             user←⊃⎕NPARTS verSpec ⍝ /../
             verAgno←user,'dyalog.files' 'Dyalog APL Files'⊃⍨1+⍵
             ∊¨1 ⎕NPARTS dyalog verAgno verSpec ⍝ normalise
         }win
     :EndIf

     paths←1⍴'/StartupSession/' '/StartupWorkspace/'Path¨envVars ⍝ "1⍴" disables ws
     roots←1⍴⎕SE #                                               ⍝ "1⍴" disables #

     as←AutoStatus 0
     :For path root :InEach paths roots
         :For dir :In path
             ⍝ files←2 Dir dir      ⍝ disabled non-dir items in root
             ⍝ {}root FixEach files ⍝ disabled non-dir items in root
             dirs←1 Dir dir
             :For subdir :In 2⊃¨⎕NPARTS dirs
                 ref←⍎subdir root.⎕NS ⍬
                 fulldir←dir NJoin subdir
                 files←2 Dir fulldir
                 oldlinks←5177⌶⍬
                 {}ref FixEach files
                 :Select dskl←Env'DYALOGSTARTUPKEEPLINK' ⍝ proper link or just import?
                 :Case ,'1'
                 :CaseList ''(,'0')
                     new←(5177⌶⍬)~oldlinks  ⍝ list new links
                     :For ref parent :In 2↑¨new
                         z←5178 parent.⌶ref ⍝ remove all newly created links
                     :EndFor
                 :Else
                     ⍞←'Configuration parameter DYALOGSTARTUPKEEPLINK is "',dskl,'" but must be "0" or "1". Press Enter.'
                     {}⍞ ⋄ ⎕OFF 1
                 :EndSelect
             :EndFor
         :EndFor
     :EndFor

     load←Env'LOAD'
     msg←' ─ LOAD ignored!'
     load↓⍨←-'/\'∊⍨⊃⌽load ⍝ trim trailing slash
     :If 0≠≢load ⍝ LOAD allows linking/importing one dir into # at startup
     :AndIf ⎕NEXISTS load
     :AndIf 1=1 ⎕NINFO load ⍝ handle if dir (file is handled by interpreter)
         :If 0≠⎕NC'⎕SE.Link'
             :Select exe
             :CaseList 'Development' 'DLL'
                 :Trap 0
                     ⍞←⎕SE.Link.Create # load
                 :Else
                     ⍞←'Could not link "',load,'" with #: ',FullMsg ⎕DMX
                 :EndTrap
             :CaseList 'Runtime' 'DLLRT'
                 :Trap 0
                     ⍞←⎕SE.Link.Import # load
                 :Else
                     ⍞←'Could not import "',load,'" to #: ',FullMsg ⎕DMX
                 :EndTrap
             :Else
                 ⍞←'Could not determine if interpreter (',exe,') is Development or Runtime version',msg
             :EndSelect
         :Else
             :Select exe
             :CaseList 'Development' 'DLL'
                 ⍞←'Could not link "',load,'" with # because ⎕SE.Link does not exist',msg
             :CaseList 'Runtime' 'DLLRT'
                 ⍞←'Could not import "',load,'" to # because ⎕SE.Link does not exist',msg
             :Else
                 ⍞←'Could not bring in "',load,'" to # because ⎕SE.Link does not exist',msg
             :EndSelect
         :EndIf
         ⍞←⎕UCS 13
     :EndIf

     {}AutoStatus as
     ok←1
     :Trap 0 ⋄ {⎕SIGNAL ⍵}517 ⋄ :EndTrap ⍝ flush association tables
 :Else
     ok←0
 :EndTrap
