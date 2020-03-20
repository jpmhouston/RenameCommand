//
//  RenameCommand.swift
//  RenameCommand
//
//  Created by Pierre Houston on 2020-03-19.
//  Copyright © 2020 Pierre Houston. All rights reserved.
//

import ArgumentParser
import Files
import Regex

public struct RenameOptions: ParsableArguments {
    @Argument(help: "Files to rename.")
    public var files: [String]
    
    @Flag(name: .shortAndLong, help: "Silent output.")
    public var silent: Bool
    
    @Flag(name: .shortAndLong, help: "Verbose output (overrides \"--silent\").")
    public var verbose: Bool
    
    @Flag(name: [.long, .customLong("dry-run")], help: "Don't perform rename just output the result.")
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
                else if !silent { print("'\(fileName)' renamed to '\(replacementName)'") }
                nrenamed += 1
            } else {
                if verbose { print("\(String(repeating: " ", count: "\(i)".count))  not renamed") }
                else if !silent && dryRun { print("'\(fileName)' not renamed") }
            }
        }
        return nrenamed
    }
}

// add conveniences to Regex/String+ReplaceMatching.swift
extension String {
   public mutating func replaceFirst(matchingIgnoringCase pattern: StaticString, with template: String) {
       replaceFirst(matching: Regex(pattern, options: [.ignoreCase]), with: template)
   }
   public mutating func replaceAll(matchingIgnoringCase pattern: StaticString, with template: String) {
       replaceAll(matching: Regex(pattern, options: [.ignoreCase]), with: template)
   }
   
   // for completeness, however not expected to be used by users of RenameCommand
   public func replacingFirst(matchingIgnoringCase pattern: StaticString, with template: String) -> String {
       return replacingFirst(matching: Regex(pattern, options: [.ignoreCase]), with: template)
   }
   public func replacingAll(matchingIgnoringCase pattern: StaticString, with template: String) -> String {
       return replacingAll(matching: Regex(pattern, options: [.ignoreCase]), with: template)
   }
}