# RenameCommand

A library making it easy to make a swift command-line program for renaming files according to your own rules.

#### Details

This package exports a struct `RenameOptions` conforming to the `ParsableArguments` protocol from Apple's `ArgumentParser`. It's intended to be used with `@OptionGroup()` and your own `ParsableCommand` and provides a `runRename()` function you can call within your own `run()`, implementing all the boilerplate file system and string processing involved in a command that renames files. Your code is little more than your custom regular expressions or any such manipulation of the base filename.

 `runRename()` takes a function argument with a inout `name` `String` (and file extension `String`), you provide this function which changes `name` as desired. This is called for every file passed on the command line, with the directory omitted and file extension separated, and the file gets renamed accordingly. Leave `name` unchanged (or change to empty string) to do nothing to the file.

`RenameOptions`  defines arguments `--verbose`/`-v`, `--quiet`/`-q`, `--dry-run`, `--try` (not to mention the defaults provided by ArgumentParser, `--help`/`-h` and `--generate-completion-script`). The difference between  `--dry-run` and `--try` are that the former fails as usual if the file arguments aren't found, the latter will allow any file argument as if they were files that existed; both show the would-be results of the rename without carrying it out.

It works well with `swift-sh`, also the `sharplet/Regex` package which `RenameCommand` extends with an overload of its  `String` extension functions allowing you to more conveniently specify case insensitive. See below.

#### Example

With `swift-sh` installed, this simple Swift "script" source file "myrename" (no ".swift" extension needed) is all you need to give you a fully functional custom file renaming command:

```swift
#!/usr/bin/swift sh
import ArgumentParser // apple/swift-argument-parser
import RenameCommand // @jpmhouston
import Regex // @sharplet

struct RenameMoviesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Renames my ripped movies from their old name format to how I prefer them now.")
    @OptionGroup() var options: RenameCommand.RenameOptions
    
    func run() throws {
        try options.runRename() { name, _ in
            name.replaceAll(matching: #"\."#, with: " ")
            name.replaceFirst(matching: " 720p", .ignoreCase, with: "")
            name.replaceFirst(matching: " 1080p", .ignoreCase, with: "")
            name.replaceFirst(matching: " ([0-9][0-9][0-9][0-9])$", with: " ($1)")
        }
    }
}

RenameMoviesCommand.main()
```

The functions  `replaceFirst` and `replaceAll` are from `sharplet/Regex`. If your script uses this package too, you're also able to pass options such as `.ignoreCase`  to those shortcut functions as shown rather than having to construct a `Regex` yourself to provide those options.

Thanks to the magic of `swift-sh`, after a `chmod a+x myrename` and moving it to somewhere in the shell command path like `/usr/local/bin`, you can then do:

```bash
$ myrename --help
OVERVIEW: Renames my ripped movies from their old name format to how I prefer them now.

USAGE: myrename [<files> ...] [--quiet] [--verbose] [--dry-run] [--try]

ARGUMENTS:
  <files>                 Files to rename. 

OPTIONS:
  -q, --quiet             Suppress non-error output. 
  -v, --verbose           Verbose output (overrides "--quiet"). 
  --dry-run               Show what would be renamed (overrides "--quiet", no files are changed).
  --try                   Try hypothetical file names (overrides "--quiet", no files are changed).
  -h, --help              Show help information.

$ myrename ~/Movies/Die.Hard.1988.720p.mp4
'Die.Hard.1988.720p.mp4' renamed to 'Die Hard (1988).mp4'
```

#### Tip for fish shell users

If you use the [fish shell](https://fishshell.com/), add this [selection function](https://gist.github.com/jpmhouston/4e23e60767055f98fccfee956eef9eda) and you can rename the current Finder selection with simply this:

```bash
$ myrename (selection)
```

(exercise for the reader: make something similar that works in other shells)

## See Also

- [ArgumentParser](https://github.com/apple/swift-argument-parser)
- [swift-sh](https://github.com/mxcl/swift-sh)
- [Regex](http://github.com/sharplet/Regex)
- [Files](https://github.com/JohnSundell/Files)

