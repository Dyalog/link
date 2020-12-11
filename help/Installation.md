# Installation

Link requires Dyalog APL versions v17.1 and newer. \
Link can also work with Dyalog APL v17.0 Unicode, provided [some additional installation steps](#v17.0-default-session) \
LInk v2.1+ has optimal behaviour with Dyalog v18.1 and newer (see [release notes](ReleaseNotes.md)).

## Standard installation ##

To download the latest Link, visit [https://github.com/dyalog/link/branches](https://github.com/dyalog/link/branches), click on the branch you wish to download from, then click on the green button labelled "**↓Code**" then select "**Download ZIP**" to download the Link repository as a ZIP file.

To update Link, copy the contents of the link repository into the Dyalog installation directory so **startup.dyalog** ends up in the same directory as **dyalog.exe**, confirming the overwriting of **$DYALOG/SALT/spice/Link.dyalog** and of **$DYALOG/StartupSession/\***. Then restart Dyalog APL.

If you have standard v17.1+ installation, you're done. Otherwise a couple more steps might be required.



## Non-standard installations

To use Link from a non-standard v17.1+ session (the .dse file installed with Dyalog APL) where the `WorkspaceLoaded` event is unused, follow the instructions for [Session that does *not* use the WorkspaceLoaded event](#session-that-does-not-use-the-workspaceloaded-event). If the `WorkspaceLoaded` is used for something else, follow the instructions for [Session that *does* use the WorkspaceLoaded event](#session-that-does-use-the-workspaceloaded-event).

In Dyalog APL v17.0, Link must be manually be added to the existing session. To use Link from a default v17.0 session (the .dse file installed with Dyalog APL), follow the instructions for [17.0 default session](#170-default-session). To use Link from a non-standard 17.0 session where the `WorkspaceLoaded` event is unusued, follow the instructions for [Session that does *not* use the WorkspaceLoaded event](#session-that-does-not-use-the-workspaceloaded-event). If the `WorkspaceLoaded` is used for something else, follow the instructions for [Session that *does* use the WorkspaceLoaded event](#session-that-does-use-the-workspaceloaded-event).


## Session that does *not* use the `WorkspaceLoaded` event

1. Copy the **link** repository contents into the Dyalog installation directory so **startup.dyalog** ends up in the same directory as **dyalog.exe**
1. `2⎕FIX'file://',(2⎕NQ#'GetEnvironment' 'DYALOG'),'/StartupSession/Link/Install/RemoveLinks.dyalog'`
1. `2⎕FIX'file://',(2⎕NQ#'GetEnvironment' 'DYALOG'),'/StartupSession/Link/Install/WSLoaded-clean.dyalog'`
1. `2⎕FIX'file://',(2⎕NQ#'GetEnvironment' 'DYALOG'),'/StartupSession/Link/Install/BUILD_DYALOGSPACE.dyalog'`
1. Run `BUILD_DYALOGSPACE`
1. Save the session

Since SALT is not available, the `LINK` user command group is also unavailable, and the only interface to Link will be through `⎕SE.Link`.



## Session that *does* use the `WorkspaceLoaded` event

1. Copy the **link** repository contents into the Dyalog installation directory so **startup.dyalog** ends up in the same directory as **dyalog.exe**
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

Availability of the `LINK` user command group will depend on SALT being available.



## v17.0 default session

1. Copy the **link** repository contents into the Dyalog installation directory so **startup.dyalog** ends up in the same directory as **dyalog.exe**
1. `2⎕FIX'file://',(2⎕NQ#'GetEnvironment' 'DYALOG'),'/StartupSession/Link/Install/RemoveLinks.dyalog'`
1. `2⎕FIX'file://',(2⎕NQ#'GetEnvironment' 'DYALOG'),'/StartupSession/Link/Install/WSLoaded-default.dyalog'`
1. `2⎕FIX'file://',(2⎕NQ#'GetEnvironment' 'DYALOG'),'/StartupSession/Link/Install/BUILD_DYALOGSPACE.dyalog'`
1. Run `BUILD_DYALOGSPACE`
1. Run `⎕SE.Dyalog.Callbacks.WSLoaded 1`
1. Run `]UReset`
1. Save the session
