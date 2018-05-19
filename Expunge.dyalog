{r}←Expunge name;caller;src
⍝ Expunge a function/operator or script, also removing any source file
⍝   Can be used in place of ⎕EX

:If DEBUG=2
    ⎕TRAP←0 'S' ⋄ ∘∘∘
:EndIf

caller←⊃⎕RSI
src←Utils.GetLinkInfo caller name
r←caller.⎕EX name

:If (0≢4⊃src)∧0=≢4⊃Utils.GetLinkInfo caller name ⍝ There was source and now there is none
    ⎕NDELETE 4⊃src
:EndIf
