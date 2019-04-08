 Is←{
     0::'MISMATCH'⎕SIGNAL 999
     a←Serialise ⍺⍺ Array 1
     a≡Serialise ⍵:
     a≡Serialise ⎕JSON ⍵:
     ∧/⍵(∨/⍷)¨⊂a:
     !#
 }
