# swiftui-alert-state

View-local state for SwiftUI alerts that carry a value.

```swift
import SwiftUIAlertState
import SwiftUI

struct ProfileView: View {
  @AlertState private var failure: (any Error)?

  var body: some View {
    Button("Save") {
      Task {
        do { try await save() } catch { $failure.present(error) }
      }
    }
    .alert("Couldn't save", state: $failure) { _ in
      Button("OK") {}
    } message: { error in
      Text(error.localizedDescription)
    }
  }
}
```

## Motivation

SwiftUI's `alert(_:isPresented:presenting:)` needs two pieces of state that belong together:
a `Bool` that says *whether* to show the alert, and the value the alert *describes*, such as the
error or the item being deleted. Most code keeps them side by side:

```swift
@State private var showsError = false
@State private var error: MyError?

// ...
error = e
showsError = true
```

Nothing ties the two together, and that costs you in three places:

- **They drift apart.** Setting the flag without the value (or the reverse) presents an empty
  alert or none at all. Every call site must remember to write both, in the right order.
- **The value disappears while the alert is animating out.** SwiftUI clears the flag on dismissal.
  If you clear the value at the same moment, the message goes blank during the dismissal animation.
  `AlertState` keeps the last value after dismissal, so the alert fades out with its content intact.
- **Overlapping presentations are silent.** Presenting while an alert is already showing replaces
  the value under the visible alert. `present(_:)` asserts in debug builds, so the mistake surfaces
  while you develop.

`AlertState` holds the flag and the value as one property wrapper, so a single `present(_:)` call
sets both and the alert modifier reads both.

### The value is data, not content

`Value` is the context the alert needs, such as the error or the model it concerns. It isn't a
title-and-message struct that one generic alert renders. Declare each alert's title, message, and
actions in the view tree, next to the view that presents it. Then a reader can see which alerts a
view can show and what each says. A single dynamic alert whose content depends on a payload hides
that.

## Usage

Declare the state, present it, and attach an alert that reads it:

```swift
@AlertState private var item: Item?        // carries a value
@AlertState private var confirmation: Void? // carries nothing

$item.present(item)
$confirmation.present()
$item.dismiss()
```

| API | Meaning |
| --- | --- |
| `present(_:)` | Stores the value and requests presentation. Call it only when no alert is showing. |
| `present()` | The same, for `AlertState<Void>`. |
| `dismiss()` | Requests dismissal. The last value stays available. |
| `isPresented` | Whether presentation is currently requested. |
| `wrappedValue` | The last presented value. It is not nil-ed on dismissal, so it doesn't mean "an alert is showing". Use `isPresented` for that. |

The `alert(_:state:actions:message:)` overloads accept a `LocalizedStringKey`,
`LocalizedStringResource`, `StringProtocol`, or `Text` title. Without a value, pass
`AlertState<Void>` and omit the closure parameter. With a value, the `actions` and `message`
closures receive it.

## Requirements

iOS 18 / macOS 15, Swift 6.0.

## Installation

```swift
.package(url: "https://github.com/FluidGroup/swiftui-alert-state.git", from: "0.1.0")
```

Then add the `SwiftUIAlertState` product to your target.

## License

Apache License 2.0. See [LICENSE](LICENSE).
