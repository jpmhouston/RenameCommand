//
//  RenameCommand.swift
//  RenameCommand
//
//  Created by Pierre Houston on 2020-03-19.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//
//  MIT License
//  
//  Copyright (c) 2020 Pierre Houston
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import ArgumentParser
import Files
import Regex

public typealias RenameFunc = (_ name: inout String, _ extn: String) throws -> Void

public struct RenameOptions: ParsableArguments {
    @Argument(help: "Files to rename.", completion: .file())
    public var files: [String]
    
    @Flag(name: .shortAndLong, help: "Suppress non-error output.")
    public var quiet: Bool = false
    
    @Flag(name: .shortAndLong, help: "Verbose output (overrides \"--quiet\").")
    public var verbose: Bool = false
    
    @Flag(name: .customLong("dry-run"), help: "Show what would be renamed (overrides \"--quiet\", no files are changed).")
    public var dryRun: Bool = false
    
    @Flag(name: .customLong("try"), help: "Try hypothetical file names (overrides \"--quiet\", no files are changed).")
    public var `tryOut`: Bool = false
    
    public init() { } // swift complains if this not present
    
    @discardableResult
    public func runRename(_ renameFunc: RenameFunc) throws -> Int {
        var i = 0, nrenamed = 0
        for path in files {
            let (_, fileName) = separateFile(path)
            if fileName.isEmpty { // disregard empty argument strings
                continue 
            }
            i += 1
            
            let file: File?
            if tryOut {
                file = nil
            } else {
                file = try File(path: path)
                if file!.parent == nil {
                    throw Files.LocationError(path: path, reason: .cannotRenameRoot)
                }
            }

            reportBefore(index: i, path: path)

            let (fileBase, fileExtn) = separateExtension(fileName)
            var newBase = fileBase
            try renameFunc(&newBase, fileExtn)
            
            let replacementName = newBase.isEmpty ? fileName : "\(newBase).\(fileExtn)"
            if replacementName != fileName {
                if !dryRun && !tryOut {
                    try file!.rename(to: replacementName)
                }
                nrenamed += 1
            }
            
            reportAfter(index: i, original: fileName, replacement: replacementName)
        }
        return nrenamed
    }
    
    func reportBefore(index i: Int, path: String) {
        if verbose {
            print("\(i). '\(path)'")
        }
    }
    
    func reportAfter(index i: Int, original: String, replacement: String) {
        if replacement != original {
            if verbose {
                print("\(String(repeating: " ", count: "\(i)".count))  renamed to '\(replacement)'")
            } else if !quiet || tryOut || dryRun {
                print("'\(original)' renamed to '\(replacement)'")
            }
        } else {
            if verbose {
                print("\(String(repeating: " ", count: "\(i)".count))  not renamed")
            } else if !quiet || tryOut || dryRun {
                print("'\(original)' not renamed")
            }
        }
    }
    
    func separateFile(_ full: String) -> (path: String, file: String) {
        var path = ""
        var file = full
        let components = full.split(separator: "/", omittingEmptySubsequences: false)
        if components.count > 1 {
            path = components.dropLast().joined(separator: "/")
            file = String(components.last!)
        }
        return (path, file) // to re-concatenate, path.isEmpty ? "\(path)/\(file)" : file
    }
    
    func separateExtension(_ name: String) -> (base: String, extn: String) {
        var base = name
        var extn = ""
        let components = name.split(separator: ".", omittingEmptySubsequences: false)
        if components.count > 1, let e = components.last, e.count > 0 {
            base = components.dropLast().joined(separator: ".")
            extn = String(e)
        }
        return (base, extn) // to re-concatenate, extn.isEmpty ? "\(base).\(extn)" : base
    }
}

// add conveniences to Regex/String+ReplaceMatching.swift: pass in regex options like .ignoreCase easily
//
// note: due to Swift bug SR-5304 am unable to refer to type `Regex.Options` below as would be preferable.
// instead must use inappropriately generic `Options` which could easily collide with a definition from
// another import. filed bug against github.com/sharplet/Regex to add a public `RegexOptions` typealias.

extension String {
   public mutating func replaceFirst(matching pattern: StaticString, _ options: Options, with template: String) {
       replaceFirst(matching: Regex(pattern, options: options), with: template)
   }
   public mutating func replaceAll(matching pattern: StaticString, _ options: Options, with template: String) {
       replaceAll(matching: Regex(pattern, options: options), with: template)
   }
   
   // for completeness, however not expected to be used by users of RenameCommand
   public func replacingFirst(matching pattern: StaticString, _ options: Options, with template: String) -> String {
       return replacingFirst(matching: Regex(pattern, options: options), with: template)
   }
   public func replacingAll(matching pattern: StaticString, _ options: Options, with template: String) -> String {
       return replacingAll(matching: Regex(pattern, options: options), with: template)
   }
}
