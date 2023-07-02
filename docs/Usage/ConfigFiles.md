# Configuration Files

## Introduction
Link Configuration files are in [JSON5 format](https://json5.org/), which is the same format as Dyalog APL configuration files. There is a user configuration file containing options that apply to all links, and directory configuraton files which apply to individual directories.

### User Configuration Files
You can have a user configuration file which allows you to record preferences that apply to all links, for example link creation options like -watch= or the `notify` setting. A simple example of a user configuration file would be:

```
{
  Debug: {
    notify: 1,
  },
  Settings: {
    watch: "ns",
  },
}
```
With the above user configuration file contents, Link will display notifications when processing changes to the source (notify:1), and use default to only propagating changes from the namespace to source files (watch:ns), unless a call to [Link.Create](..API/Link.Create.md) includes an explicit setting of that option .

### Directory Configuration Files
Each linked directory may contain a `.linkconfig` file containing defaults that will apply when a link is created to that directory, or if the directory is imported. When [Link.Create](..API/Link.Create.md) or [Link.Export](..API/Link.Export.md) create a directory and create files in it, any non-default switch settings provided to tha API function will be recorded in a configuration file within the directory. This means that you no longer need to remember the options used to re-create the original link when continuing work, or importing the link into a runtime environment.

If you already have a Link folder which was created by an earlier version of Link, you can add a `.linkconfig` file using [Link.Configure](..API/Link.Configure.md). For example:

```
      ]Link.Create linkdemo /tmp/linkdemo
      ]Link.Configure linkdemo flatten:1
Was  flatten: 
```
The result documents that there was no previous setting for the option. A file called `/tmp/linkdemo/.linkconfig` is created, with the following contents:

```
{
  Settings: {
    flatten: 1,
  },
}
```
### Stop and Trace flags

Directory configuration files also record stop and trace settings for functions and operators in the linked directory, which you can either manipulate in the editor, or using the API functions [Link.Stop](../API/Link.Stop.md) and (Link.Trace)[../API/Link.Trace.md]:

```
      ]link.stop linkdemo.stats.Mean 2
Was linkdemo.stats.Mean 1
```
These settings are recorded in a `SourceFlags` section of our configuration file, which now looks like this:

```
{
  Settings: {
    flatten: 1,
  },
  SourceFlags: [
    {
      Name: "stats.Mean",
      Stop: [
        2,        
      ],
    },    
  ],
}
```

## Link.Configure
The [Link.Configure](../API/Link.Configure.md) API function, and the corresponding user command, can be used to query and set the contents of both user and directory configuration files. For example, following on from the above example, we can query the current settings:

```
      ]link.configure linkdemo
Contents of "c:/tmp/linkdemo/.linkconfig":
   Settings  :  flatten:1 

      ]link.configure *
Contents of "C:\Users\mkrom\Documents\.linkconfig":
   Debug     :  notify:1 
   Settings  :  watch:ns 
```


## The Configuration File Format

### Debug Section

### Settings Section

### SourceFlags Section

