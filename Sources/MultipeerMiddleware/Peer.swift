import Foundation
import MultipeerConnectivity

public struct Peer: Codable, Equatable {
    public let peerInstance: MCPeerID

    public init(peerInstance: MCPeerID) {
        self.peerInstance = peerInstance
    }

    public init(displayName: String) {
        self.peerInstance = .init(displayName: displayName)
    }

    enum CodingKeys: String, CodingKey {
        case displayName
        case data
    }

    public func encode(to encoder: Encoder) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: peerInstance,
                                                    requiringSecureCoding: false)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(peerInstance.displayName, forKey: .displayName)
        try container.encode(data, forKey: .data)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .data)
        let displayName = try container.decode(String.self, forKey: .displayName)

        guard let peerID = try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data) else {
            throw DecodingError.dataCorruptedError(
                forKey: .data,
                in: container,
                debugDescription: "Can't unarchive data"
            )
        }

        guard displayName == peerID.displayName else {
            throw DecodingError.dataCorruptedError(
                forKey: .displayName,
                in: container,
                debugDescription: "Unarchived data has wrong display name"
            )
        }
        self.peerInstance = peerID
    }
}

public func == (lhs: Peer, rhs: Peer) -> Bool {
    lhs.peerInstance == rhs.peerInstance
}
