:Namespace Utils
    ⍝ Utilities shared by Link infrastructure

    Normalise←∊1⎕NPARTS⊢

    ∇ r←IsWindows
      r←⎕SE.SALTUtils.WIN
    ∇
	
    Strip←{⍵↓⍨-'/'⍳⍨⌽⍵}
    Shortest←{⍵⊃⍨(⊢⍳⌊/)≢¨⍵}
    WinSlash←'\'@(=∘'/')⍣IsWindows
    Combine←{(⍕⍺),⍨(326≠⎕DR ⍺)/'.',⍨⍕⍵}/
    IsDir←{22::0 ⋄ 1=1 ⎕NINFO ⍵}

    lc←819⌶ ⍝ Lowercase
	
    GetCheckSum←{2 ⎕NQ #'GetBuildID' ⍵}

    ∇ r←GetName file;code;ns
    ⍝ Attempt to determine the name which will be defined by a file
     
      ns←(⎕NS'').⎕NS r←'' ⍝ Two levels of nesting to allow safe fixing of :Namespace/##.⎕IO←0/:EndNamespace
      :Trap 0
          2 ns.⎕FIX'file://',file
          :If 1=≢r←ns.⎕NL-⍳10 ⋄ r←⊃r
          :Else ⋄ r←''
          :EndIf
      :EndTrap
    ∇

    ∇ r←GetLinkInfo(ns name)
    ⍝ Return link info or ⍬
      r←5179(ns.⌶)name
    ∇

    ∇ r←GetFileInfo file
    ⍝ Return links to file
      r←5174⌶file
    ∇
	
    ∇ r←GetRefTo nsname;name
     ⍝ Get a reference to a container namespace (or ⍬ if that is not possible)
     
      :If ~(⊂nsname)∊'⎕SE'(,'#')
          r←⍬ ⍝ pessimism in action     
          →(¯1=⎕NC nsname)⍴0 ⍝ Not a valid name, not worth trying
     
          :If ~(nsname≡,'#')∨9=⎕NC nsname ⍝ if it isn't already there
              :Trap 0
                  :For name :In (¯1+⍸'.'=nsname,'.')↑¨nsname ⍝ growing paths		
                      :If 9.1≠⎕NC⊂name ⍝ Not a namespace
                          name ⎕NS''
                      :EndIf
                  :EndFor
              :Else
                  →0
              :EndTrap
          :EndIf
      :EndIf
      r←⍎nsname
    ∇
	
:EndNamespace
