import Combine
import Foundation
import MultipeerCombine
import MultipeerConnectivity
import SwiftRex

public final class MultipeerMessagingMiddleware: MiddlewareProtocol {
    public typealias InputActionType = MultipeerSessionMessagingAction
    public typealias OutputActionType = MultipeerSessionMessagingAction
    public typealias StateType = Void

    private let session: MultipeerSession
    private var messageSubscription: AnyCancellable?

    public init(session: @escaping () -> MultipeerSession) {
        self.session = session()
    }

    public func handle(action: MultipeerSessionMessagingAction, from dispatcher: ActionSource, state: @escaping GetState<Void>) -> IO<MultipeerSessionMessagingAction> {
        switch action {
        case .startMonitoring:
            return startMonitoring()
        case .stoppedMonitoring:
            return .pure()
        case let .sendData(data):
            return sendData(data)
        case let .sendDataToPeer(data, peer):
            return sendData(data, to: peer.peerInstance)
        case .gotData,
             .sendDataResult:
            return .pure()
        }
    }

    private func startMonitoring() -> IO<MultipeerSessionMessagingAction> {
        IO { [weak self] output in
            guard let self = self else { return}
            self.messageSubscription = self.session.messages.sink(
                receiveCompletion: { _ in
                    output.dispatch(.stoppedMonitoring)
                },
                receiveValue: { event in
                    switch event {
                    case let .data(data, peer, _):
                        output.dispatch(.gotData(data, from: Peer(peerInstance: peer)))
                    case .didFinishReceivingResource, .didStartReceivingResource, .stream:
                        break
                    }
                }
            )
        }
    }

    private func sendData(_ data: Data, to peer: MCPeerID? = nil) -> IO<MultipeerSessionMessagingAction> {
        IO { [weak self] output in
            guard let self = self else { return }
            output.dispatch(
                .sendDataResult(
                    data,
                    to: peer.map(Peer.init),
                    result: peer.map {
                        self.session.send(data, to: $0)
                    } ?? self.session.sendToAll(data)
                )
            )
        }
    }
}
