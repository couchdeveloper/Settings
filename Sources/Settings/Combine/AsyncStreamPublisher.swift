import Combine

/// Publishes values from an AsyncSequence (such as AsyncStream).
///
/// Notes:
/// - This publisher is intended for infrequently-changing sources (for example,
///   UserDefaults). It intentionally keeps the implementation minimal (no
///   backpressure/demand accounting) because updates are rare.
/// - Deliveries to subscribers are performed on the `MainActor`. The subscription
///   iterates the underlying `AsyncSequence` and runs its Task isolated to the
///   `MainActor`, ensuring subscriber callbacks are invoked on the main thread
///   (convenient for UI consumers). If you prefer the loop off-main and only
///   hop to the main actor for delivery, consider modifying the Task to call
///   `await MainActor.run { ... }` for each delivery instead.
struct AsyncStreamPublisher<S>: Publisher
where S: AsyncSequence & Sendable, S.Element: Sendable {
    typealias Output = S.Element
    typealias Failure = Swift.Error

    private let sequence: S

    init(_ sequence: S) {
        self.sequence = sequence
    }

    func receive<Sink: Subscriber>(subscriber: Sink)
    where Sink.Input == Output, Sink.Failure == Failure {
        let erased = AnySubscriber<Output, Failure>(subscriber)
        let subscription = Subscription(sequence: sequence, downstream: erased)
        subscriber.receive(subscription: subscription)
    }
}

extension AsyncStreamPublisher {

    // Subscription assumptions / environment
    // - This publisher observes infrequently-changing sources (UserDefaults), so
    //   we intentionally keep the implementation minimal: no demand/backpressure
    //   accounting is performed and updates are delivered as they arrive.
    // - The subscription captures an erased `AnySubscriber<Output, Failure>` which
    //   the Task owns exclusively. We mark the small box as `@unchecked Sendable`
    //   and rely on the Task to perform all subscriber calls. This avoids Swift
    //   concurrency Sendable capture diagnostics while maintaining memory-safety.
    // - Cancellation is cooperative: `cancel()` cancels the Task and the Task
    //   checks `Task.checkCancellation()` after awaits to exit early. There is a
    //   narrow, acceptable window where an in-flight delivery may complete after
    //   `cancel()` returns; this is intentional for simplicity and matches common
    //   Combine semantics for fire-and-forget cancellation.
    // - If callers require immediate release of resources on cancel or strict
    //   guarantees of no post-cancel deliveries, consider switching to a
    //   class-box with an optional downstream cleared under a lock in `cancel()`.
    private final class Subscription: Combine.Subscription {

        // Box to hold the downstream. Mark the box @unchecked Sendable so it can be captured
        // from the Task's @Sendable closure.
        //
        // Design note / tradeoff:
        // - This implementation uses a small struct-box that holds an erased
        //   `AnySubscriber<Output, Failure>`. The Task captures the struct as its sole
        //   owner, meaning the Task holds the only strong reference to the subscriber and
        //   will release it when the Task finishes. We call `Task.checkCancellation()`
        //   after each await to bail out quickly on cancellation, so there are no memory
        //   races and the boxed subscriber is only accessed from the Task.
        //
        // - The struct-box approach keeps the implementation minimal. The tradeoff is
        //   that `cancel()` only cancels the Task; the subscriber may not be released
        //   until the Task actually exits (a very short duration). If you need the
        //   subscriber to be released immediately when `cancel()` is called, switch to
        //   a class-box with an optional `downstream` field guarded by a lock and clear
        //   that optional in `cancel()` before cancelling the Task. That class-box
        //   approach slightly increases complexity but allows earlier release of the
        //   subscriber and reduces the chance of a post-cancel delivery.
        //
        // The box holds an erased `AnySubscriber<Output, Failure>` so the Task's
        // @Sendable closure does not capture a generic subscriber metatype.
        private struct DownstreamBox: @unchecked Sendable {
            let downstream: AnySubscriber<Output, Failure>
            init(_ downstream: AnySubscriber<Output, Failure>) {
                self.downstream = downstream
            }
        }

        private var task: Task<Void, Swift.Error>?

        init(sequence: S, downstream: AnySubscriber<Output, Failure>) {
            let downstreamBox = DownstreamBox(downstream)

            // Start a Task that iterates the AsyncSequence.
            self.task = Task { @MainActor in
                do {
                    for try await value in sequence {
                        try Task.checkCancellation()
                        _ = downstreamBox.downstream.receive(value)  // ignore returned demand for now
                    }

                    // natural completion -> send finished
                    downstreamBox.downstream.receive(completion: .finished)
                } catch is CancellationError {
                    // we should reach here only, when the cancel function
                    // has been called – which cancels the task.
                    /* nothing */
                } catch {
                    // We reach here, when the stream has been forcibly terminated
                    // or the `do` above threw another error. So, `downstream`
                    // should be intact.
                    downstreamBox.downstream.receive(
                        completion: .failure(error)
                    )
                }
            }
        }

        func request(_ demand: Subscribers.Demand) {
            // TODO: implement demand accounting if you need backpressure support.
        }

        func cancel() {
            task?.cancel()
        }
    }
}
