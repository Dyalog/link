# TODO
 - clean up ⎕SE.Link into ⎕SE.Link.U to have as few non-public names as possible
 - Normalise results of Add, Break, Create, Export, Fix, Import, List, Notify, Refresh
 - FSW error recovery (no .NetCore support !)
 - turn Serialise into ,↓Serialise
 - use :Holds to synchronise access to ⎕SE.Link.Links
 - FileWatcher.Break should break all at once : (EnableRaisingEvents←0) (⎕DL) (Dispose)
 - 

# RFE
 - proper logging of errors and warnings, with accessible backlog - to check no errors during a working session.
 - remember ties between arrays and files (could be stored in ⎕SE.Link.Links.arrays)
 - add Ignore - requires ignore list in ⎕SE.Link.Links.ignored)
 - Add should support non-existing names (added to ⎕SE.Link.Links.added)
 - inotify on linux
 - add Pause/Resume ? to disable watcher ? and editor callbacks ?
 - add crawlers (file and namespace) - costy in code complexity and performance : Link would spend a fraction of the CPU time looking for changes that don't exist