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
sets both and the alert modifier reads both. It keeps SwiftUI's two-part model rather than replacing
it. See [Background](#background) for why that model exists.

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

## Background

SwiftUI could have driven alerts with a single optional, the way `sheet(item:)` works. Instead,
`alert(_:isPresented:presenting:)` takes a `Bool` and a separate value. `AlertState` keeps that
model and only bundles the two pieces. This section explains why the model looks the way it does.

### SwiftUI treats an alert as a snapshot

An alert shows the value it had when it appeared. The [documentation][presenting-docs] for
`alert(_:isPresented:presenting:actions:message:)` says:

> The data should not change after the presentation occurs. Any changes that you make after the
> presentation occurs are ignored.

The `actions` and `message` closures aren't `@escaping` either. SwiftUI evaluates them while it
builds the alert and can't keep them to call again later.

Apple doesn't document the reasons, but the design is consistent:

- **An alert asks the user a question.** If its content changed while the user reached for a
  button, they could confirm a destructive action meant for a different item.
- **UIKit presents one view controller at a time.** `UIAlertView` lived in its own window, outside
  your view controllers, so you could show several without coordinating them. Since iOS 8,
  `UIAlertController` is a view controller that belongs to the screen presenting it, and a view
  controller presents one view controller at a time. Replacing a visible alert means dismissing it
  and presenting again after the transition ends. Ignoring changes avoids that sequence.
- **An alert that never updates needs no identity.** The original `alert(item:content:)` required
  `Identifiable`, as `sheet(item:)` still does, to notice a new item. Once changes are ignored,
  identity has no job, so the iOS 15 API accepts any type, such as `any Error`. The price is a
  separate `Bool` that says whether the alert is showing.
- **SwiftUI writes only the flag.** `presenting:` is a plain value, not a binding. On dismissal,
  SwiftUI sets the `Bool` to `false` and leaves your data alone.

The trade-off is that the type system can't rule out a flag without a value. SwiftUI accepts that
in exchange for alerts that never change under the user's finger, and a framework that never
writes to your data.

### How AlertState fits the model

`AlertState` follows the same rules and makes them easier to see:

| SwiftUI's rule | AlertState |
| --- | --- |
| Changes after presentation are ignored. | `present(_:)` asserts when an alert is already showing, so an ignored change shows up during development. |
| Dismissal clears only the `Bool`. | Dismissal clears only `isPresented`. The value stays, so the alert keeps its content while it animates out. |
| `presenting:` accepts any type. | `Value` has no constraints. `AlertState<any Error>` and `AlertState<Void>` both work. |

`AlertState` isn't meant for alerts whose content changes while they're visible. It keeps SwiftUI's
snapshot behavior on purpose.

[presenting-docs]: https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:presenting:actions:message:)-8584l

## Requirements

iOS 18 / macOS 15, Swift 6.0.

## Installation

```swift
.package(url: "https://github.com/FluidGroup/swiftui-alert-state.git", from: "0.1.0")
```

Then add the `SwiftUIAlertState` product to your target.

## License

Apache License 2.0. See [LICENSE](LICENSE).
