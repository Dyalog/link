 Deserialise←{ ⍝ Convert text to array
     ⍺←1 ⍝ 1=execute expression; 0=return expression
     q←''''
     ⎕IO←0
     SEP←'⋄',⎕UCS 10 13

     Unquot←{(⍺⍺ ⍵)×~≠\q=⍵}
     SepMask←∊∘SEP Unquot
     ParenLev←+\(×¯3+7|¯3+'([{)]}'∘⍳)Unquot

     Paren←1⌽')(',⊢
     Split←{1↓¨⍺⍺⊂Over(1∘,)⍵}

     Over←{(⍵⍵ ⍺)⍺⍺(⍵⍵ ⍵)}
     EachIfAny←{0=≢⍵:⍵ ⋄ ⍺ ⍺⍺¨⍵}
     EachNonempty←{⍺ ⍺⍺ EachIfAny Over((×≢¨⍵~¨' ')/⊢)⍵}

     Parse←{
         0=≢⍵:''
         bot←0=⍺
         (2≤≢⍵)>∨/¯1↓bot:⍺ SubParse ⍵
         p←bot×SepMask ⍵
         ∨/p:∊{1=≢⍵:',⊂',⍵ ⋄ ⍵}⍺(Paren ∇)EachNonempty Over(p Split)⍵
         p←2(1,>/∨¯1↓0,</)bot
         ∨/1↓p:∊(p⊂⍺)∇¨p⊂⍵
         ⍵
     }

     ErrIfEmpty←{⍵⊣'Empty array'⎕SIGNAL 11/⍨0=≢⍵}

     SubParse←{
         ('})]'⍳⊃⌽⍵)≠('{(['⍳⊃⍵):'Bad bracketing'⎕SIGNAL 2
         (a w)←(1↓¯1∘↓)¨(⍺-1)⍵
         '['=⊃⍵:Paren'↑1/¨',Paren ErrIfEmpty a Parse w ⍝ high-rank
         ':'∊⍵/⍨(1=⍺)×~≠\q=⍵:a Namespace w ⍝ ns
         '('=⊃⍵:Paren{⍵,'⎕NS⍬'/⍨0=≢⍵}a Parse w ⍝ vector/empty ns
         ⍵ ⍝ dfn
     }

     ParseLine←{
         c←⍵⍳':'
         1≥≢(c↓⍵)~' ':'Missing value'⎕SIGNAL 6
         name←c↑⍵
         ¯1=⎕NC name:'Invalid name'⎕SIGNAL 2
         name(name,'←',⍺ Parse Over((c+1)↓⊢)⍵)
     }

     Namespace←{
         p←(0=⍺)×SepMask ⍵
         (names assns)←↓⍉↑⍺ ParseLine EachNonempty Over(p Split)⍵
         ∊'({'(assns,¨'⋄')'⎕NS'('(, '∘,¨q,¨names,¨⊂q')')'}⍬)'
     }

     w←↓⍣(2=≢⍴⍵)⊢⍵                  ⍝ mat?
     w←{¯1↓∊⍵,¨⎕UCS 13}⍣(2=|≡w)⊢w   ⍝ vtv?
     w←'''[^'']+''' '⍝.*'⎕R'&' ''⊢w ⍝ strip comments

     pl←ParenLev w
     ∨/0>pl:'Unmatched brackets'⎕SIGNAL 2
     ∨/(pl=0)×SepMask w:'Multi-line input'⎕SIGNAL 11
     ⍎⍣⍺⊢pl Parse w
 }
