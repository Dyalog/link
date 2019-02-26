 WSLoaded msg;tb;univ;f;dev;forced;dld;loc;tn;b;code;su
⍝ Handle WS )LOAD event
 :If forced←msg≡1
 :OrIf 'WorkspaceLoaded'≡2⊃msg

     :Trap 0 ⍝ ignore custom sessions without font selector
         :If 0≠⎕NC f←'⎕SE.cbtop.bandtb5.tb' ⍝ skip non GUI environments
             tb←⍎f ⍝ Initialize font picker
             univ←80∊⎕DR''
             tb.font.Items←{⍵[⍋↑⍵]}univ{(⍺∨1=3⊃¨⍵)/1⊃¨⍵}'.'⎕WG'FontList'
             tb.size.Items←{⍵[⍋⍵]}∪(2⊃'⎕se'⎕WG'FontObj'),tb.size.Items
             tb.font.Text←⊃'⎕SE'⎕WG'font'
             tb.size.(Value Thumb←{⍵,Items⍳⍵}2⊃'⎕se'⎕WG'Font')
         :EndIf
     :EndTrap
     :If ∧/×⎕SE.⎕NC'cbtop.bandtb5.tb.boxing' 'Dyalog.Out.B.state'
         ⎕SE.(cbtop.bandtb5.tb.boxing.State←'on'≡Dyalog.Out.B.state)
     :EndIf

    ⍝ To determine if the session just started we use ⎕AI
    ⍝ Keyboard time will be 0 the 1st time it is loaded but this will
    ⍝ be wrong in runtimes so we'll use the elapsed time there, assuming
    ⍝ that 15 seconds is enough to start APL.
    ⍝ In the worst case, if another ws is )LOADed within 15 sec of startup
    ⍝ SALT will be reloaded.

     dev←1∊'Dev'⍷4⊃'.'⎕WG'aplversion'
     :If forced∨⎕AI[3+dev]≤15000×~dev ⍝ dev: kb time=0, runtime: elapsed ≤ 15 sec

     Env←{2 ⎕NQ #'GetEnvironment'⍵}
     :Trap 0
         (⎕NS ⍬).(⍎⎕FX)⊃⎕NGET({×≢⍵:⍵ ⋄ '/startup.dyalog',⍨Env'DYALOG'}Env'DYALOGSTARTUP')1
     :Else
         ⍞←⎕DMX.(OSError{⍵,(×≢⍺)/2⌽'") ("',3⊃⍺}Message{⍵,⍺,⍨': '/⍨×≢⍺}⊃DM)
     :EndTrap

    ⍝ This code used to be divided into subfns but for sanity sake it is all together now.
    ⍝ 1st find the location of SALTUtils:
         dld←{(-'/\'∊⍨¯1↑⍵)↓⍵} ⍝ Drop Last Deliminiter fn

        ⍝ The SALT location may be supplied on the command line
         :If 0∊⍴loc←dld 2 ⎕NQ'.' 'GetEnvironment' 'SALT'
        ⍝ If it isn't it should be found here:
             f←dld 2 ⎕NQ'.' 'GetEnvironment' 'DYALOG'
             loc←(dld(¯3×'bin'≡¯3↑f)↓f),'/SALT'
         :EndIf
         loc,←'/core/SALTUtils.dyalog'

        ⍝ Things should not go wrong but if they do we don't want to leave a pending stack
         :Trap 0
        ⍝ Define the (SALTUtils) namespace locally
             su←0 ⎕FIX'file://',loc
         :Else
             →0⊣⎕←'SALT initialization failed: ',⎕DMX.Message
         :EndTrap

         su.BootSALT ⍝ finally, call the bootstrap fn
     :EndIf

     ⍝ Needs to be done on every )CLEAR or )LOAD:
     RemoveLinks

 :Else

     :If 'Spin'≡2⊃msg
         ⎕NQ(1⊃msg)'Change'
     :Else
         :If 'KeyPress'≢2⊃msg
         :OrIf 'ER'≡3⊃msg
             tb←(⍎⊃msg).##
             '⎕SE'⎕WS'Font'(f←(tb.font.Text)(⌊tb.size.Value)1 0 0 400)
             ⍝ Also update status bar font
             f[2]←¯8+1⊃'⎕SE.cbbot.bandsb2.sb'⎕WG'Size'
             '⎕se.cbbot.bandsb2.sb.curobj'⎕WS'Font'f
         :EndIf
     :EndIf
 :EndIf
