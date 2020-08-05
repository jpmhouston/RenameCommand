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

public struct RenameOptions: ParsableArguments {
    @Argument(help: "Files to rename.")
    public var files: [String]
    
    @Flag(name: .shortAndLong, help: "Suppress non-error output.")
    public var quiet: Bool
    
    @Flag(name: .shortAndLong, help: "Verbose output (overrides \"--quiet\").")
    public var verbose: Bool
    
    @Flag(name: .customLong("dry-run"), help: "Show what would be renamed (no files are changed).")
    public var dryRun: Bool
    
    public init() { } // swift complains if this not present
    
    @discardableResult
    public func runRename(_ renameFunc: (_ name: inout String) -> Void) throws -> Int {
        var i = 0, nrenamed = 0
        for path in files {
            i += 1
            
            let file = try File(path: path)
            guard let parent = file.parent else {
                throw Files.LocationError(path: path, reason: .cannotRenameRoot)
            }
            let fileName = file.name
            
            if verbose { print("\(i). \(parent.path)\(fileName)") }
            
            var baseName = fileName
            var fileExtn: String? = nil
            let components = fileName.split(separator: ".")
            if let ext = components.last {
                fileExtn = String(ext)
                baseName = components.dropLast().joined(separator: ".")
            }
            
            renameFunc(&baseName)
            
            let replacementName = fileExtn != nil ? "\(baseName).\(fileExtn!)" : baseName
            
            if replacementName != fileName {
                if !dryRun {
                    try file.rename(to: replacementName)
                }
                
                if verbose { print("\(String(repeating: " ", count: "\(i)".count))  renamed to \(replacementName)") }
                else if !quiet { print("'\(fileName)' renamed to '\(replacementName)'") }
                nrenamed += 1
            } else {
                if verbose { print("\(String(repeating: " ", count: "\(i)".count))  not renamed") }
                else if !quiet && dryRun { print("'\(fileName)' not renamed") }
            }
        }
        return nrenamed
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
