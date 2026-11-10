import SwiftUI

/// View-local state for presenting an alert with a value.
///
/// Call ``present(_:)`` to present a value. SwiftUI dismisses the alert by
/// clearing its presentation flag; the last value remains available afterward.
///
/// Use `Value` for contextual data, such as the item or error involved, rather
/// than for presentation content such as a title or message. Declare the
/// alert's title, message, and actions in its view modifier. Avoid bundling
/// those definitions into the value to drive a single generic alert whose
/// content changes dynamically. Declaring each alert in the view tree makes
/// its presence, content, and purpose explicit.
@propertyWrapper
public struct AlertState<Value>: DynamicProperty {

  @State fileprivate var presentationRequested = false
  @State fileprivate var value: Value?

  public var wrappedValue: Value? {
    value
  }

  /// Whether presentation is requested, independent of the retained value.
  public var isPresented: Bool {
    presentationRequested
  }

  /// Creates alert state with an optional initial value without presenting it.
  public init(wrappedValue: Value? = nil) {
    // `value` is optional, so Swift has already initialized it to nil. Assigning through
    // `self.value` would set an uninstalled `State` and drop the value; replace the storage.
    self._value = State(initialValue: wrappedValue)
  }

  public var projectedValue: AlertState {
    self
  }

  /// Presents the value. Call this only when an alert is not already presented.
  public func present(_ value: Value) {
    assert(!isPresented, "AlertState is already presented.")
    self.value = value
    self.presentationRequested = true
  }

  /// Dismisses the alert while retaining its last presented value.
  public func dismiss() {
    presentationRequested = false
  }
}

extension AlertState where Value == Void {

  /// Presents an alert that does not need a value.
  public func present() {
    present(())
  }
}

extension View {

  /// Presents an alert without presentation data.
  public func alert<Actions: View, Message: View>(
    _ title: LocalizedStringKey,
    state: AlertState<Void>,
    @ViewBuilder actions: () -> Actions,
    @ViewBuilder message: () -> Message
  ) -> some View {
    alert(title, isPresented: state.$presentationRequested, actions: actions, message: message)
  }

  /// Presents an alert without presentation data using a localized string resource.
  @_disfavoredOverload
  public func alert<Actions: View, Message: View>(
    _ title: LocalizedStringResource,
    state: AlertState<Void>,
    @ViewBuilder actions: () -> Actions,
    @ViewBuilder message: () -> Message
  ) -> some View {
    alert(title, isPresented: state.$presentationRequested, actions: actions, message: message)
  }

  /// Presents an alert without presentation data using a string title.
  @_disfavoredOverload
  public func alert<S: StringProtocol, Actions: View, Message: View>(
    _ title: S,
    state: AlertState<Void>,
    @ViewBuilder actions: () -> Actions,
    @ViewBuilder message: () -> Message
  ) -> some View {
    alert(title, isPresented: state.$presentationRequested, actions: actions, message: message)
  }

  /// Presents an alert without presentation data using a text title.
  public func alert<Actions: View, Message: View>(
    _ title: Text,
    state: AlertState<Void>,
    @ViewBuilder actions: () -> Actions,
    @ViewBuilder message: () -> Message
  ) -> some View {
    alert(title, isPresented: state.$presentationRequested, actions: actions, message: message)
  }

  /// Presents an alert using view-local alert state.
  public func alert<Value, Actions: View, Message: View>(
    _ title: LocalizedStringKey,
    state: AlertState<Value>,
    @ViewBuilder actions: (Value) -> Actions,
    @ViewBuilder message: (Value) -> Message
  ) -> some View {
    alert(title, isPresented: state.$presentationRequested, presenting: state.value, actions: actions, message: message)
  }

  /// Presents an alert using a localized string resource as its title.
  @_disfavoredOverload
  public func alert<Value, Actions: View, Message: View>(
    _ title: LocalizedStringResource,
    state: AlertState<Value>,
    @ViewBuilder actions: (Value) -> Actions,
    @ViewBuilder message: (Value) -> Message
  ) -> some View {
    alert(title, isPresented: state.$presentationRequested, presenting: state.value, actions: actions, message: message)
  }

  /// Presents an alert using a string as its title.
  @_disfavoredOverload
  public func alert<S: StringProtocol, Value, Actions: View, Message: View>(
    _ title: S,
    state: AlertState<Value>,
    @ViewBuilder actions: (Value) -> Actions,
    @ViewBuilder message: (Value) -> Message
  ) -> some View {
    alert(title, isPresented: state.$presentationRequested, presenting: state.value, actions: actions, message: message)
  }

  /// Presents an alert using a text view as its title.
  public func alert<Value, Actions: View, Message: View>(
    _ title: Text,
    state: AlertState<Value>,
    @ViewBuilder actions: (Value) -> Actions,
    @ViewBuilder message: (Value) -> Message
  ) -> some View {
    alert(title, isPresented: state.$presentationRequested, presenting: state.value, actions: actions, message: message)
  }
}

#if DEBUG

#Preview("AlertState without data") {
  @Previewable @AlertState var literal: Void?
  @Previewable @AlertState var resource: Void?
  @Previewable @AlertState var string: Void?
  @Previewable @AlertState var text: Void?

  let titleResource: LocalizedStringResource = "Localized resource"
  let titleString: String = "String title"

  return VStack {
    Button("String literal") { $literal.present() }
      .alert("Localized key", state: $literal) {
        Button("OK") {}
      } message: {
        Text("The title is a localized string key.")
      }

    Button("LocalizedStringResource") { $resource.present() }
      .alert(titleResource, state: $resource) {
        Button("OK") {}
      } message: {
        Text("The title is a localized string resource.")
      }

    Button("String") { $string.present() }
      .alert(titleString, state: $string) {
        Button("OK") {}
      } message: {
        Text("The title is a string.")
      }

    Button("Text") { $text.present() }
      .alert(Text("Text title"), state: $text) {
        Button("OK") {}
      } message: {
        Text("The title is a text view.")
      }
  }
}

#Preview("AlertState with data") {
  @Previewable @AlertState var literal: Int?
  @Previewable @AlertState var resource: Int?
  @Previewable @AlertState var string: Int?
  @Previewable @AlertState var text: Int?

  let titleResource: LocalizedStringResource = "Localized resource"
  let titleString: String = "String title"

  return VStack {
    Button("String literal") { $literal.present(1) }
      .alert("Localized key", state: $literal) { value in
        Button("Confirm \(value)") {}
      } message: { value in
        Text("Value: \(value)")
      }

    Button("LocalizedStringResource") { $resource.present(2) }
      .alert(titleResource, state: $resource) { value in
        Button("Confirm \(value)") {}
      } message: { value in
        Text("Value: \(value)")
      }

    Button("String") { $string.present(3) }
      .alert(titleString, state: $string) { value in
        Button("Confirm \(value)") {}
      } message: { value in
        Text("Value: \(value)")
      }

    Button("Text") { $text.present(4) }
      .alert(Text("Text title"), state: $text) { value in
        Button("Confirm \(value)") {}
      } message: { value in
        Text("Value: \(value)")
      }
  }
}

#endif
