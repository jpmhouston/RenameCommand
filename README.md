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

## Note for swift-sh 1.17.1 and recent versions of Swift Package Manager
Until swift-sh issue #111 https://github.com/mxcl/swift-sh/issues/111 is fixed and if you're using SPM from Swift 5.2 (Xcode 11.4 or later) then any script using RenameCommand will fail to build with a "dependency requires explicit declaration" error and output like this:

    Updating https://github.com/jpmhouston/RenameCommand.git
    Updating https://github.com/JohnSundell/Files
    Updating https://github.com/sharplet/Regex.git
    Updating https://github.com/apple/swift-argument-parser.git
    Resolving https://github.com/jpmhouston/RenameCommand.git at 4c299aa2e4ff571893b18ac71aa39a195cb09bb1
    'renametest' /Users/me/Library/Developer/swift-sh.cache/98d753591fe20951a239e2e2b1a6cc12: error: dependency 'ArgumentParser' in target 'renametest' requires explicit declaration; reference the package in the target dependency with '.product(name: "ArgumentParser", package: "swift-argument-parser")'
    error: 1 <(/usr/bin/swift build -Xswiftc -suppress-warnings)

You'll need to copy the `swift-sh.cache` path out of that error and edit the file `Package.swift` in that directory, for example:

    vi /Users/me/Library/Developer/swift-sh.cache/98d753591fe20951a239e2e2b1a6cc12/Package.swift

In `Package.swift` the occurance of `"ArgumentParser"` must be replaced with `.product(name: "ArgumentParser", package: "swift-argument-parser")`.

Explicitly, replace:

    pkg.targets = [
        .target(name: "rename-tv", dependencies: ["ArgumentParser", "RenameCommand", "Regex"], path: ".", sources: ["main.swift"])
    ]

with (I've expanded the inner array onto multiple lines):

    pkg.targets = [
        .target(name: "rename-tv", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            "RenameCommand",
            "Regex"
        ], path: ".", sources: ["main.swift"])
    ]

Save this and build / run the script again and it should work. Unfortunately if any of those packages are updated in the future before swift-sh #111 is fixed you'll need to make this same edit again. You may want to explicitly fix the dependency versions in your `import` line comments to prevent this, see examples in the readme at https://github.com/mxcl/swift-sh.
