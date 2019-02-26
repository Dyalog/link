 {ok}←startup
 ;⎕IO;⎕ML ⍝ sysvars
 ;Env;Dir;Path;NoSlash;Fix;AutoStatus ⍝ fns
 ;win;dirs;root;dir;subdir;ref;files;paths;path;roots;os;ver;envVars;defaults;as ⍝ vars

 :Trap 0
     ⎕IO←⎕ML←1

     AutoStatus←2036⌶
     Env←{2 ⎕NQ #'GetEnvironment'⍵}
     NoSlash←{⍵↓⍨-'/\'∊⍨⊃⌽⍵} ⍝ remove trailing (back)slash
     Fix←{ ⍝ cover for ⎕FIX
         0::⍺{
             Fail←{⎕←⎕DMX.('*** Fixing "',⍵,'" into ',(⍕⍺),' caused a ',(⊃DM),(''≢Message)/' (',Message,')')} ⍝ msg on fail
             0::⍺ Fail ⍵
             ⎕DMX.(EN ENX)≡11 121:⍺.⎕FIX'file://',⍵ ⍝ re-try anonymous ns
             ⍺ Fail ⍵
         }⍵
         ×≢⍵:2 ⍺.⎕FIX'file://',⍵ ⍝ fix there
     }
     Path←{
         ×≢⍵:⍵(≠⊆⊣)':;'⊃⍨1+win ⍝ split on OS separator
         defaults,¨⊂⍺
     }
     Dir←{ ⍝ ⍺=1:dirs; ⍺=2:files
         pats←⍺⊃(,⊂'/*')('/*.dyalog' '/*.apl?')
         pats,¨⍨←⊂NoSlash ⍵
         ~∨/⎕NEXISTS⍠1⊢pats:0⍴⊂''
         (names types)←⊃,¨/0 1 ⎕NINFO⍠1⊢pats
         {(⊂⍋⍵)⌷⍵}names/⍨types=⍺
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
                 num←∊2↑'.'(≠⊆⊢)ver
                 uc←'UC'/⍨80 82=⎕DR'' ⍝ unicode/classic
                 bits←¯2↑'32',{⍵↓⍨⍵⍳'-'}os
                 home,'/dyalog.',num,'.files'
             }⍵
             user←⊃⎕NPARTS verSpec ⍝ /../
             verAgno←user,'dyalog.files' 'Dyalog APL Files'⊃⍨1+⍵
             ∊¨1 ⎕NPARTS dyalog verAgno verSpec ⍝ normalise
         }win
     :EndIf

     paths←'/StartupSession/' '/StartupWorkspace/'Path¨envVars
     roots←⎕SE #

     as←AutoStatus 0
     :For path root :InEach paths roots
         :For dir :In path
             files←2 Dir dir
             root Fix¨files
             dirs←1 Dir dir
             :For subdir :In 2⊃¨⎕NPARTS dirs
                 ref←⍎subdir root.⎕NS ⍬
                 files←2 Dir dir,subdir
                 ref Fix¨files
             :EndFor
         :EndFor
     :EndFor
     {}AutoStatus as
     ok←1
 :Else
     ok←0
 :EndTrap
