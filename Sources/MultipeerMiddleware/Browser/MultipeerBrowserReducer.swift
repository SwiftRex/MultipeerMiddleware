import Foundation
import SwiftRex

public let multipeerBrowserReducer = Reducer<MultipeerBrowserAction, MultipeerBrowserState>.reduce { action, state in
    switch action {
    case .startBrowsing,
         .stopBrowsing,
         .startedBrowsing,
         .stoppedBrowsing,
         .stoppedBrowsingDueToError,
         .foundPeer,
         .lostPeer,
         .manuallyInvite,
         .didSendInvitation,
         .remoteAcceptedInvitation,
         .remoteDeclinedInvitation:
        return
    }
}
