# Installation

In the below, **[DYALOG]** refers to the Dyalog APL install directory.

`Link` is installed with Dyalog APL versions 17.1 and newer. To use `Link` from a non-standard 17.1+ session (the .dse file installed with Dyalog APL) where the `WorkspaceLoaded` event is unusued, follow the instructions for [Session that does *not* use the `WorkspaceLoaded` event](#session-that-does-not-use-the-workspaceloaded-event). If the `WorkspaceLoaded` is used for something else, follow the instructions for [Session that *does* use the `WorkspaceLoaded` event](#session-that-does-use-the-workspaceloaded-event).

In Dyalog APL version 17.0, `Link` must be manually be added to the existing session. To use `Link` from a default 17.0 session (the .dse file installed with Dyalog APL), follow the instructions for [17.0 default session](https://github.com/abrudz/Link/blob/master/Install/README.md#170-default-session). To use `Link` from a non-standard 17.0 session where the `WorkspaceLoaded` event is unusued, follow the instructions for [Session that does *not* use the `WorkspaceLoaded` event](#session-that-does-not-use-the-workspaceloaded-event). If the `WorkspaceLoaded` is used for something else, follow the instructions for [Session that *does* use the `WorkspaceLoaded` event](#session-that-does-use-the-workspaceloaded-event).

`Link` is not compatible with Dyalog APL version 16.0 or older.

## Session that does *not* use the `WorkspaceLoaded` event

1. Copy the **Link** directory's files into **[DYALOG]/StartupSession/Link**
1. Copy **Link/Install/startup.dyalog** into **[DYALOG]**
1. `2⎕FIX'file://<path>/Link/Install/RemoveLinks.dyalog'`
1. `2⎕FIX'file://<path>/Link/Install/WSLoaded-clean.dyalog'`
1. `2⎕FIX'file://<path>/Link/Install/BUILD_DYALOGSPACE.dyalog'`
1. Run `BUILD_DYALOGSPACE`
1. Save the session

## 17.0 default session

1. Copy the **Link** directory's files into **[DYALOG]/StartupSession/Link**
1. Copy **Link/Install/startup.dyalog** into **[DYALOG]**
1. `2⎕FIX'file://<path>/Link/Install/RemoveLinks.dyalog'`
1. `2⎕FIX'file://<path>/Link/Install/WSLoaded-default.dyalog'`
1. `2⎕FIX'file://<path>/Link/Install/BUILD_DYALOGSPACE.dyalog'`
1. Run `BUILD_DYALOGSPACE`
1. Save the session

## Session that *does* use the `WorkspaceLoaded` event

1. Copy the **Link** directory's files into **[DYALOG]/StartupSession/Link**
1. Copy **Link/Install/startup.dyalog** into **[DYALOG]**
1. Edit the callback function for the `WorkspaceLoaded` event (as reported by `{⎕ML←1⋄⊃⌽l⊃⍨⍵⍳⍨⊃¨l←'⎕SE'⎕WG'Event'}⊂'WorkspaceLoaded'`) to insert the following code at the very top (it must begin at line `[1]`) of the function:<pre>
 ;boot;Env
 boot←⎕AI{⎕IO←1 ⋄ ⍵≡4⊃# ⎕WG'APLVersion':0=4⊃⍺ ⋄ 15000≥3⊃⍺}'Development'
 :If boot ⍝ These things need to be done once at Dyalog startup, not on subsequent WSLoaded events:
     Env←{2 ⎕NQ #'GetEnvironment'⍵}
     :Trap 0
         (⎕NS ⍬).(⍎⎕FX)⎕IO⊃⎕NGET({×≢⍵:⍵ ⋄ '/startup.dyalog',⍨Env'DYALOG'}Env'DYALOGSTARTUP')1
     :Else
         ⎕DMX.{⎕IO←1 ⋄ OSError{⍵,(×≢3⊃⍺)/2⌽'") ("',3⊃⍺}Message{⍵,⍺,⍨': '/⍨×≢⍺}1⊃DM}⍬
     :EndTrap
 :EndIf</pre>Also ensure that the function ends with:<pre>
 :If ×⎕NC'⎕SE.Link.WSLoaded'
     ⎕SE.Link.WSLoaded
 :EndIf</pre>Be especially careful to catch all occurrences of things like `→`, `→0`, `:GoTo 0`, `:Return` etc. and redirect them to reach the above code before the callback function terminates.
