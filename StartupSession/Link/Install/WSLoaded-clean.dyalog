 {ok}←WSLoaded msg;Env;boot
⍝ Handle )LOAD and )CLEAR
ok←1
 ⍝ These things need to be done once at Dyalog startup, not on subsequent WSLoaded events:
 :If msg≡1 ⍝ forced
     ⍝ To determine if the session just started, we use ⎕AI. Keyboarding time will be 0 the 1st time it is loaded
     ⍝ but this will be wrong in runtimes, so we use elapsed time, assuming that 15 seconds is enough to start APL.
     ⍝ In the worst case, if another ws is )LOADed within 15 sec of startup, initialisation will happen again.
     boot←⎕AI{⎕IO←1 ⋄ ⍵:0=4⊃⍺ ⋄ 15000≥3⊃⍺}'Development'≡4⊃# ⎕WG'APLVersion' ⍝ startup
 :OrIf boot
     Env←{2 ⎕NQ #'GetEnvironment'⍵}
     :Trap 0
         ⍎⊃2 ⎕FIX'file://',{×≢⍵:⍵ ⋄ '/startup.dyalog',⍨Env'DYALOG'}Env'DYALOGSTARTUP'
     :Else
         ⍞←⎕DMX.(OSError{⍵,(×≢⍺)/2⌽'") ("',3⊃⍺}Message{⍵,⍺,⍨': '/⍨×≢⍺}⊃DM)
         ok←0
     :EndTrap
 :EndIf

 ⍝ The rest also need to be done on every )CLEAR or )LOAD:
 RemoveLinks
