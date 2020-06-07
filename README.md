# RenameCommand

A library making it easy to make a swift command-line program for renaming files according to your own rules.

It exports a struct `RenameOptions` conforming to the `ParsableArguments` protocol from Apple's `ArgumentParser`. It can be used with `@OptionGroup()` and your own `ParsableCommand` and also provides a `runRename()` function you can call within your own `run()`, doing most of the work needed.

 `runRename()` takes a function argument with a inout `name` parameter, you provide this function which changes `name` as desired. This is called for every file passed on the command line, with the file extension omitted if any, and the file gets renamed accordingly.

`RenameOptions`  defines arguments `verbose`, `silent`, `dry-run`.

It works well with `swift-sh`, also the `Regex` package at http://github.com/sharplet/Regex which it extends with a convenience function for case insensitive matching.

For example:

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
            name.replaceFirst(matchingIgnoringCase: " 720p", with: "")
            name.replaceFirst(matchingIgnoringCase: " 1080p", with: "")
            name.replaceFirst(matching: " ([0-9][0-9][0-9][0-9])$", with: " ($1)")
        }
    }
}

RenameMoviesCommand.main()
```
