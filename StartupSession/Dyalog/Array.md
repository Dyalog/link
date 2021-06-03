 # A model for a literal notation for most APL arrays

 ## How to use

 The API is located in the `⎕SE.Dyalog.Array` namespace.

 ### `Deserialise`

 This takes a character array and evaluates it as array notation, returning the resulting array.

 ```apl
 Deserialise '[1 2 ⋄ 3 4]'
 Deserialise '(a:{(+⌿⍵)÷≢⍵}' 'b:42)'
 Deserialise '(1 2 3',(⎕UCS 10),'4 5)'
 ```

 An optional left argument of `0` may be specified to return an APL expression which will generate the array rather than returning the array itself.

 ### `Serialise`

 This takes an array and returns a vector of character vectors representing the argument in array notation.

 ```apl
 Serialise 2 2⍴⍳4
 Serialise ⎕fix ':namespace' 'a←{(+⌿⍵)÷≢⍵}' 'b←42' ':endnamespace'
 Serialise '(1 2 3)(4 5)'
 ```

An optional left argument of `1` may be specified to force return of a vector by using `⋄` to fuse lines. Alternatively, a negative number may be given as left argument to specify how many spaces to indent the content of multi-line parenthesis/brackets (default is 2).

**Note:** `Serialise` will error if it cannot generate array notation that will round-trip.

 ### `∆NS`

 Extends `⎕NS` to allow a two-element right argument of names and values:

 ```apl
 myns←∆NS ('name1' 'name2')(7 42)
 'myns'∆NS ('name3' 'name4')('apl' 'dyalog')
 ```

 ### `∆NSinverse`

 Takes a ref or name of a namespace and returns a two-element vector of names and values.
 ```
 ∆NSinverse myns
 ∆NSinverse 'myns'
 ```

 ### `Inline`

 This allows using the notation inline, optionally over multiple lines, without having to quote everything. Instead, the notation is encapsulated in a dfn, which is used as operand for `Inline` which in turn returns the corresponding array. A right argument must be supplied, and may be `⍬` or `1` returns the array, while `0` returns an expression for the array.

 ## Domain and Limitations

 ### Valid Content

 The models handle arrays consisting of numbers, characters, namespaces, one-liner dfns/dops, and such arrays. Note that namespaces lose their scripts, names, and system variables when serialised, just like when converted to JSON using `⎕JSON`. Classes, Instances, Interfaces, and namespaces are not supported. Namespaces with circular references will cause `Serialise` to recurse until `WS FULL`.

 ### Functions and Operators

 `Serialise` does handle multi-line dfns/dops, but `Deserialise` is not able to parse them. Tradfns/tradops and derived functions/operators (including primitives and trains) are not supported.

 ### Code Layout

 `Serialise` generates indented notation using line breaks, but will fall back to using diamonds for the inner parts of certain nested arrays. It will often generate superfluous parentheses and diamonds.

 ### Scoping and Order of Evaluation

 The official proposal for the below notation includes specification of exact scope in phrases, including order of evaluation. The models do not attempt to address this other than encapsulating namespace members such that names created as side effects avoid polluting their surroundings. This also means that a namespace cannot contain a member with a name identical to itself.

 ### System Variables

 `Deserialise` does not accept invalid APL names as members of namespaces. This includes otherwise valid system names like `⎕IO` and `⎕ML`.

 ## Notation

 The notation extends strand notation as follows:

 ### Round Parentheses

 A diamond (`⋄`) inside a parenthesis causes the parenthesis to represent a vector where each diamond-delimited phrase represents an element.  
  `(1 2 ⋄ 3 4 5)` is equivalent to `(1 2)(3 4 5)`

 A colon (`:`) inside a parenthesis causes the parenthesis to represent a namespace where each diamond-delimited phrase represents a name:value pair.  
  `(ans:42)` is equivalent to `⎕JSON'{"ans":42}'` (except for the display form)

 An empty parenthesis (`()`) represents a new empty namespace.  
  `()` is equivalent to `⎕NS⍬`

 ### Square Brackets

 A diamond (`⋄`) inside a bracket causes the bracket to represent an array where each diamond-delimited phrase represents a major cell.  
  `[1 2 3 ⋄ 4 5 6]` is equivalent to `2 3⍴1 2 3,4 5 6`

 If a major cell is scalar, it will be interpreted as a 1-element vector.  
  `[1 ⋄ 2]` is equivalent to `⍪1 2`

 If major cells have differing shapes, they will be extended in the manner of Mix (`↑`).  
  `[1 2 ⋄ 3 4 5]` is equivalent to `2 3⍴1 2 0,3 4 5`

 ### Diamonds, Whitespace, Line Breaks

 At least one diamond is required to indicate array notation as opposed to traditional parenthesisation or bracketing.  
  `(1)` is equivalent to `1`  
  `'abcdef'[[1 2 3 ⋄ 4 5 6]]` is equivalent to `'abcdef'[2 3⍴1 2 3,4 5 6]`

 All-whitespace phrases are ignored.  
  `(1 2 ⋄ ⋄ 3 4 5)` is equivalent to `(1 2)(3 4 5)`  
  `(1 2 ⋄ )` is equivalent to `,⊂1 2`  
  `(1 ⋄ )` is equivalent to `,1`

 Any diamond may be exchanged with a line break.  
  `(1 2`   
  `3 4 5)`  is equivalent to `(1 2 ⋄ 3 4 5)`