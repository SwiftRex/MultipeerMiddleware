import Combine
import Foundation
import MultipeerCombine
import MultipeerConnectivity
import SwiftRex

public final class MultipeerBrowserMiddleware: MiddlewareProtocol {
    public typealias InputActionType = MultipeerBrowserAction
    public typealias OutputActionType = MultipeerBrowserAction
    public typealias StateType = MultipeerBrowserState

    private let browser: () -> MultipeerBrowserPublisher
    private let session: MultipeerSession
    private var browserSubscription: AnyCancellable?
    private let autoInvite: MultipeerBrowserAutoInvite
    private let timeout: TimeInterval
    private var invitations = Set<AnyCancellable>()

    public init(
        browser: @escaping () -> MultipeerBrowserPublisher,
        session: @escaping () -> MultipeerSession,
        autoInvite: MultipeerBrowserAutoInvite = .always,
        timeout: TimeInterval = 10
    ) {
        self.browser = browser
        self.session = session()
        self.autoInvite = autoInvite
        self.timeout = timeout
    }

    public func handle(action: MultipeerBrowserAction, from dispatcher: ActionSource, state: @escaping GetState<MultipeerBrowserState>) -> IO<MultipeerBrowserAction> {
        switch action {
        case .startBrowsing:
            return startBrowsing()
        case .stopBrowsing:
            return stopBrowsing()
        case let .manuallyInvite(peer, browser):
            return invite(peer: peer.peerInstance, browser: browser)
        case .foundPeer,
             .lostPeer,
             .startedBrowsing,
             .stoppedBrowsing,
             .stoppedBrowsingDueToError,
             .didSendInvitation,
             .remoteAcceptedInvitation,
             .remoteDeclinedInvitation:
            return .pure()
        }
    }

    private func invite(peer: MCPeerID, browser: MCNearbyServiceBrowser) -> IO<MultipeerBrowserAction> {
        IO { [weak self] output in
            self?.inviteAndOutput(peer: peer, browser: browser, output: output)
        }
    }

    private func startBrowsing() -> IO<MultipeerBrowserAction> {
        IO { [weak self] output in
            guard let self = self else { return }

            self.browserSubscription = self.browser().sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        output.dispatch(.stoppedBrowsing)
                    case let .failure(error):
                        output.dispatch(.stoppedBrowsingDueToError(error))
                    }
                },
                receiveValue: { [weak self] event in
                    guard let self = self else { return }

                    switch event {
                    case let .foundPeer(peer, info, browser):
                        output.dispatch(.foundPeer(Peer(peerInstance: peer), info: info, browser: browser))
                        if self.autoInvite.shouldInviteAutomatically(peerID: peer, info: info) {
                            self.inviteAndOutput(peer: peer, browser: browser, output: output)
                        }
                    case let .lostPeer(peer):
                        output.dispatch(.lostPeer(Peer(peerInstance: peer)))
                    }
                }
            )
            output.dispatch(.startedBrowsing)
        }
    }

    private func inviteAndOutput(peer: MCPeerID, browser: MCNearbyServiceBrowser, output: AnyActionHandler<MultipeerBrowserAction>) {
        session.invite(peer: peer, browser: browser, context: nil, timeout: self.timeout).sink(
            receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    output.dispatch(.remoteDeclinedInvitation(Peer(peerInstance: peer), error: error))
                case .finished:
                    break
                }
            },
            receiveValue: { peer in
                output.dispatch(.remoteAcceptedInvitation(Peer(peerInstance: peer)))
            }
        ).store(in: &invitations)

        output.dispatch(.didSendInvitation(Peer(peerInstance: peer)))
    }

    private func stopBrowsing() -> IO<MultipeerBrowserAction> {
        IO { [weak self] _ in
            self?.browserSubscription = nil
        }
    }
}
