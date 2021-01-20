:Namespace Link ⍝ V 2.13
⍝ 2020 11 02 Nic: Moved code to ⎕SE.Link.U
⍝ 2021 01 14 Nic: Do not error if UCMD functions not found
⍝ 2021 01 21 MKrom: Better message

    ∇ Error;msg
      msg←'Link User Commands are incompatible with the installed version of Link'
      :If 3=⎕NC'⎕SE.Link.Version'
          msg,←' (',⎕SE.Link.Version,' - required version is 2.1 or later)'
      :EndIf
      ⎕←msg
    ∇

    ∇ r←List
      :If 3=⎕NC'⎕SE.Link.U.UCMD_List'
          r←⎕SE.Link.U.UCMD_List
      :Else
          Error
          r←⍬
      :EndIf
    ∇

    ∇ r←level Help cmd
      :If 3=⎕NC'⎕SE.Link.U.UCMD_List'
          r←level ⎕SE.Link.U.UCMD_Help cmd
      :Else
          Error
          r←0⍴⊂''
      :EndIf
    ∇

    ∇ r←Run(cmd args)
      :If 3=⎕NC'⎕SE.Link.U.UCMD_List'
          r←⎕SE.Link.U.UCMD_Run(cmd args)
      :Else
          Error
          r←''
      :EndIf
    ∇

:EndNamespace
