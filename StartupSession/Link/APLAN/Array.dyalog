 Array←{
     aa←⍺⍺
     (1≡⊃⍵,1)Deserialise 1↓∊(⎕UCS 13),¨'^ aa←{( |\R)*|( |\R)*}\R*$'⎕R''⍠'Mode' 'D'⎕NR'aa'
 }
