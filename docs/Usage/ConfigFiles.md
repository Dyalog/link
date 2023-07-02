# Configuration Files

## Introduction
Link Configuration files are in [JSON5 format](https://json5.org/), which is the same format as Dyalog APL configuration files. 

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
Each linked directory may contain a `.linkconfig` file containing defaults that will apply when a link is created to that directory, or if the directory is imported. When [Link.Create](..API/Link.Create.md) or [Link.Export](..API/Link.Export.md) create a directory and create files in it, any non-default switch settings will be recorded in a configuration file within the directory. This means that you no longer need to remember the options used to re-create the original link when continuing work, or importing the link into a runtime environment.

If you already have a Link folder which was created by an earlier version of Link, you can add a `.linkconfig` file using [Link.Configure](..API/Link.Configure.md). For example:

```
      ]link.Create linkdemo c:\tmp\linkdemo
      ]link.configure linkdemo flatten:1
Was  flatten: 
```

This will create a file called `/tmp/linkdemo/.linkconfig` with the following contents:

```
{
  Settings: {
    flatten: 1,
  },
}
```



## The Configuration File Format

### Debug Section

### Settings Section

### SourceFlags Section

