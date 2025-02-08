import Foundation

class StreamListManager {
    
    static let shared: StreamListManager = StreamListManager()

    var streams: [Stream] = load("streams.json")
    private var streamMap = [String: Stream]()
    
    private init() {
        for stream in streams {
            streamMap[stream.name] = stream
        }
    }
    
    func stream(withName name: String) -> Stream {
        guard let stream = streamMap[name] else {
            fatalError("Could not find `Stream` with name: \(name)")
        }
        return stream
    }

    static func load<T: Decodable>(_ filename: String) -> T {
        let data: Data

        guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
            fatalError("Couldn't find \(filename).")
        }

        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Couldn't load \(filename).")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Couldn't parse \(filename).")
        }
    }
}
