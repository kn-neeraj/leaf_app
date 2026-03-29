//
//  FileService.swift
//  Leaf
//

import Foundation

public struct OpenedFile {
    public let content: String
    public let didStartAccessingSecurityScopedResource: Bool

    public init(content: String, didStartAccessingSecurityScopedResource: Bool) {
        self.content = content
        self.didStartAccessingSecurityScopedResource = didStartAccessingSecurityScopedResource
    }
}

public enum FileServiceError: Error, Equatable {
    case invalidUTF8
}

public protocol FileSystemHandling {
    func startAccessingSecurityScopedResource(at url: URL) -> Bool
    func stopAccessingSecurityScopedResource(at url: URL)
    func readData(from url: URL) throws -> Data
    func writeData(_ data: Data, to url: URL) throws
}

public struct LiveFileSystem: FileSystemHandling {
    public init() {}

    public func startAccessingSecurityScopedResource(at url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    public func stopAccessingSecurityScopedResource(at url: URL) {
        url.stopAccessingSecurityScopedResource()
    }

    public func readData(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func writeData(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }
}

public protocol FileServing {
    func open(_ url: URL) throws -> OpenedFile
    func save(_ content: String, to url: URL) throws
    func stopAccessing(_ url: URL)
}

public struct FileService: FileServing {
    private let fileSystem: any FileSystemHandling

    public init(fileSystem: any FileSystemHandling = LiveFileSystem()) {
        self.fileSystem = fileSystem
    }

    public func open(_ url: URL) throws -> OpenedFile {
        let didStartAccessing = fileSystem.startAccessingSecurityScopedResource(at: url)
        let data = try fileSystem.readData(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            if didStartAccessing {
                fileSystem.stopAccessingSecurityScopedResource(at: url)
            }
            throw FileServiceError.invalidUTF8
        }
        return OpenedFile(
            content: content,
            didStartAccessingSecurityScopedResource: didStartAccessing
        )
    }

    public func save(_ content: String, to url: URL) throws {
        let data = Data(content.utf8)
        try fileSystem.writeData(data, to: url)
    }

    public func stopAccessing(_ url: URL) {
        fileSystem.stopAccessingSecurityScopedResource(at: url)
    }
}
