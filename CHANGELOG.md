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
