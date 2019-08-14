 text←Serialise array;a;Quot;Brack;Encl;name;⎕IO;zero;trailshape;content;SubMat;Dia;Esc;DblQuot;MkEsc;DelQQ;q;drs;items ⍝ Convert Array to text
 ⎕IO←1
 q←''''
 DblQuot←{'('q,(q ⎕R'&&'⍕⍵),q')'}
 MkEsc←{
     stop←~⍵.Lengths[3]
     nums←⍕⎕UCS ⍵.Match↓⍨-~stop
     ''',',stop↓'(⎕UCS ',nums,stop↓'),''',⊃⌽⍵.Match
 }
 Esc←'([\x00-\x1F\x80-\xA0]+)(.?)'⎕R MkEsc⍠'Mode' 'D'
 DelQQ←'^(\()'''',' ',''''(\))$'⎕R'\1'
 Quot←DelQQ∘Esc∘DblQuot∘⍕⍤1
 Encl←{(l↑⍺⍺),(¯1⊖l↑w),')]'['(['⍳⍺⍺]↑⍨-l←2+≢w←⎕FMT ⍵}
 Brack←{(⎕FMT'['Encl⍤2)⍣⍺⍺⊢⍵}
 SubMat←{(¯2+≢⍴⍵)Brack ⍺⍺ ⍵}
 Dia←{1⌽')(',' *⋄ *$' ' *⋄ *(⋄ *)?' '([[(]) *⋄ *'⎕R'' ' ⋄ ' '\1'⍣≡∊↓'⋄',⍨⍵}⍣(2≥⊃⌽⍴array)
 :Trap 0
     :If 0=≡array ⍝ simple scalar
         :Select 10|⎕DR array
         :CaseList 0 2  ⍝ char
             :If (⎕UCS array)∊0,(⍳31),127+⍳33
                 text←1⌽')(⎕UCS ',⍕⎕UCS array
             :Else
                 text←q,array,q
             :EndIf
         :CaseList 6    ⍝ ref
             :If ⎕NULL≡array
                 text←'⎕NULL'
             :Else
                 text←'('
                 :For name :In array.⎕NL-⍳9
                     :Select |array.⎕NC⊂name
                     :CaseList 2.1 2.2 2.3 2.6 ⍝ var
                         text,←⊂⎕FMT(name,':')(Serialise array⍎name)
                     :CaseList 3.2 4.2 ⍝ dfn/dop
                         text,←⊂↑('^( ',name,')←')⎕R'\1:'@1 array.⎕NR name
                     :CaseList 9+0.1×⍳9
                         text,←⊂(name,':')(Serialise array⍎name)
                     :Else
                         'Unsupported array'⎕SIGNAL 11
                     :EndSelect
                 :EndFor
                 text←⎕FMT⍪text,')'
             :EndIf
         :Else ⍝ num
             text←⍕array
         :EndSelect
     :ElseIf ⍬≡⍴array ⍝ enclosure
         'Unsupported array'⎕SIGNAL 11/⍨1=≡array ⍝ ⎕OR
         text←⎕FMT'⊂'(Serialise⊃array)
     :ElseIf 0=≢array ⍝ no major cells
         :Select array
         :Case ⍬
             text←'⍬'
         :Case ''
             text←q q
         :Else
             text←(⍕⍴array),'⍴⊂',Dia Serialise⊃array
         :EndSelect
     :ElseIf 1=≢⍴array ⍝ non-empty vec
         :If 326=⎕DR array ⍝ heterovec
             text←'('Encl⍪Dia∘Serialise¨array
         :Else ⍝ simple vec
             :If 2|⎕DR array ⍝ numvec
                 text←⍕array
             :Else ⍝ charvec
                 text←Quot array
             :EndIf
             :If 1=≢array
                 text←'('text,'⋄)'
             :EndIf
         :EndIf
         text←⎕FMT⍣(1≡≢array)⊢text
     :ElseIf 0∊¯1↓⍴array ⍝ early 0 length
         zero←¯1+0⍳⍨⍴array
         trailshape←zero↓⍴array
         content←(⍕trailshape),'⍴⊂',Dia Serialise⊃array
         text←zero Brack(1,⍨zero↑⍴array)⍴⊂content
⍝ Special-case "tables"
     :ElseIf 2=≢⍴array ⍝ matrix
     :AndIf (⊂≢⊆)array ⍝ nested
     :AndIf 2≤≢array   ⍝ 2-row
     :AndIf ~326∊drs←⎕DR¨array  ⍝ simple, non-ref'y items
     :AndIf ∧/,1≥≢∘⍴¨array ⍝ scal/vec items
     :AndIf ~∨/(⎕UCS∊(,~2|drs)/,array)∊127 133 0,⍳31 ⍝ ctrl chars
         items←{
             ⍬≡⍵:'⍬'
             r←⍕⍵
             r{⍵:⍺ ⋄ 1⌽q q,''''⎕R'&&'⊢⍺}←⍬≡0⍴⍵  ⍝ quote?
             r,←'⋄'/⍨1∊⍴⍵                       ⍝ 1-element vec
             r{⍵:1⌽')(',⍺ ⋄ ⍺}←(1∊⍴⍵)∨(⍬≡⍴⍵)<⍬≡0⍴⍵ ⍝ parens?
             r
         }¨array
         text←⍕items
         text←'[]'@(1 1)(⍴text)⊢text
     :Else ⍝ high-rank
         :Select 10|⎕DR array
         :CaseList 0 2 ⍝ charmat
             text←Quot SubMat array
         :Case 6  ⍝ heteromat
             text←⍪Dia∘Serialise¨↓array
         :Else ⍝ nummat
             :If ⍬≡array
             :ElseIf (1↑⍨-≢⍴array)≡0=⍴array
                 text←('⍬'⍴⍨1,⍨¯1↓⍴)SubMat array
             :Else
                 text←Serialise⍤1 SubMat array
             :EndIf
         :EndSelect
         text←'['Encl text
     :EndIf
 :Else
     ⎕SIGNAL⊂⎕DMX.(('EN'EN)('Message'Message))
 :EndTrap
