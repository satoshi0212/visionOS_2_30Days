import Foundation
import AVFoundation

final class Video: Identifiable, Equatable {
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.id == rhs.id
    }

    var id = UUID()
    var url: URL
    var name: String
    var duration: Int
    var startTime: CMTimeValue

    init(
        name: String,
        url: URL,
        duration: Int = 0,
        startTime: CMTimeValue = 0
    ) {
        self.url = url
        self.name = name
        self.duration = duration
        self.startTime = startTime
    }
}

extension Video {
    var formattedDuration: String {
        Duration.seconds(duration)
            .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }

    var playerItem: AVPlayerItem? {
        return Video.openStream(url)
    }

    static func openStream(_ url: URL) -> AVPlayerItem? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                copyAndRenameFileInDocuments(fileName: destinationURL.lastPathComponent)
            } else {
                defer { url.stopAccessingSecurityScopedResource() }
                _ = url.startAccessingSecurityScopedResource()
                try FileManager.default.copyItem(at: url, to: destinationURL)
            }
        } catch {
            return nil
        }

        return AVPlayerItem(url: destinationURL)
    }

    private static func copyAndRenameFileInDocuments(fileName: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let originalFileURL = documentsURL.appendingPathComponent(fileName)
        let copyFileURL = documentsURL.appendingPathComponent("\(fileName)_copy")

        do {
            guard fileManager.fileExists(atPath: originalFileURL.path) else {
                print("Original file does not exist. : \(originalFileURL.path)")
                return
            }

            if fileManager.fileExists(atPath: copyFileURL.path) {
                try fileManager.removeItem(at: copyFileURL)
            }

            try fileManager.copyItem(at: originalFileURL, to: copyFileURL)
            // print("File copy succeeded. : \(copyFileURL.path)")
        } catch {
            print("File copy failed. : \(error.localizedDescription)")
            return
        }

        do {
            try fileManager.removeItem(at: originalFileURL)
            // print("Original file deletion succeeded. : \(originalFileURL.path)")
        } catch {
            print("Original file deletion failed. : \(error.localizedDescription)")
            return
        }

        do {
            try fileManager.moveItem(at: copyFileURL, to: originalFileURL)
            // print("File name change succeeded. : \(originalFileURL.path)")
        } catch {
            print("File name change failed. : \(error.localizedDescription)")
        }
    }
}
