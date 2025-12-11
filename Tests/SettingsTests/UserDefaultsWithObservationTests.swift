import Dispatch
import Foundation
import Observation
import Settings
import Testing
import Utilities
import os

@MainActor
final class Observer<Observable: Observation.Observable>: Sendable
where Observable: Sendable {
    let observable: Observable

    init(observable: Observable) {
        self.observable = observable
    }

    func observe<Subject>(
        _ keyPath: KeyPath<Observable, Subject>,
        action: @escaping @Sendable (Subject) -> Void
    ) {
        nonisolated(unsafe) let capturedKeyPath = keyPath
        withObservationTracking {
            action(observable[keyPath: capturedKeyPath])
            // print("counter.count: \(observable[keyPath: capturedKeyPath])")
        } onChange: {
            DispatchQueue.main.async {
                self.observe(capturedKeyPath, action: action)
            }
        }
    }
}

struct UserDefaultsWithObservationTests {

    @Settings(prefix: "UserDefaultsWithObservationTests_Settings_")
    struct AppSettings {
        @Setting var hasSeenOnboarding = false

        static func clear() {
            store.dictionaryRepresentation().keys
                .filter { $0.hasPrefix(self.prefix) }
                .forEach { store.removeObject(forKey: $0) }
        }
    }

    @MainActor
    @Observable
    final class ViewModel {
        var settings = AppSettings()
    }

    @MainActor
    @Test
    func testObservation() async throws {
        AppSettings.clear()

        let viewModel = ViewModel()
        let observer = Observer(observable: viewModel)

        #expect(viewModel.settings.hasSeenOnboarding == false)

        let expectationInitial = Utilities.Expectation()
        let expectationSet = Utilities.Expectation()

        observer.observe(\.settings.hasSeenOnboarding) { hasSeenOnboarding in
            print("Has seen Onboarding: ", hasSeenOnboarding)
            if hasSeenOnboarding == false {
                expectationInitial.fulfill()
            }
            if hasSeenOnboarding {
                expectationSet.fulfill()
            }
        }

        viewModel.settings.hasSeenOnboarding = true

        try await expectationInitial.await()
        try await expectationSet.await()
        #expect(viewModel.settings.hasSeenOnboarding == true)
        viewModel.settings.$hasSeenOnboarding.reset()

        AppSettings.clear()
    }

}
