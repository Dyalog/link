:Namespace Link ⍝ V 3.01
⍝ 2020 11 02 Nic: Moved code to ⎕SE.Link.U
⍝ 2021 01 14 Nic: Do not error if UCMD functions not found
⍝ 2021 01 21 MKrom: Better message
⍝ 2022 11 02 Adam: Disable ucmds when there's no Link, link to update

    ∇ Error;msg
      msg←'Link User Commands are incompatible with the installed version of Link'
      :If 3=⎕NC'⎕SE.Link.Version'
          msg,←' (',⎕SE.Link.Version,' - required version is 2.1 or later - see https://dyalog.github.io/link for how to update)'
      :EndIf
      ⎕←msg
    ∇

    ∇ r←List
      :If 9=⎕NC'⎕SE.Link'
          :If 3=⎕NC'⎕SE.Link.U.UCMD_List'
              r←⎕SE.Link.U.UCMD_List
          :Else
              Error
              r←⍬
          :EndIf
      :Else
          r←⍬
      :EndIf
    ∇

    ∇ r←level Help cmd
      :If 9=⎕NC'⎕SE.Link'
          :If 3=⎕NC'⎕SE.Link.U.UCMD_List'
              r←level ⎕SE.Link.U.UCMD_Help cmd
          :Else
              Error
              r←0⍴⊂''
          :EndIf
      :Else
          ⎕←'⎕SE.Link not found'
          r←0⍴⊂''
      :EndIf
    ∇

    ∇ r←Run(cmd args)
      :If 9=⎕NC'⎕SE.Link'
          :If 3=⎕NC'⎕SE.Link.U.UCMD_List'
              r←⎕SE.Link.U.UCMD_Run(cmd args)
          :Else
              Error
              r←''
          :EndIf
      :Else
          ⎕←'⎕SE.Link not found'
          r←''
      :EndIf
    ∇

:EndNamespace
