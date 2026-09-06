# flutter_bloc_paginated_list

A reusable, **state-shape-agnostic** paginated `ListView` for Flutter, driven by any
[`bloc`](https://pub.dev/packages/flutter_bloc) `Cubit` or `Bloc`.

It handles the boilerplate every infinite-scroll list needs — page tracking, appending
pages on scroll, pull-to-refresh, and swapping between loading / empty / error / data
views — while leaving **all** of the UI to you through builder callbacks.

## Why "state-shape-agnostic"?

Most paginated-list packages force you to adopt their state classes. This one doesn't.
Instead of requiring a specific state type, you pass small predicate/extractor callbacks
(`isLoadingState`, `isSuccessState`, `isErrorState`, `extractData`,
`extractErrorMessage`), so it drops straight onto a BLoC you already have.

## Features

- ♾️ Infinite scroll with configurable `pageSize` and `loadMoreThreshold`
- 🔄 Pull-to-refresh (toggle with `enableRefresh`)
- 🧱 Fully customizable builders: item, loading/skeleton, empty, error, separator,
  header, and bottom loader
- 📜 Optional scrolling header, external `ScrollController`, `shrinkWrap`, custom physics
- 🎨 Theme-aware defaults with an optional `progressIndicatorColor`
- 🪶 No dependencies beyond `flutter_bloc`

## Installation

```yaml
dependencies:
  flutter_bloc_paginated_list: ^0.1.0
```

## Usage

Given a cubit that emits distinct loading / success / error states:

```dart
BlocPaginatedListView<Post, PostCubit, PostState>(
  bloc: context.read<PostCubit>(),

  // Called with the 1-based page number and your pageSize as `limit`.
  onFetchData: (page, limit) =>
      context.read<PostCubit>().fetchPosts(page: page, limit: limit),

  // Map your state shape -> the widget's expectations.
  isLoadingState: (s) => s is PostLoading,
  isSuccessState: (s) => s is PostLoaded,
  isErrorState:   (s) => s is PostError,
  extractData:         (s) => (s as PostLoaded).posts,
  extractErrorMessage: (s) => (s as PostError).message,

  // Build the UI.
  itemBuilder: (context, post, index) => PostTile(post: post),
  loadingItemBuilder: (context, index) => const PostSkeleton(),
  emptyBuilder: (context) => const Center(child: Text('No posts yet')),
  errorBuilder: (context, error, retry) =>
      ErrorView(message: error, onRetry: retry),

  // Optional extras.
  pageSize: 20,
  separatorBuilder: (context, index) => const Divider(),
  headerBuilder: (context) => const SectionHeader('Latest'),
)
```

### How pagination is detected

The widget requests page `1` on first build, then requests the next page when the user
scrolls within `loadMoreThreshold` pixels of the bottom. A returned page with **fewer
than `pageSize`** items is treated as the last page, so no further requests are made.
Pull-to-refresh resets back to page `1`.

> Your `onFetchData` should **emit a loading state** for pages after the first (rather
> than clearing the list) so appended pages are added to what's already shown.

## Parameters

| Parameter | Description | Default |
| --- | --- | --- |
| `bloc` | The BLoC/Cubit instance emitting pages. | required |
| `onFetchData` | `(page, limit)` callback that triggers a fetch. | required |
| `isLoadingState` / `isSuccessState` / `isErrorState` | Predicates over your state. | required |
| `extractData` / `extractErrorMessage` | Extractors from a success/error state. | required |
| `itemBuilder` | Builds one list item. | required |
| `loadingItemBuilder` | Builds one skeleton item for the initial load. | required |
| `emptyBuilder` | Widget shown when the list is empty. | required |
| `errorBuilder` | `(context, error, retry)` for a failed first page. | required |
| `headerBuilder` | Optional header that scrolls with the list. | `null` |
| `pageSize` | Items per page (also the "last page" heuristic). | `10` |
| `shimmerCount` | Skeleton items during initial load. | `8` |
| `separatorBuilder` | Use `ListView.separated` when provided. | `null` |
| `showBottomLoader` | Show a spinner while loading more. | `true` |
| `bottomLoaderWidget` | Custom "loading more" widget. | platform spinner |
| `enableRefresh` | Enable pull-to-refresh. | `true` |
| `scrollController` | External controller (kept alive by you). | internal |
| `physics` | Scroll physics. | `AlwaysScrollableScrollPhysics` |
| `shrinkWrap` | Shrink-wrap the list. | `false` |
| `loadMoreThreshold` | Pixels from bottom to trigger load-more. | `200` |
| `progressIndicatorColor` | Refresh/loader tint. | theme primary |

## Example

A complete runnable example lives in [`example/`](example/lib/main.dart).

## License

MIT © Abdulrahman Bayo
