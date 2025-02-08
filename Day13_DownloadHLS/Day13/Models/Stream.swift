import Foundation

struct Stream: Codable, Hashable {

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case playlistURL = "playlist_url"
    }
    
    let name: String
    let playlistURL: String

    init(name: String, playlistURL: String) {
        self.name = name
        self.playlistURL = playlistURL
    }
}

extension Stream: Equatable {
    static func ==(lhs: Stream, rhs: Stream) -> Bool {
        return (lhs.name == rhs.name) && (lhs.playlistURL == rhs.playlistURL)
    }
}
