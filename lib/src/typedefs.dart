import 'package:flutter/widgets.dart';

/// Called whenever a page should be fetched, with the 1-based [page] number and
/// the configured page size as `limit`.
typedef PaginatedFetchCallback = void Function(int page, int limit);

/// Tests whether a BLoC state [S] matches a particular phase
/// (loading / success / error).
typedef StatePredicate<S> = bool Function(S state);

/// Extracts the current page's items of type [T] from a success state [S].
typedef PaginatedDataExtractor<T, S> = List<T> Function(S state);

/// Extracts a human-readable error message from an error state [S].
typedef PaginatedErrorExtractor<S> = String Function(S state);

/// Builds a single item [item] of type [T] at [index].
typedef PaginatedItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

/// Builds a widget for a given [index] (used for skeletons and separators).
typedef PaginatedIndexedBuilder = Widget Function(
  BuildContext context,
  int index,
);

/// Builds a standalone widget (used for empty state and header).
typedef PaginatedWidgetBuilder = Widget Function(BuildContext context);

/// Builds the error view, given the [error] message and a [retry] callback.
typedef PaginatedErrorBuilder = Widget Function(
  BuildContext context,
  String error,
  VoidCallback retry,
);
