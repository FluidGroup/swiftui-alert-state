import SwiftUI
import Testing

@testable import SwiftUIAlertState

/// Captures the projected `AlertState` from a live view, where its `@State` storage is installed.
@MainActor
private final class Capture<Value> {
  var state: AlertState<Value>?
}

private struct Probe<Value>: View {
  @AlertState var value: Value?
  let capture: Capture<Value>

  init(initial: Value?, capture: Capture<Value>) {
    self._value = AlertState(wrappedValue: initial)
    self.capture = capture
  }

  var body: some View {
    capture.state = $value
    return Color.clear
  }
}

@MainActor
@Suite struct AlertStateTests {

  private func hostedState<Value>(
    of _: Value.Type,
    initial: Value? = nil
  ) -> AlertState<Value> {
    let capture = Capture<Value>()
    let host = NSHostingView(rootView: Probe(initial: initial, capture: capture))
    host.layoutSubtreeIfNeeded()
    return capture.state!
  }

  @Test func startsDismissedWithoutValue() {
    let state = hostedState(of: Int.self)
    #expect(state.wrappedValue == nil)
    #expect(state.isPresented == false)
  }

  @Test func initialValueIsRetainedButNotPresented() {
    let state = hostedState(of: Int.self, initial: 7)
    #expect(state.wrappedValue == 7)
    #expect(state.isPresented == false)
  }

  @Test func presentRequestsPresentationAndStoresValue() {
    let state = hostedState(of: Int.self)
    state.present(3)
    #expect(state.wrappedValue == 3)
    #expect(state.isPresented)
  }

  @Test func dismissKeepsTheLastValue() {
    let state = hostedState(of: Int.self)
    state.present(3)
    state.dismiss()
    #expect(state.isPresented == false)
    #expect(state.wrappedValue == 3)
  }

  @Test func canPresentAgainAfterDismiss() {
    let state = hostedState(of: String.self)
    state.present("first")
    state.dismiss()
    state.present("second")
    #expect(state.wrappedValue == "second")
    #expect(state.isPresented)
  }

  @Test func voidStateCanPresentWithoutArguments() {
    let state = hostedState(of: Void.self)
    state.present()
    #expect(state.isPresented)
  }
}
