import Combine
import Foundation
import MultipeerCombine
import MultipeerConnectivity
import SwiftRex

public final class MultipeerAdvertiserMiddleware: MiddlewareProtocol {
    public typealias InputActionType = MultipeerAdvertiserAction
    public typealias OutputActionType = MultipeerAdvertiserAction
    public typealias StateType = MultipeerAdvertiserState

    private let advertiser: () -> MultipeerAdvertiserPublisher
    private let session: MultipeerSession
    private let acceptanceCriteria: MultipeerAdvertiserAcceptance
    private var advertisement: AnyCancellable?

    public init(
        advertiser: @escaping () -> MultipeerAdvertiserPublisher,
        session: @escaping () -> MultipeerSession,
        acceptanceCriteria: MultipeerAdvertiserAcceptance = .always
    ) {
        self.advertiser = advertiser
        self.session = session()
        self.acceptanceCriteria = acceptanceCriteria
    }

    public func handle(action: MultipeerAdvertiserAction, from dispatcher: ActionSource, state: @escaping GetState<MultipeerAdvertiserState>) -> IO<MultipeerAdvertiserAction> {
        switch action {
        case .startAdvertising:
            return startAdvertising()
        case .stopAdvertising:
            return stopAdvertising()
        case .startedAdvertising,
             .stoppedAdvertising,
             .stoppedAdvertisingDueToError,
             .invited,
             .acceptedInvitation,
             .declinedInvitation:
            return .pure()
        }
    }

    private func startAdvertising() -> IO<MultipeerAdvertiserAction> {
        IO { [weak self] output in
            guard let self = self else { return }
            self.advertisement = self.advertiser().sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        output.dispatch(.stoppedAdvertising)
                    case let .failure(error):
                        output.dispatch(.stoppedAdvertisingDueToError(error))
                    }
                },
                receiveValue: { event in
                    switch event {
                    case let .didReceiveInvitationFromPeer(peer, context, handler):
                        output.dispatch(.invited(by: Peer(peerInstance: peer), context: context))
                        let accepted = self.acceptanceCriteria.shouldAccept(invitedBy: peer, context: context)
                        handler(accepted, self.session.session)
                        output.dispatch(
                            accepted
                            ? .acceptedInvitation(from: Peer(peerInstance: peer), context: context)
                            : .declinedInvitation(from: Peer(peerInstance: peer), context: context)
                        )
                    }
                }
            )
            output.dispatch(.startedAdvertising)
        }
    }

    private func stopAdvertising() -> IO<MultipeerAdvertiserAction> {
        IO { [weak self] _ in
            self?.advertisement = nil
        }
    }
}
