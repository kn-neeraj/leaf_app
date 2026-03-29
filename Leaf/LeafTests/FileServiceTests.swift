import Foundation
import Testing

struct FileServiceTests {
    @Test func openReadsUTF8ContentAndTracksSecurityScope() throws {
        let url = URL(fileURLWithPath: "/tmp/leaf-open.md")
        let fileSystem = MockFileSystem(
            startedAccessing: true,
            readResponses: [url: Data("# Leaf".utf8)]
        )
        let service = FileService(fileSystem: fileSystem)

        let opened = try service.open(url)

        #expect(opened.content == "# Leaf")
        #expect(opened.didStartAccessingSecurityScopedResource == true)
        #expect(fileSystem.startedURLs == [url])
    }

    @Test func openThrowsOnInvalidUTF8AndReleasesSecurityScope() throws {
        let url = URL(fileURLWithPath: "/tmp/leaf-invalid.md")
        let fileSystem = MockFileSystem(
            startedAccessing: true,
            readResponses: [url: Data([0xFF, 0xFE])]
        )
        let service = FileService(fileSystem: fileSystem)

        #expect(throws: FileServiceError.invalidUTF8) {
            try service.open(url)
        }
        #expect(fileSystem.stoppedURLs == [url])
    }

    @Test func saveWritesUTF8Content() throws {
        let url = URL(fileURLWithPath: "/tmp/leaf-save.md")
        let fileSystem = MockFileSystem()
        let service = FileService(fileSystem: fileSystem)

        try service.save("# Saved", to: url)

        #expect(fileSystem.writes[url] == Data("# Saved".utf8))
    }
}

final class MockFileSystem: FileSystemHandling {
    var startedAccessing: Bool
    var readResponses: [URL: Data]
    var writes: [URL: Data] = [:]
    var startedURLs: [URL] = []
    var stoppedURLs: [URL] = []

    init(startedAccessing: Bool = false, readResponses: [URL: Data] = [:]) {
        self.startedAccessing = startedAccessing
        self.readResponses = readResponses
    }

    func startAccessingSecurityScopedResource(at url: URL) -> Bool {
        startedURLs.append(url)
        return startedAccessing
    }

    func stopAccessingSecurityScopedResource(at url: URL) {
        stoppedURLs.append(url)
    }

    func readData(from url: URL) throws -> Data {
        readResponses[url] ?? Data()
    }

    func writeData(_ data: Data, to url: URL) throws {
        writes[url] = data
    }
}
