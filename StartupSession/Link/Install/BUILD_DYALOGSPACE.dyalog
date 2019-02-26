 BUILD_DYALOGSPACE
⍝ Pre-populate ⎕SE, and set WSLoaded callback up
 '⎕SE.Dyalog.Callbacks'⎕NS'RemoveLinks' 'WSLoaded'
 '⎕SE'⎕WS'Event' 'WorkspaceLoaded' '⎕SE.Dyalog.Callbacks.WSLoaded'
