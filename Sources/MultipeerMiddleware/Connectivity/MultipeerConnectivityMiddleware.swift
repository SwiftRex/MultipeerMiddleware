import Combine
import Foundation
import MultipeerCombine
import SwiftRex

public final class MultipeerConnectivityMiddleware: MiddlewareProtocol {
    public typealias InputActionType = MultipeerSessionConnectivityAction
    public typealias OutputActionType = MultipeerSessionConnectivityAction
    public typealias StateType = Void

    private let session: MultipeerSession
    private var connectivitySubscription: AnyCancellable?

    public init(session: @escaping () -> MultipeerSession) {
        self.session = session()
    }

    public func handle(action: MultipeerSessionConnectivityAction, from dispatcher: ActionSource, state: @escaping GetState<Void>) -> IO<MultipeerSessionConnectivityAction> {
        switch action {
        case .startMonitoring:
            return startMonitoring()
        default:
            return .pure()
        }
    }

    private func startMonitoring() -> IO<MultipeerSessionConnectivityAction> {
        IO { [weak self] output in
            guard let self = self else { return }
            self.connectivitySubscription = self.session.connections.sink(
                receiveCompletion: { _ in
                    output.dispatch(.stoppedMonitoring)
                },
                receiveValue: { event in
                    switch event {
                    case let .peerConnected(peer, _):
                        output.dispatch(.peerConnected(Peer(peerInstance: peer)))
                    case let .peerDisconnected(peer, _):
                        output.dispatch(.peerDisconnected(Peer(peerInstance: peer)))
                    case let .peerIsConnecting(peer, _):
                        output.dispatch(.peerIsConnecting(Peer(peerInstance: peer)))
                    }
                }
            )
        }
    }
}
