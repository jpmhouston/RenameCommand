# RenameCommand

A library making it easy to make a swift command-line program for renaming files according to your own rules.

It exports a struct `RenameOptions` conforming to the `ParsableArguments` protocol from Apple's `ArgumentParser`. It can be used with `@OptionGroup()` and your own `ParsableCommand` and also provides a `runRename()` function you can call within your own `run()`, doing most of the work needed.

 `runRename()` takes a function argument with a inout `name` parameter, you provide this function which changes `name` as desired. This is called for every file passed on the command line, with the file extension omitted if any, and the file gets renamed accordingly.

`RenameOptions`  defines arguments `verbose`, `quiet`, `dry-run`.

It works well with `swift-sh`, also the `Regex` package at http://github.com/sharplet/Regex which `RenameCommand` extends with an overload of its `replace` functions added to `String` allowing you to more conveniently specify case insensitive.

For example, this simple Swift "script" source file "myrename" (no ".swift" extension needed):

```swift
#!/usr/bin/swift sh
import ArgumentParser // apple/swift-argument-parser
import RenameCommand // @jpmhouston
import Regex // @sharplet

struct RenameMoviesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Renames my ripped movies from their old name format to how I prefer them now.")
    @OptionGroup() var options: RenameCommand.RenameOptions
    
    func run() throws {
        try options.runRename() { name in
            name.replaceAll(matching: #"\."#, with: " ")
            name.replaceFirst(matching: " 720p", .ignoreCase, with: "")
            name.replaceFirst(matching: " 1080p", .ignoreCase, with: "")
            name.replaceFirst(matching: " ([0-9][0-9][0-9][0-9])$", with: " ($1)")
        }
    }
}

RenameMoviesCommand.main()
```

after `chmod a+x myrename` and moving it to somewhere in the shell command path like `/usr/local/bin`, can then do:

```bash
$ myrename --help
OVERVIEW: Renames my ripped movies from their old name format to how I prefer them now.

USAGE: myrename [<files> ...] [--quiet] [--verbose] [--dry-run]

ARGUMENTS:
  <files>                 Files to rename. 

OPTIONS:
  -q, --quiet             Suppress non-error output. 
  -v, --verbose           Verbose output (overrides "--quiet"). 
  --dry-run               Show what would be renamed (no files are changed).
  -h, --help              Show help information.

$ myrename ~/Movies/Die.Hard.1988.720p.mp4
'Die.Hard.1988.720p.mp4' renamed to 'Die Hard (1988).mp4'
```

## See Also

- [ArgumentParser](https://github.com/apple/swift-argument-parser)
- [swift-sh](https://github.com/mxcl/swift-sh)
- [Regex](http://github.com/sharplet/Regex)
- [Files](https://github.com/JohnSundell/Files)

