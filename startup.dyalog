 {ok}←startup
⍝ This is a boot strapping function run when APL starts.
⍝ At this point, it only loads Link from text files into ⎕SE, but will be the basis for much more functionality in the future.
⍝ Please do not rely on the current behaviour of this function, as it may change without warning.
⍝ For more information about Link, see https://github.com/dyalog/link/wiki

 ;⎕IO;⎕ML ⍝ sysvars
 ;Env;Dir;Path;NoSlash;FixEach;AutoStatus;Cut ⍝ fns
 ;win;dirs;root;dir;subdir;ref;files;paths;path;roots;os;ver;envVars;defaults;as;oldlinks;new;z;fulldir ⍝ vars

 :Trap 0
     ⎕IO←⎕ML←1

     AutoStatus←2036⌶
     Env←{2 ⎕NQ #'GetEnvironment'⍵}
     NoSlash←{⍵↓⍨-'/\'∊⍨⊃⌽⍵} ⍝ remove trailing (back)slash
     Cut←{⎕ML←3 ⋄ ⍵⊂⍨⍺≠⍵}
     FixEach←{ ⍝ cover for ⎕FIX
         0=≢⍵:⍬⊤⍬
         ⍬⊤⍺{
             0::⍺{
                 Fail←{⎕←⎕DMX.('*** Fixing "',⍵,'" into ',(⍕⍺),' caused a ',(⊃DM),(''≢Message)/' (',Message,')')} ⍝ msg on fail
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

     (os ver)←2↑# ⎕WG'APLVersion'
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
                 :If 4≠1(⎕NINFO ⎕OPT'Follow' 0)fulldir ⍝ if folder is NOT a symbolic link
                     new←(5177⌶⍬)~oldlinks    ⍝ list new links
                     z←5178(2⊃¨new).⌶1⊃¨new ⍝ remove all newly created links
                 :EndIf
             :EndFor
         :EndFor
     :EndFor
     {}AutoStatus as
     ok←1
     :Trap 0 ⋄ {⎕SIGNAL ⍵}517 ⋄ :EndTrap ⍝ flush association tables
 :Else
     ok←0
 :EndTrap
