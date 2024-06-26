import Saber
import InboxFeatureInterface
import InboxFeatureImplementation
import InboxServiceInterface
import InboxServiceImplementation
import MemberwiseServiceInterface
import MemberwiseServiceImplementation
import SwiftUI
import UIKit

@Injectable
@Injector
public final class InboxScope {
    public var date: Date {
        Date()
    }

    private let memberwiseServiceStore = Store { MemberwiseServiceImplementation(first: "First", second: 1) }
    public var memberwiseService: any MemberwiseService {
        self.memberwiseServiceStore.value
    }

    @Store(InboxServiceImplementation.self)
    public var inboxService: any InboxService

    @Store(InboxViewModel.self)
    public var inboxViewModel: InboxViewModel

    @Factory(InboxView.self)
    public var rootFactory: Factory<Void, any View>
}

extension InboxScope: InboxScopeFulfilledDependencies {}
