 r←SerialiseQA stop_on_error;⎕IO;Is;⎕TRAP
 ⎕IO←0
 ⎕TRAP←(~stop_on_error)/⊂999 'C' '→r←0'
 Is←{
     0::'MISMATCH'⎕SIGNAL 999
     a←Serialise ⍺⍺ Array 1
     a≡Serialise ⍵:
     a≡Serialise ⎕JSON ⍵:
     ∧/⍵(1∊⍷)¨⊂a:
     !#
 }

 :Section scalars
     {
         'a'
     }Is'a'
     {
         42
     }Is 42
 :EndSection
 :Section vectors
     {(42 ⋄ )}Is,42

     {(42
         )}Is,42

     {
         (1 2 3 'Hello' ⋄ 4 5 6 'World')
     }Is(1 2 3 'Hello')(4 5 6 'World')

     {
         (1 2 3 'Hello'
         4 5 6 'World')
     }Is(1 2 3 'Hello')(4 5 6 'World')

     {
         (0 1 ⋄ 2 3
         4 5 ⋄ 6 7)
     }Is↓4 2⍴⍳8

     {
         ('Three'
         'Blind'
         'Mice')
     }Is'Three' 'Blind' 'Mice'
 :EndSection
 :Section Matrices
     {
         [0 1 2
         3 4 5]
     }Is 2 3⍴⍳6

     {
         [ ⋄ 0 1 2 3]
     }Is⍉⍪⍳4

     {
         [
         0 1 2 3
         ]
     }Is⍉⍪⍳4

     {
         ['Three'
         'Blind'
         'Mice']
     }Is 3 5⍴'ThreeBlindMice '

     {
         [1 ⋄ ]
     }Is⍪1

     {
         1 2[1 ⋄ ]
     }Is 1 2(⍪1)
 :EndSection
 :Section Combo
     {
         ([0 0 1
         1 0 1
         0 1 1]

         [0 1 1
         1 1 0
         0 1 0]

         [0 1 1 1
         1 1 1 0]

         [0 1 1 0
         1 0 0 1
         0 1 1 0])

     }Is{
         _←⍉⍪0 0 1
         _⍪←1 0 1
         _⍪←0 1 1
         r←⊂_
         _←⍉⍪0 1 1
         _⍪←1 1 0
         _⍪←0 1 0
         r,←⊂_
         _←⍉⍪0 1 1 1
         _⍪←1 1 1 0
         r,←⊂_
         _←⍉⍪0 1 1 0
         _⍪←1 0 0 1
         _⍪←0 1 1 0
         r,←⊂_
         r
     }⍬

     {
         [0 'OK' ⋄ 1 'WS FULL' ⋄ 2 'SYNTAX ERROR' ⋄ 3 'INDEX ERROR' ⋄ 4 'RANK ERROR']
     }Is{
         e←⍉⍪0 'OK'
         e⍪←1 'WS FULL'
         e⍪←2 'SYNTAX ERROR'
         e⍪←3 'INDEX ERROR'
         e⍪←4 'RANK ERROR'
         e
     }⍬
     {
         ['a'(⊂1 2)'a'
         (⊂1 2)'a'(⊂1 2)]
     }Is 2 3⍴'a'(⊂1 2)
 :EndSection

 :Section High Rank
     {
         [[3
         1 5 9]
         [2 7 1
         2 8]]
     }Is 2 2 3⍴3 0 0 1 5 9 2 7 1 2 8 0
 :EndSection

 :Section Empty
     {
         ⍬
     }Is ⍬
     {
         (⍬ ⋄ )
     }Is,⊂⍬
     {
         0⍴⊂⍬
     }Is 0⍴⊂⍬
     {
         0⍴⊂⊂⍬
     }Is 0⍴⊂⊂⍬
     {
         0⍴⊂0⍴⊂⍬
     }Is 0⍴⊂0⍴⊂⍬
     {
         [⍬ ⋄ ]
     }Is⍉⍪⍬
     {
         ⍉[⍬ ⋄ ]
     }Is⍪⍬
     {
         0⍴⊂[⍬ ⋄ ]
     }Is 0⍴⊂⍉⍪⍬
     {
         0⍴⊂⍉[⍬ ⋄ ]
     }Is 0⍴⊂⍪⍬
 :EndSection

 :Section Namespace
     {
         ()
     }Is'{}'

     {
         (
         )
     }Is'{}'

     {
         ()()
     }Is'[{},{}]'

     {
         (a:⍳n←3 ⋄ b:n*2)
     }Is'{"a":[0,1,2],"b":9}'

     {
         (p:{⍺+⍵}
         m:{⍺-⍵})
     }Is'p:{⍺+⍵}' ' m:{⍺-⍵}'

     {
         (v:(1 2 ⋄ 3))
     }Is'{"v":[[1,2],3]}'

     {
         (v:(1 2
         3))
     }Is'{"v":[[1,2],3]}'

     {
         (v:(1 2 ⋄ 3)
         )
     }Is'{"v":[[1,2],3]}'

     {
         (
         ()
         )
     }Is'[{}]'

     {(n:())}Is'{"n":{}}'

 :EndSection
 r←1
