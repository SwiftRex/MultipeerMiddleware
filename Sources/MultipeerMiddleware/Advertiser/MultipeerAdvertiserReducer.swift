import Foundation
import SwiftRex

public let multipeerAdvertiserReducer = Reducer<MultipeerAdvertiserAction, MultipeerAdvertiserState>.reduce { action, state in
    switch action {
    case .startedAdvertising:
        state = .advertising
    case .stoppedAdvertising:
        state = .stopped
    case let .stoppedAdvertisingDueToError(error):
        state = .error(MultipeerAdvertiserError(innerError: error))
    case .startAdvertising,
         .stopAdvertising,
         .invited,
         .acceptedInvitation,
         .declinedInvitation:
        return
    }
}
