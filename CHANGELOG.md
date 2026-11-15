## 0.2.0

* **Breaking:** requires Flutter 3.47+ / Dart 3.13+.
* Migrated from the deprecated `package:flutter/material.dart` and
  `package:flutter/cupertino.dart` libraries to the decoupled
  [`material_ui`](https://pub.dev/packages/material_ui) and
  [`cupertino_ui`](https://pub.dev/packages/cupertino_ui) packages.
* Verified against Flutter 3.50 / Dart 3.14.

## 0.1.0

Initial release.

* `BlocPaginatedListView` — a state-shape-agnostic paginated `ListView` driven
  by any `BLoC`/`Cubit`.
* Infinite scroll with configurable `pageSize` and `loadMoreThreshold`.
* Pull-to-refresh (`enableRefresh`).
* Fully customizable loading, empty, error, item, separator, header, and
  bottom-loader builders.
* Optional external `ScrollController`, `shrinkWrap`, and custom scroll physics.
* Theme-aware defaults with an optional `progressIndicatorColor`.
