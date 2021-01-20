:Namespace Link ⍝ V 2.12
⍝ 2018 12 17 Adam: Rewrite to thin covers
⍝ 2018 02 01 Adam: Help text
⍝ 2018 02 14 Adam: List -e
⍝ 2019 03 14 Adam: help text
⍝ 2019 05 07 Adam: disable ]CaseCode
⍝ 2019 05 31 MKrom: Fix ⎕ML sensitivity
⍝ 2019 06 19 Adam: Avoid special-cased vars in caller
⍝ 2020 05 14 Nic: updated to link v2.1 API
⍝ 2020 06 08 Adam: Remove Version ucmd (use ⎕SE.Link.Version)
⍝ 2020 10 07 Adam: Fix Help parsing ranged arg count as -mod
⍝ 2020 10 27 Nic: Run: Fix :With making locals visible to ⎕SE.Link.*
⍝ 2020 11 02 Nic: Run: Cleaned calls to ⎕SE.Link.*
⍝ 2020 11 02 Nic: Moved code to ⎕SE.Link.U
⍝ 2021 01 14 Nic: Do not error if UCMD functions not found
⍝ 2021 01 21 MKrom: Tested the previous fix and made it actually work

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
          ⍝ /// Return one fake UCMD to prevent Spice from falling over
          r←,⎕JSON '{"Name":"NotInstalled", "args":"[ns1]",   "Parse":"1S", "Desc":"Link is not installed", "Group":"Link"}'
          Error
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
